package pl.edu.pwr.chat.entity

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
data class UploadedFile(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
    val filename: String,
    @Column(columnDefinition = "TEXT")
    val url: String,
    val uploadedAt: LocalDateTime = LocalDateTime.now()
)
