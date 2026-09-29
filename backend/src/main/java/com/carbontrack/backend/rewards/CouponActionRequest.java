package com.carbontrack.backend.rewards;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CouponActionRequest(
    @NotBlank(message = "Coupon code is required")
    @Size(max = 100)
    String code
) {}
