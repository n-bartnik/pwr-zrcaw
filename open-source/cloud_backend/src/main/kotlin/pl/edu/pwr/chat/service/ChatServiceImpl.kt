package pl.edu.pwr.chat.service

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service
import pl.edu.pwr.chat.dto.MessageRequestTO
import pl.edu.pwr.chat.dto.MessageTO
import pl.edu.pwr.chat.dto.MessagesListTO
import pl.edu.pwr.chat.model.ChatMessage
import pl.edu.pwr.chat.repository.ChatMessageRepository
import java.time.LocalDateTime
import org.springframework.web.multipart.MultipartFile
import java.io.File
import pl.edu.pwr.chat.repository.UploadedFileRepository
import pl.edu.pwr.chat.entity.UploadedFile
import org.springframework.beans.factory.annotation.Value

import software.amazon.awssdk.services.s3.S3Client
import software.amazon.awssdk.services.s3.model.GetObjectRequest
import software.amazon.awssdk.services.s3.model.PutObjectRequest
import java.io.ByteArrayOutputStream
import java.nio.file.Paths

import jakarta.annotation.PostConstruct
import software.amazon.awssdk.services.s3.model.CreateBucketRequest
import software.amazon.awssdk.services.s3.model.HeadBucketRequest
import software.amazon.awssdk.services.s3.model.NoSuchBucketException
import org.slf4j.LoggerFactory

@Service
class ChatServiceImpl @Autowired constructor(

    private val chatMessageRepository: ChatMessageRepository,
    private val s3Client: S3Client,
    @Value("\${s3.bucket.name}") private val bucketName: String,
    @Value("\${s3.endpoint}") private val s3Endpoint: String,
    @Autowired private val uploadedFileRepository: UploadedFileRepository

) : ChatService {

    private val logger = LoggerFactory.getLogger(ChatServiceImpl::class.java)

    @PostConstruct
    fun init() {
        try {
            logger.info("Checking MinIO connection. Endpoint: $s3Endpoint, Bucket: $bucketName")
            s3Client.headBucket(HeadBucketRequest.builder().bucket(bucketName).build())
            logger.info("Bucket $bucketName already exists")
        } catch (e: NoSuchBucketException) {
            logger.info("Bucket $bucketName does not exist. Creating it...")
            try {
                s3Client.createBucket(CreateBucketRequest.builder().bucket(bucketName).build())
                logger.info("Successfully created bucket: $bucketName")
            } catch (createException: Exception) {
                logger.error("Failed to create bucket $bucketName: ${createException.message}", createException)
            }
        } catch (e: Exception) {
            logger.error("Error connecting to MinIO at $s3Endpoint: ${e.message}", e)
            logger.error("Please verify that MinIO is running and accessible")
        }
    }
    override fun getAllEvents(username: String): MessagesListTO {
        val messages = chatMessageRepository.findAll()
        val messageList = messages.map { msg ->
            MessageTO(
                username = msg.username,
                filename = msg.filename,
                message = msg.message,
                timestamp = msg.timestamp
            )
        }
        return MessagesListTO(messages = messageList, filename = null)
    }

    override fun getNewMessages(username: String, after: LocalDateTime): MessagesListTO {
        val messages = chatMessageRepository.findByTimestampAfter(after)
        val messageList = messages.map { msg ->
            MessageTO(
                username = msg.username,
                filename = msg.filename,
                message = msg.message,
                timestamp = msg.timestamp
            )
        }
        return MessagesListTO(messages = messageList, filename = null)
    }

    override fun createLiveEvent(username: String, messageDTO: MessageRequestTO) {
        val chatMessage = ChatMessage(
            username = username,
            message = messageDTO.message,
            filename = messageDTO.filename,
            timestamp = LocalDateTime.now()
        )

        chatMessageRepository.save(chatMessage)
    }

    override fun clearAllMessages(){
        chatMessageRepository.deleteAll()
    }

    override fun uploadImage(file: MultipartFile): String {
        val key = file.originalFilename ?: "upload-${System.currentTimeMillis()}"
        var tempFile: File? = null

        try {
            tempFile = File.createTempFile("upload-", "-${key}")
            file.transferTo(tempFile)

            val putRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build()

            s3Client.putObject(putRequest, Paths.get(tempFile.absolutePath))
            logger.info("Successfully uploaded file: $key to bucket: $bucketName")

            val uploadedFile = UploadedFile(filename = key, url = "$s3Endpoint/$bucketName/$key")
            uploadedFileRepository.save(uploadedFile)

            return key
        } catch (e: Exception) {
            logger.error("Error uploading file to MinIO: ${e.message}", e)
            throw RuntimeException("Failed to upload file: ${e.message}", e)
        } finally {
            tempFile?.delete()
        }
    }

    override fun getImage(filename: String): ByteArray? {
        return try {
            val getRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(filename)
                .build()

            val inputStream = s3Client.getObject(getRequest)
            val output = ByteArrayOutputStream()
            inputStream.transferTo(output)
            output.toByteArray()
        } catch (e: Exception) {
            null
        }
    }
}
