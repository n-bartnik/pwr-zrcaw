package pl.edu.pwr.chat.controller
import java.io.File
import java.net.URLConnection
import org.springframework.http.HttpHeaders
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.format.annotation.DateTimeFormat
import pl.edu.pwr.chat.dto.MessageRequestTO
import pl.edu.pwr.chat.dto.MessagesListTO
import pl.edu.pwr.chat.service.ChatService
import java.time.LocalDateTime
import org.springframework.web.multipart.MultipartFile


@RestController
@RequestMapping("chat")
class ChatController @Autowired constructor(
    private val chatService: ChatService
) {

    @GetMapping("all")
    fun getAllMessages(@RequestHeader("x-amzn-oidc-identity") username: String): ResponseEntity<Any> {
        val resultTO: MessagesListTO = chatService.getAllEvents(username)

        return ResponseEntity.ok(resultTO)
    }

    @GetMapping("username")
    fun getUsername(@RequestHeader("x-amzn-oidc-identity") username: String): ResponseEntity<Any> {
        return ResponseEntity.ok(mapOf("username" to username))
    }


    @GetMapping
    fun getNewMessages(@RequestHeader("x-amzn-oidc-identity") username: String, @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) after: LocalDateTime): ResponseEntity<Any> {
        val resultTO: MessagesListTO = chatService.getNewMessages(username, after)

        return ResponseEntity.ok(resultTO)
    }

    @PostMapping
    fun createLiveEvent(@RequestHeader("x-amzn-oidc-identity") username: String, @RequestBody messageDTO: MessageRequestTO): ResponseEntity<Any> {
        chatService.createLiveEvent(username, messageDTO)
        return ResponseEntity.ok().build()
    }

    @PostMapping("clear")
    fun clearChat(): ResponseEntity<Any>{
        chatService.clearAllMessages()
        return ResponseEntity.ok("Chat cleared")
    }

    @PostMapping("upload")
    fun uploadImage(@RequestParam("file") file: MultipartFile): ResponseEntity<Any> {
        val filename = chatService.uploadImage(file)
        return ResponseEntity.ok(mapOf("filename" to filename))
    }

    @GetMapping("{filename}")
    fun getImage(@PathVariable filename: String): ResponseEntity<ByteArray> {
        val bytes = chatService.getImage(filename) ?: return ResponseEntity.notFound().build()

        val file = File("/app/uploads/$filename")
        val mimeType = URLConnection.guessContentTypeFromName(file.name) ?: "application/octet-stream"
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_TYPE, mimeType)
            .body(bytes)
    }

    @GetMapping("oidc")
    fun checkOidc(@RequestHeader("x-amzn-oidc-identity") identity: String): ResponseEntity<String> {
        println("OIDC Identity: $identity")
        return ResponseEntity.ok(identity)
    }


}