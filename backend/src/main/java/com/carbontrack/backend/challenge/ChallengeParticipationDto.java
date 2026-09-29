package com.carbontrack.backend.challenge;

import java.time.LocalDateTime;
import java.util.UUID;

public record ChallengeParticipationDto(
    UUID id,
    UUID challengeId,
    String challengeTitle,
    String challengeDescription,
    UUID targetActionId,
    String targetActionTitle,
    int targetCount,
    int progressCount,
    int bonusPoints,
    String status,
    LocalDateTime joinedAt,
    LocalDateTime completedAt,
    LocalDateTime challengeStartDate,
    LocalDateTime challengeEndDate,
    String challengeStatus
) {}
