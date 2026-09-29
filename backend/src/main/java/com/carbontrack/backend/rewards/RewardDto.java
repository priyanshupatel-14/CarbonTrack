package com.carbontrack.backend.rewards;

import java.time.LocalDateTime;
import java.util.UUID;

public record RewardDto(
        UUID id,
        String name,
        String description,
        int pointsRequired,
        int inventory,
        LocalDateTime expiresAt,
        String merchantName
) {}
