package com.carbontrack.backend.rewards;

import java.time.LocalDateTime;
import java.util.UUID;

public record RedemptionDto(
        UUID id,
        RewardDto reward,
        int pointsSpent,
        String status,
        LocalDateTime createdAt,
        LocalDateTime redeemedAt
) {}
