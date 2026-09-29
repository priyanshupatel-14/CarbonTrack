package com.carbontrack.backend.points;

import com.carbontrack.backend.action.ActionSubmission;
import com.carbontrack.backend.action.SubmissionStatus;
import com.carbontrack.backend.user.User;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PointService {

    private final PointTransactionRepository pointTransactionRepository;

    public PointService(PointTransactionRepository pointTransactionRepository) {
        this.pointTransactionRepository = pointTransactionRepository;
    }

    @Transactional
    public void awardPointsForSubmission(ActionSubmission submission) {
        if (submission.getStatus() != SubmissionStatus.VERIFIED) {
            throw new IllegalStateException("Points can only be awarded for VERIFIED submissions.");
        }

        int pointsToAward = submission.getSustainableAction().getPointsReward();
        if (pointsToAward <= 0) {
            return; // No points to award
        }

        if (pointTransactionRepository.existsByTransactionTypeAndReferenceTypeAndReferenceId(
                TransactionType.EARN, "ACTION_SUBMISSION", submission.getId().toString())) {
            return; // Already awarded, idempotent
        }

        PointTransaction tx = new PointTransaction();
        tx.setUser(submission.getUser());
        tx.setTransactionType(TransactionType.EARN);
        tx.setPoints(pointsToAward);
        tx.setReferenceType("ACTION_SUBMISSION");
        tx.setReferenceId(submission.getId().toString());
        tx.setDescription("Earned from: " + submission.getSustainableAction().getTitle());

        try {
            pointTransactionRepository.saveAndFlush(tx);
        } catch (DataIntegrityViolationException e) {
            // Already awarded points for this submission concurrently, safe
        }
    }

    @Transactional
    public void awardBonusPointsForChallengeCompletion(User user, java.util.UUID participationId, String challengeTitle, int bonusPoints) {
        if (bonusPoints <= 0) {
            return;
        }

        if (pointTransactionRepository.existsByTransactionTypeAndReferenceTypeAndReferenceId(
                TransactionType.EARN, "CHALLENGE_COMPLETION", participationId.toString())) {
            return; // Already awarded bonus points, idempotent
        }

        PointTransaction tx = new PointTransaction();
        tx.setUser(user);
        tx.setTransactionType(TransactionType.EARN);
        tx.setPoints(bonusPoints);
        tx.setReferenceType("CHALLENGE_COMPLETION");
        tx.setReferenceId(participationId.toString());
        tx.setDescription("Bonus for completing challenge: " + challengeTitle);

        try {
            pointTransactionRepository.saveAndFlush(tx);
        } catch (DataIntegrityViolationException e) {
            // Already awarded bonus points for this challenge completion concurrently, safe
        }
    }

    public int getBalance(User user) {
        return pointTransactionRepository.calculateBalanceByUser(user);
    }
}
