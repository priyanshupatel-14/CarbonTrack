package com.carbontrack.backend.challenge;

import com.carbontrack.backend.action.ActionSubmission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChallengeProgressEventRepository extends JpaRepository<ChallengeProgressEvent, UUID> {
    boolean existsByChallengeAndSubmission(Challenge challenge, ActionSubmission submission);

    List<ChallengeProgressEvent> findByParticipation(ChallengeParticipation participation);
}
