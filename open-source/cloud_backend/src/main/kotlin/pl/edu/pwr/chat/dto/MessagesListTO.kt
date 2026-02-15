package pl.edu.pwr.chat.dto

data class MessagesListTO(
    val messages: List<MessageTO>,
    val filename: String?,
)
