package com.carbontrack.backend.points;

import java.time.LocalDateTime;
import java.util.UUID;

public record PointTransactionDto(
        UUID id,
        String type,
        int points,
        String referenceType,
        String referenceId,
        String description,
        LocalDateTime createdAt
) {}
