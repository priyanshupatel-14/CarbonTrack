package com.carbontrack.backend.action;

import java.math.BigDecimal;
import java.util.UUID;

public record ActionDto(
        UUID id,
        String title,
        String description,
        String category,
        String status,
        BigDecimal estimatedImpact,
        String evidenceRequirements,
        String verificationRequirements
) {}
