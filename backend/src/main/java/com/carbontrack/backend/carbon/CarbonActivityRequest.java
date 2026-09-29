package com.carbontrack.backend.carbon;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;

public record CarbonActivityRequest(
    @NotNull Category category,
    @NotNull ActivityType activityType,
    @NotNull @Positive BigDecimal quantity,
    @NotBlank @Size(max = 50) String unit,
    @NotNull @PastOrPresent LocalDate activityDate,
    @Size(max = 1000) String metadata
) {}

