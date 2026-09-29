package com.carbontrack.backend.challenge;

import java.time.LocalDateTime;
import java.util.UUID;

public record ChallengeDto(
    UUID id,
    String title,
    String description,
    LocalDateTime startDate,
    LocalDateTime endDate,
    String status,
    UUID targetActionId,
    String targetActionTitle,
    int targetCount,
    int bonusPoints,
    Integer maxParticipants,
    long participantCount,
    boolean joined,
    String participationStatus,
    Integer progressCount,
    LocalDateTime completedAt
) {}
