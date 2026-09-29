package com.carbontrack.backend.rewards;

import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class RewardController {

    private final RewardService rewardService;
    private final UserRepository userRepository;

    public RewardController(RewardService rewardService, UserRepository userRepository) {
        this.rewardService = rewardService;
        this.userRepository = userRepository;
    }

    @GetMapping("/rewards")
    public ResponseEntity<List<RewardDto>> getActiveRewards() {
        return ResponseEntity.ok(rewardService.getActiveRewards());
    }

    @PostMapping("/rewards/{id}/redeem")
    public ResponseEntity<CouponDto> redeemReward(@AuthenticationPrincipal AuthenticatedUserPrincipal principal, @PathVariable UUID id) {
        User user = userRepository.findById(principal.getId()).orElseThrow();
        CouponDto coupon = rewardService.redeemReward(user, id);
        return ResponseEntity.ok(coupon);
    }

    @GetMapping("/coupons/me")
    public ResponseEntity<List<CouponDto>> getMyCoupons(@AuthenticationPrincipal AuthenticatedUserPrincipal principal) {
        User user = userRepository.findById(principal.getId()).orElseThrow();
        return ResponseEntity.ok(rewardService.getMyCoupons(user));
    }
}
