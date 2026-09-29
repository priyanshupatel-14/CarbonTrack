package com.carbontrack.backend.challenge;

import com.carbontrack.backend.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ChallengeParticipationRepository extends JpaRepository<ChallengeParticipation, UUID> {
    Optional<ChallengeParticipation> findByChallengeAndUser(Challenge challenge, User user);

    List<ChallengeParticipation> findByUserOrderByJoinedAtDesc(User user);

    List<ChallengeParticipation> findByUserAndStatus(User user, ParticipationStatus status);

    @Query("SELECT COUNT(cp) FROM ChallengeParticipation cp WHERE cp.challenge = :challenge AND cp.status != 'CANCELLED'")
    long countActiveParticipantsByChallenge(@Param("challenge") Challenge challenge);

    long countByChallenge(Challenge challenge);

    @Query("SELECT COUNT(cp) FROM ChallengeParticipation cp WHERE cp.user = :user AND cp.status = 'JOINED'")
    long countActiveParticipationsByUser(@Param("user") User user);
}
