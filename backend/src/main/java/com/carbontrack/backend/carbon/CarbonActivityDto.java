package com.carbontrack.backend.carbon;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record CarbonActivityDto(
    UUID id,
    Category category,
    ActivityType activityType,
    BigDecimal quantity,
    String unit,
    LocalDate activityDate,
    String metadata,
    LocalDateTime createdAt,
    BigDecimal co2e,
    int factorVersion
) {
    public static CarbonActivityDto fromEntity(CarbonActivity activity) {
        BigDecimal co2e = BigDecimal.ZERO;
        int version = 0;
        
        if (activity.getCalculation() != null) {
            co2e = activity.getCalculation().getCo2e();
            version = activity.getCalculation().getFactorVersion();
        }
        
        return new CarbonActivityDto(
            activity.getId(),
            activity.getCategory(),
            activity.getActivityType(),
            activity.getQuantity(),
            activity.getUnit(),
            activity.getActivityDate(),
            activity.getMetadata(),
            activity.getCreatedAt(),
            co2e,
            version
        );
    }
}
