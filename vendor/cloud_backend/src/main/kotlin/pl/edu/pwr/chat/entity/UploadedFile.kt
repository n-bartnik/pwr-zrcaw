package pl.edu.pwr.chat.entity

import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import java.time.LocalDateTime

@Entity
data class UploadedFile(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    val filename: String,
    val url: String,
    val uploadedAt: LocalDateTime = LocalDateTime.now()
)
