package com.carbontrack.backend.challenge;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChallengeRepository extends JpaRepository<Challenge, UUID> {
    List<Challenge> findByStatus(ChallengeStatus status);
    List<Challenge> findAllByOrderByCreatedAtDesc();

    @Query("SELECT c FROM Challenge c WHERE c.status = 'ACTIVE' ORDER BY c.startDate ASC")
    List<Challenge> findActiveChallenges();
}
