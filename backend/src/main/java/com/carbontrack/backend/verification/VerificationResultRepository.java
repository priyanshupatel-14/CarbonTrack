package com.carbontrack.backend.verification;

import com.carbontrack.backend.action.ActionSubmission;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface VerificationResultRepository extends JpaRepository<VerificationResult, UUID> {
    Optional<VerificationResult> findBySubmission(ActionSubmission submission);
}
