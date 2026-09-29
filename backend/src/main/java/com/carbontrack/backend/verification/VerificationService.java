package com.carbontrack.backend.verification;

import com.carbontrack.backend.action.ActionSubmission;
import com.carbontrack.backend.action.CampusZone;
import com.carbontrack.backend.action.SubmissionStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class VerificationService {

    private final EvidenceRepository evidenceRepository;
    private final EvidenceAnalyzer evidenceAnalyzer;
    private final VerificationResultRepository verificationResultRepository;

    public VerificationService(EvidenceRepository evidenceRepository, EvidenceAnalyzer evidenceAnalyzer, VerificationResultRepository verificationResultRepository) {
        this.evidenceRepository = evidenceRepository;
        this.evidenceAnalyzer = evidenceAnalyzer;
        this.verificationResultRepository = verificationResultRepository;
    }

    @Transactional
    public VerificationResult verifySubmission(ActionSubmission submission) {
        List<Evidence> evidenceList = evidenceRepository.findBySubmission(submission);
        
        VerificationResult result = new VerificationResult();
        result.setSubmission(submission);
        
        boolean aiPassed = true;
        boolean locationPassed = true;
        boolean timestampPassed = true;
        boolean duplicatePassed = true;
        
        StringBuilder reasons = new StringBuilder();

        // 1. Check Timestamp
        if (submission.getClientTimestamp() != null) {
            long secondsDiff = Math.abs(Duration.between(submission.getClientTimestamp(), submission.getServerTimestamp()).getSeconds());
            if (secondsDiff > 3600) { // More than 1 hour diff
                timestampPassed = false;
                result.setTimestampResult("Failed: Time difference too large (" + secondsDiff + "s)");
                reasons.append("Timestamp discrepancy. ");
            } else {
                result.setTimestampResult("Passed");
            }
        }

        // 2. Evaluate Evidence
        for (Evidence evidence : evidenceList) {
            if (evidence.getType() == EvidenceType.PHOTO) {
                // Check Duplicates
                if (evidence.getSha256Hash() != null) {
                    List<Evidence> matchingHashes = evidenceRepository.findBySha256Hash(evidence.getSha256Hash())
                        .stream().filter(e -> !e.getId().equals(evidence.getId())).toList();
                    if (!matchingHashes.isEmpty()) {
                        duplicatePassed = false;
                        result.setDuplicateResult("Failed: Exact duplicate image found.");
                        reasons.append("Duplicate photo detected. ");
                    } else {
                        result.setDuplicateResult("Passed");
                    }
                }

                // AI Analysis
                EvidenceAnalyzer.AnalysisResult aiResult = evidenceAnalyzer.analyze(evidence, submission.getSustainableAction());
                result.setAiEvidenceResult(aiResult.explanation());
                result.setConfidence(BigDecimal.valueOf(aiResult.confidence()));
                result.setAiProvider(aiResult.provider());
                result.setAiModel(aiResult.model());
                if (aiResult.detectedElements() != null && !aiResult.detectedElements().isEmpty()) {
                    result.setAiDetectedElements(String.join(", ", aiResult.detectedElements()));
                } else if (aiResult.detectedContent() != null) {
                    result.setAiDetectedElements(aiResult.detectedContent());
                }
                result.setAiSuspicious(aiResult.isSuspicious());
                result.setAiFraudRisk(aiResult.fraudRisk());
                result.setAiPossibleGenerated(aiResult.possibleAiGenerated());
                result.setAiPossibleManipulation(aiResult.possibleManipulation());
                result.setAiPossibleRecapture(aiResult.possibleRecapture());
                if (aiResult.fraudIndicators() != null && !aiResult.fraudIndicators().isEmpty()) {
                    result.setAiFraudIndicators(String.join(", ", aiResult.fraudIndicators()));
                }

                if (!aiResult.isValid()) {
                    aiPassed = false;
                    reasons.append("AI flagged photo: ").append(aiResult.explanation()).append(" ");
                }
            } else if (evidence.getType() == EvidenceType.LOCATION) {
                // Geofence check if action requires campus zone
                CampusZone zone = submission.getSustainableAction().getCampusZone();
                if (zone != null) {
                    double distance = calculateDistance(
                        evidence.getLatitude().doubleValue(), evidence.getLongitude().doubleValue(),
                        zone.getLatitude().doubleValue(), zone.getLongitude().doubleValue()
                    );
                    if (distance > zone.getRadiusMeters()) {
                        locationPassed = false;
                        result.setLocationResult("Failed: Distance " + distance + "m exceeds radius " + zone.getRadiusMeters() + "m");
                        reasons.append("Location outside campus zone. ");
                    } else {
                        result.setLocationResult("Passed: Inside zone");
                    }
                } else {
                    result.setLocationResult("N/A: No zone required");
                }
            }
        }

        // Final Scoring
        if (!duplicatePassed || !timestampPassed) {
            result.setStatus(SubmissionStatus.REJECTED);
        } else if (!aiPassed || !locationPassed) {
            result.setStatus(SubmissionStatus.REVIEW_REQUIRED);
        } else {
            result.setStatus(SubmissionStatus.VERIFIED);
        }
        
        result.setReasons(reasons.toString().isEmpty() ? "All checks passed" : reasons.toString());

        return verificationResultRepository.save(result);
    }

    // Haversine formula for distance in meters
    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371000; // Earth radius in meters
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
