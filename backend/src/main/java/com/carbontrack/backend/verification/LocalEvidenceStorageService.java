package com.carbontrack.backend.verification;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class LocalEvidenceStorageService implements EvidenceStorageService {

    private final Path storageLocation;

    public LocalEvidenceStorageService() throws IOException {
        storageLocation = Files.createTempDirectory("carbontrack_evidence");
    }

    @Override
    public String storeEvidence(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Cannot store empty or null file.");
        }
        String originalName = file.getOriginalFilename();
        String extension = ".bin";
        if (originalName != null && originalName.lastIndexOf('.') != -1) {
            String ext = originalName.substring(originalName.lastIndexOf('.')).toLowerCase();
            if (ext.equals(".jpg") || ext.equals(".jpeg") || ext.equals(".png")) {
                extension = ext;
            }
        }
        String filename = UUID.randomUUID().toString() + extension;
        Path destination = storageLocation.resolve(filename).normalize();
        
        if (!destination.startsWith(storageLocation.normalize())) {
            throw new SecurityException("Cannot store file outside configured directory.");
        }
        Files.copy(file.getInputStream(), destination, StandardCopyOption.REPLACE_EXISTING);
        return destination.toAbsolutePath().toString();
    }

    @Override
    public void deleteEvidence(String storageKey) throws IOException {
        if (storageKey == null || storageKey.isBlank()) {
            return;
        }
        Path file = Path.of(storageKey).normalize();
        if (!file.startsWith(storageLocation.normalize())) {
            throw new SecurityException("Cannot delete file outside configured directory.");
        }
        Files.deleteIfExists(file);
    }

    public Path getStorageLocation() {
        return storageLocation;
    }
}
