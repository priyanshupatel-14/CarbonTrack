package com.carbontrack.backend.verification;

import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;

public interface EvidenceStorageService {
    String storeEvidence(MultipartFile file) throws IOException;
    void deleteEvidence(String storageKey) throws IOException;
}
