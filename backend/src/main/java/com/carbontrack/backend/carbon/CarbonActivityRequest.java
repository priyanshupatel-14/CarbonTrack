package com.carbontrack.backend.carbon;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;
import java.time.LocalDate;

public record CarbonActivityRequest(
    @NotNull Category category,
    @NotNull ActivityType activityType,
    @NotNull @Positive BigDecimal quantity,
    @NotNull String unit,
    @NotNull LocalDate activityDate,
    String metadata
) {}
