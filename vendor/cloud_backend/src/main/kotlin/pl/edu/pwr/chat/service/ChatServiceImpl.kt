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
import java.io.ByteArrayOutputStream

import software.amazon.awssdk.services.s3.model.PutObjectRequest
import java.nio.file.Paths
@Service
class ChatServiceImpl @Autowired constructor(

    private val chatMessageRepository: ChatMessageRepository,
    private val s3Client: S3Client,
    @Value("\${s3.bucket.name}") private val bucketName: String,
    @Autowired private val uploadedFileRepository: UploadedFileRepository

) : ChatService {
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

// @Autowired
// private lateinit var uploadedFileRepository: UploadedFileRepository

// override fun uploadImage(file: MultipartFile): String {
//     val dir = File("/app/uploads")
//     if (!dir.exists()) dir.mkdirs()

//     val targetFile = File(dir, file.originalFilename!!)
//     file.transferTo(targetFile)

//     val url = "http://localhost/uploads/${file.originalFilename}"

//     val uploadedFile = UploadedFile(filename = file.originalFilename!!, url = url)
//     uploadedFileRepository.save(uploadedFile)
    
//     return file.originalFilename!!
// }

override fun uploadImage(file: MultipartFile): String {
        val key = file.originalFilename!!

        val tempFile = File.createTempFile("upload-", key)
        file.transferTo(tempFile)

        val putRequest = PutObjectRequest.builder()
            .bucket(bucketName)
            .key(key)
            .acl("private")
            .build()

        s3Client.putObject(putRequest, Paths.get(tempFile.absolutePath))

        tempFile.delete() // deleting temporary file

        val uploadedFile = UploadedFile(filename = key, url = "https://$bucketName.s3.amazonaws.com/$key")
        uploadedFileRepository.save(uploadedFile)

        return key
    }

// override fun getImage(filename: String): ByteArray? {
//         val file = File("/app/uploads/$filename")
//         return if (file.exists()) file.readBytes() else null
//     }

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
