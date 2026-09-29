package com.carbontrack.backend.rewards;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;
import java.util.UUID;

public record CreateRewardRequest(
    @NotNull UUID merchantUserId,
    @NotBlank @Size(max = 255) String name,
    @Size(max = 2000) String description,
    @NotNull @Positive Integer pointsRequired,
    @NotNull @PositiveOrZero Integer inventory,
    LocalDateTime expiresAt
) {}
