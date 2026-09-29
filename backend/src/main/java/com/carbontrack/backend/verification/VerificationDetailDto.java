package com.carbontrack.backend.verification;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record VerificationDetailDto(
    UUID id,
    UUID submissionId,
    String status,
    BigDecimal confidence,
    String aiEvidenceResult,
    String aiProvider,
    String aiModel,
    String aiDetectedElements,
    Boolean aiSuspicious,
    String aiFraudRisk,
    Boolean aiPossibleGenerated,
    Boolean aiPossibleManipulation,
    Boolean aiPossibleRecapture,
    String aiFraudIndicators,
    String locationResult,
    String timestampResult,
    String duplicateResult,
    String reasons,
    LocalDateTime evaluatedAt
) {
    public static VerificationDetailDto fromEntity(VerificationResult vr) {
        if (vr == null) return null;
        return new VerificationDetailDto(
                vr.getId(),
                vr.getSubmission() != null ? vr.getSubmission().getId() : null,
                vr.getStatus() != null ? vr.getStatus().name() : null,
                vr.getConfidence(),
                vr.getAiEvidenceResult(),
                vr.getAiProvider(),
                vr.getAiModel(),
                vr.getAiDetectedElements(),
                vr.getAiSuspicious(),
                vr.getAiFraudRisk(),
                vr.getAiPossibleGenerated(),
                vr.getAiPossibleManipulation(),
                vr.getAiPossibleRecapture(),
                vr.getAiFraudIndicators(),
                vr.getLocationResult(),
                vr.getTimestampResult(),
                vr.getDuplicateResult(),
                vr.getReasons(),
                vr.getEvaluatedAt()
        );
    }
}
