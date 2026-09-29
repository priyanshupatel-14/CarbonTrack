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
            // Already awarded points for this submission, swallow or log
            // This prevents duplicate point awards.
        }
    }

    public int getBalance(User user) {
        return pointTransactionRepository.calculateBalanceByUser(user);
    }
}
