package com.carbontrack.backend.action;

import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.verification.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.math.BigDecimal;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import com.carbontrack.backend.points.PointService;
import com.carbontrack.backend.challenge.ChallengeService;

@Service
public class ActionService {

    private final SustainableActionRepository actionRepository;
    private final ActionSubmissionRepository submissionRepository;
    private final EvidenceRepository evidenceRepository;
    private final EvidenceStorageService evidenceStorageService;
    private final VerificationService verificationService;
    private final UserRepository userRepository;
    private final PointService pointService;
    private final ChallengeService challengeService;

    public ActionService(SustainableActionRepository actionRepository, 
                         ActionSubmissionRepository submissionRepository, 
                         EvidenceRepository evidenceRepository,
                         EvidenceStorageService evidenceStorageService,
                         VerificationService verificationService,
                         UserRepository userRepository,
                         PointService pointService,
                         ChallengeService challengeService) {
        this.actionRepository = actionRepository;
        this.submissionRepository = submissionRepository;
        this.evidenceRepository = evidenceRepository;
        this.evidenceStorageService = evidenceStorageService;
        this.verificationService = verificationService;
        this.userRepository = userRepository;
        this.pointService = pointService;
        this.challengeService = challengeService;
    }

    public List<ActionDto> getActiveActions() {
        return actionRepository.findByStatus(ActionStatus.ACTIVE).stream()
                .map(a -> new ActionDto(
                        a.getId(), a.getTitle(), a.getDescription(), a.getCategory(), 
                        a.getStatus().name(), a.getEstimatedImpact(), 
                        a.getEvidenceRequirements(), a.getVerificationRequirements()))
                .toList();
    }

    @Transactional
    public SubmissionDto createSubmission(AuthenticatedUserPrincipal principal, SubmissionRequest request) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        SustainableAction action = actionRepository.findById(request.sustainableActionId())
                .orElseThrow(() -> new IllegalArgumentException("Action not found"));

        ActionSubmission submission = new ActionSubmission();
        submission.setUser(user);
        submission.setSustainableAction(action);
        submission.setStatus(SubmissionStatus.PENDING);
        submission.setClientTimestamp(request.clientTimestamp());
        submission.setServerTimestamp(LocalDateTime.now());
        submission.setSubmittedAt(LocalDateTime.now());

        submission = submissionRepository.save(submission);

        return mapToDto(submission);
    }

    @Transactional
    public EvidenceDto addEvidence(AuthenticatedUserPrincipal principal, UUID submissionId, MultipartFile file, 
                                   BigDecimal latitude, BigDecimal longitude, LocalDateTime clientTimestamp) throws IOException, NoSuchAlgorithmException {
        ActionSubmission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new IllegalArgumentException("Submission not found"));

        if (!submission.getUser().getId().equals(principal.getId())) {
            throw new SecurityException("Unauthorized access to submission");
        }

        if (submission.getStatus() != SubmissionStatus.PENDING) {
            throw new IllegalStateException("Cannot add evidence to an already finalized or reviewed submission.");
        }

        Evidence evidence = new Evidence();
        evidence.setSubmission(submission);
        evidence.setClientTimestamp(clientTimestamp != null ? clientTimestamp : LocalDateTime.now());

        if (file != null && !file.isEmpty()) {
            if (file.getContentType() == null || !file.getContentType().startsWith("image/")) {
                throw new IllegalArgumentException("Invalid file type. Only images allowed.");
            }
            if (file.getSize() > 5 * 1024 * 1024) { // 5MB limit
                throw new IllegalArgumentException("File size exceeds 5MB limit.");
            }
            evidence.setType(EvidenceType.PHOTO);
            evidence.setMimeType(file.getContentType());
            evidence.setFileSize(file.getSize());
            evidence.setStorageKey(evidenceStorageService.storeEvidence(file));
            
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(file.getBytes());
            StringBuilder sb = new StringBuilder();
            for (byte b : hashBytes) {
                sb.append(String.format("%02x", b));
            }
            evidence.setSha256Hash(sb.toString());
            if (!evidenceRepository.findBySha256Hash(sb.toString()).isEmpty()) {
                throw new IllegalArgumentException("Duplicate evidence detected.");
            }
        } else if (latitude != null || longitude != null) {
            if (latitude == null || longitude == null) {
                throw new IllegalArgumentException("Both latitude and longitude must be provided for location evidence.");
            }
            if (latitude.compareTo(BigDecimal.valueOf(-90)) < 0 || latitude.compareTo(BigDecimal.valueOf(90)) > 0) {
                throw new IllegalArgumentException("Invalid latitude. Latitude must be between -90 and 90.");
            }
            if (longitude.compareTo(BigDecimal.valueOf(-180)) < 0 || longitude.compareTo(BigDecimal.valueOf(180)) > 0) {
                throw new IllegalArgumentException("Invalid longitude. Longitude must be between -180 and 180.");
            }
            evidence.setType(EvidenceType.LOCATION);
            evidence.setLatitude(latitude);
            evidence.setLongitude(longitude);
        } else {
            evidence.setType(EvidenceType.TIMESTAMP);
        }

        try {
            evidence = evidenceRepository.saveAndFlush(evidence);
        } catch (DataIntegrityViolationException e) {
            throw new IllegalArgumentException("Duplicate evidence detected.");
        }
        return new EvidenceDto(
                evidence.getId(), 
                evidence.getType() != null ? evidence.getType().name() : "UNKNOWN", 
                evidence.getMimeType(), 
                evidence.getFileSize(), 
                evidence.getLatitude(), 
                evidence.getLongitude(), 
                evidence.getClientTimestamp(), 
                evidence.getCreatedAt() != null ? evidence.getCreatedAt() : LocalDateTime.now()
        );
    }

    @Transactional
    public SubmissionDto finalizeSubmission(AuthenticatedUserPrincipal principal, UUID submissionId) {
        ActionSubmission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new IllegalArgumentException("Submission not found"));

        if (!submission.getUser().getId().equals(principal.getId())) {
            throw new SecurityException("Unauthorized access to submission");
        }
        
        if (submission.getStatus() != SubmissionStatus.PENDING) {
            throw new IllegalStateException("Submission is already finalized or in review");
        }

        VerificationResult result = verificationService.verifySubmission(submission);
        submission.setStatus(result.getStatus());
        if (result.getStatus() == SubmissionStatus.VERIFIED || result.getStatus() == SubmissionStatus.REJECTED) {
            submission.setCompletedAt(LocalDateTime.now());
        }

        submission = submissionRepository.save(submission);

        if (submission.getStatus() == SubmissionStatus.VERIFIED) {
            pointService.awardPointsForSubmission(submission);
            challengeService.processVerifiedSubmission(submission);
        }

        return mapToDto(submission);
    }

    public List<SubmissionDto> getUserSubmissions(AuthenticatedUserPrincipal principal) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        return submissionRepository.findByUser(user).stream().map(this::mapToDto).toList();
    }

    public SubmissionDto getSubmission(AuthenticatedUserPrincipal principal, UUID id) {
        ActionSubmission submission = submissionRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Submission not found"));
        if (!submission.getUser().getId().equals(principal.getId())) {
            throw new SecurityException("Unauthorized");
        }
        return mapToDto(submission);
    }

    private SubmissionDto mapToDto(ActionSubmission sub) {
        return new SubmissionDto(sub.getId(), sub.getSustainableAction().getId(), 
                sub.getSustainableAction().getTitle(), sub.getStatus().name(), sub.getSubmittedAt(), sub.getCompletedAt());
    }
}
