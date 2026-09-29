package com.carbontrack.backend.action;

import java.time.LocalDateTime;
import java.util.UUID;

public record SubmissionDto(
        UUID id,
        UUID sustainableActionId,
        String actionTitle,
        String status,
        LocalDateTime submittedAt,
        LocalDateTime completedAt
) {}
