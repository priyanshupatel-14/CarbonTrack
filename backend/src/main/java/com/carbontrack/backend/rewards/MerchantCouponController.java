package com.carbontrack.backend.rewards;

import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.user.Role;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/merchant/coupons")
@PreAuthorize("hasRole('MERCHANT')")
public class MerchantCouponController {

    private final RewardService rewardService;
    private final UserRepository userRepository;

    public MerchantCouponController(RewardService rewardService, UserRepository userRepository) {
        this.rewardService = rewardService;
        this.userRepository = userRepository;
    }

    @PostMapping("/validate")
    public ResponseEntity<CouponDto> validateCoupon(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @Valid @RequestBody CouponActionRequest request) {
        if (principal.getRole() != Role.MERCHANT) {
            throw new SecurityException("Only merchants can validate coupons.");
        }
        User merchant = userRepository.findById(principal.getId()).orElseThrow();
        String code = request.code().trim();
        return ResponseEntity.ok(rewardService.validateCouponByMerchant(merchant, code));
    }

    @PostMapping("/consume")
    public ResponseEntity<CouponDto> consumeCoupon(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @Valid @RequestBody CouponActionRequest request) {
        if (principal.getRole() != Role.MERCHANT) {
            throw new SecurityException("Only merchants can consume coupons.");
        }
        User merchant = userRepository.findById(principal.getId()).orElseThrow();
        String code = request.code().trim();
        return ResponseEntity.ok(rewardService.consumeCoupon(merchant, code));
    }
}
