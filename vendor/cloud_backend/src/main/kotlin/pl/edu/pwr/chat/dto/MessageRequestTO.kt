package pl.edu.pwr.chat.dto

data class MessageRequestTO(
    val message: String,
    val filename: String? = null
)
