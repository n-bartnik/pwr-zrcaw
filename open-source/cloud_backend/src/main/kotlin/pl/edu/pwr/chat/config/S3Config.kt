package pl.edu.pwr.chat.config

import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.s3.S3Client
import java.net.URI
import org.slf4j.LoggerFactory

@Configuration
class S3Config {

    private val logger = LoggerFactory.getLogger(S3Config::class.java)

    @Value("\${s3.endpoint}")
    private lateinit var s3Endpoint: String

    @Value("\${s3.access.key}")
    private lateinit var accessKey: String

    @Value("\${s3.secret.key}")
    private lateinit var secretKey: String

    @Bean
    fun s3Client(): S3Client {
        logger.info("Initializing S3Client with endpoint: $s3Endpoint")
        val credentials = AwsBasicCredentials.create(accessKey, secretKey)
        
        return S3Client.builder()
            .region(Region.US_EAST_1)
            .endpointOverride(URI.create(s3Endpoint))
            .credentialsProvider(StaticCredentialsProvider.create(credentials))
            .forcePathStyle(true)
            .build()
    }
}
