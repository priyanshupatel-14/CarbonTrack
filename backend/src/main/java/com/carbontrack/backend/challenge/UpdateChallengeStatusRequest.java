package com.carbontrack.backend.challenge;

import jakarta.validation.constraints.NotNull;

public record UpdateChallengeStatusRequest(
    @NotNull(message = "Status is required")
    ChallengeStatus status
) {}
