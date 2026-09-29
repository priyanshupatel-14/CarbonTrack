package com.carbontrack.backend.carbon;

import java.math.BigDecimal;

public record CarbonSummaryDto(
    BigDecimal totalCo2e,
    BigDecimal transportationCo2e,
    BigDecimal electricityCo2e,
    BigDecimal foodCo2e,
    BigDecimal wasteCo2e,
    String reportingPeriod
) {}
