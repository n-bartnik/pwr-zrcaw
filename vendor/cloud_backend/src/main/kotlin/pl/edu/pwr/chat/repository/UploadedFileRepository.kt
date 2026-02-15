package pl.edu.pwr.chat.repository

import org.springframework.data.jpa.repository.JpaRepository
import pl.edu.pwr.chat.entity.UploadedFile

interface UploadedFileRepository : JpaRepository<UploadedFile, Long>
