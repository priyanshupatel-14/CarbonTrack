package com.carbontrack.backend.verification;

import com.carbontrack.backend.action.ActionSubmission;
import com.carbontrack.backend.action.SubmissionStatus;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "verification_results")
public class VerificationResult {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "submission_id", nullable = false)
    private ActionSubmission submission;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SubmissionStatus status;

    @Column(precision = 5, scale = 2)
    private BigDecimal confidence;

    @Column(columnDefinition = "TEXT")
    private String aiEvidenceResult;

    private String aiProvider;
    private String aiModel;

    @Column(columnDefinition = "TEXT")
    private String aiDetectedElements;

    private Boolean aiSuspicious;

    private String aiFraudRisk;
    private Boolean aiPossibleGenerated;
    private Boolean aiPossibleManipulation;
    private Boolean aiPossibleRecapture;

    @Column(columnDefinition = "TEXT")
    private String aiFraudIndicators;

    @Column(columnDefinition = "TEXT")
    private String locationResult;

    @Column(columnDefinition = "TEXT")
    private String timestampResult;

    @Column(columnDefinition = "TEXT")
    private String duplicateResult;

    @Column(columnDefinition = "TEXT")
    private String reasons;

    @Column(nullable = false, updatable = false)
    private LocalDateTime evaluatedAt;

    @PrePersist
    protected void onCreate() {
        evaluatedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public ActionSubmission getSubmission() { return submission; }
    public void setSubmission(ActionSubmission submission) { this.submission = submission; }
    public SubmissionStatus getStatus() { return status; }
    public void setStatus(SubmissionStatus status) { this.status = status; }
    public BigDecimal getConfidence() { return confidence; }
    public void setConfidence(BigDecimal confidence) { this.confidence = confidence; }
    public String getAiEvidenceResult() { return aiEvidenceResult; }
    public void setAiEvidenceResult(String aiEvidenceResult) { this.aiEvidenceResult = aiEvidenceResult; }
    public String getAiProvider() { return aiProvider; }
    public void setAiProvider(String aiProvider) { this.aiProvider = aiProvider; }
    public String getAiModel() { return aiModel; }
    public void setAiModel(String aiModel) { this.aiModel = aiModel; }
    public String getAiDetectedElements() { return aiDetectedElements; }
    public void setAiDetectedElements(String aiDetectedElements) { this.aiDetectedElements = aiDetectedElements; }
    public Boolean getAiSuspicious() { return aiSuspicious; }
    public void setAiSuspicious(Boolean aiSuspicious) { this.aiSuspicious = aiSuspicious; }
    public String getAiFraudRisk() { return aiFraudRisk; }
    public void setAiFraudRisk(String aiFraudRisk) { this.aiFraudRisk = aiFraudRisk; }
    public Boolean getAiPossibleGenerated() { return aiPossibleGenerated; }
    public void setAiPossibleGenerated(Boolean aiPossibleGenerated) { this.aiPossibleGenerated = aiPossibleGenerated; }
    public Boolean getAiPossibleManipulation() { return aiPossibleManipulation; }
    public void setAiPossibleManipulation(Boolean aiPossibleManipulation) { this.aiPossibleManipulation = aiPossibleManipulation; }
    public Boolean getAiPossibleRecapture() { return aiPossibleRecapture; }
    public void setAiPossibleRecapture(Boolean aiPossibleRecapture) { this.aiPossibleRecapture = aiPossibleRecapture; }
    public String getAiFraudIndicators() { return aiFraudIndicators; }
    public void setAiFraudIndicators(String aiFraudIndicators) { this.aiFraudIndicators = aiFraudIndicators; }
    public String getLocationResult() { return locationResult; }
    public void setLocationResult(String locationResult) { this.locationResult = locationResult; }
    public String getTimestampResult() { return timestampResult; }
    public void setTimestampResult(String timestampResult) { this.timestampResult = timestampResult; }
    public String getDuplicateResult() { return duplicateResult; }
    public void setDuplicateResult(String duplicateResult) { this.duplicateResult = duplicateResult; }
    public String getReasons() { return reasons; }
    public void setReasons(String reasons) { this.reasons = reasons; }
    public LocalDateTime getEvaluatedAt() { return evaluatedAt; }
}
