package com.carbontrack.backend.verification;

import com.carbontrack.backend.action.ActionSubmission;
import com.carbontrack.backend.action.ActionSubmissionRepository;
import com.carbontrack.backend.action.SubmissionDto;
import com.carbontrack.backend.action.SubmissionStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import com.carbontrack.backend.points.PointService;
import com.carbontrack.backend.challenge.ChallengeService;

@Service
public class AdminReviewService {

    private final ActionSubmissionRepository submissionRepository;
    private final VerificationResultRepository verificationResultRepository;
    private final PointService pointService;
    private final ChallengeService challengeService;

    public AdminReviewService(ActionSubmissionRepository submissionRepository, 
                              VerificationResultRepository verificationResultRepository,
                              PointService pointService,
                              ChallengeService challengeService) {
        this.submissionRepository = submissionRepository;
        this.verificationResultRepository = verificationResultRepository;
        this.pointService = pointService;
        this.challengeService = challengeService;
    }

    public List<SubmissionDto> getPendingReviews() {
        return submissionRepository.findByStatus(SubmissionStatus.REVIEW_REQUIRED).stream()
                .map(sub -> new SubmissionDto(sub.getId(), sub.getSustainableAction().getId(), 
                        sub.getSustainableAction().getTitle(), sub.getStatus().name(), sub.getSubmittedAt(), sub.getCompletedAt()))
                .toList();
    }

    public VerificationDetailDto getVerificationDetail(UUID submissionId) {
        return submissionRepository.findById(submissionId)
                .flatMap(verificationResultRepository::findBySubmission)
                .map(VerificationDetailDto::fromEntity)
                .orElse(null);
    }

    @Transactional
    public void reviewSubmission(UUID submissionId, boolean approve, String adminReason) {
        ActionSubmission submission = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new IllegalArgumentException("Submission not found"));

        if (submission.getStatus() != SubmissionStatus.REVIEW_REQUIRED && submission.getStatus() != SubmissionStatus.PENDING) {
            throw new IllegalStateException("Submission is not in a reviewable state.");
        }

        submission.setStatus(approve ? SubmissionStatus.VERIFIED : SubmissionStatus.REJECTED);
        submission.setCompletedAt(LocalDateTime.now());
        submissionRepository.save(submission);

        VerificationResult result = verificationResultRepository.findBySubmission(submission).orElse(new VerificationResult());
        result.setSubmission(submission);
        result.setStatus(submission.getStatus());
        result.setReasons(adminReason);
        verificationResultRepository.save(result);

        if (submission.getStatus() == SubmissionStatus.VERIFIED) {
            pointService.awardPointsForSubmission(submission);
            challengeService.processVerifiedSubmission(submission);
        }
    }
}
