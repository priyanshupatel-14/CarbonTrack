package com.carbontrack.backend.rewards;

import java.time.LocalDateTime;
import java.util.UUID;

public record CouponDto(
        UUID id,
        String code,
        String status,
        LocalDateTime expiresAt,
        LocalDateTime redeemedAt,
        RewardDto reward
) {}
