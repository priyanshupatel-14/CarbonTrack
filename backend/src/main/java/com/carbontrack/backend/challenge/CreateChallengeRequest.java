package com.carbontrack.backend.challenge;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;
import java.util.UUID;

public record CreateChallengeRequest(
    @NotBlank(message = "Title is required")
    String title,

    String description,

    @NotNull(message = "Start date is required")
    LocalDateTime startDate,

    @NotNull(message = "End date is required")
    LocalDateTime endDate,

    ChallengeStatus status,

    @NotNull(message = "Target action ID is required")
    UUID targetActionId,

    @Min(value = 1, message = "Target count must be at least 1")
    int targetCount,

    @Min(value = 0, message = "Bonus points cannot be negative")
    int bonusPoints,

    @Min(value = 1, message = "Max participants must be at least 1 if set")
    Integer maxParticipants
) {}
