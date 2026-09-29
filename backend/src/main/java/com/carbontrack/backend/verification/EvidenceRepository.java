package com.carbontrack.backend.verification;

import com.carbontrack.backend.action.ActionSubmission;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface EvidenceRepository extends JpaRepository<Evidence, UUID> {
    List<Evidence> findBySubmission(ActionSubmission submission);
    List<Evidence> findBySha256Hash(String sha256Hash);
}
