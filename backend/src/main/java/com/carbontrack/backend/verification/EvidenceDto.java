package com.carbontrack.backend.verification;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record EvidenceDto(
        UUID id,
        String type,
        String mimeType,
        Long fileSize,
        BigDecimal latitude,
        BigDecimal longitude,
        LocalDateTime clientTimestamp,
        LocalDateTime createdAt
) {}
