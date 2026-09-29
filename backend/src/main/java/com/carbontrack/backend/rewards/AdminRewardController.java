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

import java.time.LocalDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/rewards")
@PreAuthorize("hasRole('ADMIN')")
public class AdminRewardController {

    private final RewardRepository rewardRepository;
    private final UserRepository userRepository;

    public AdminRewardController(RewardRepository rewardRepository, UserRepository userRepository) {
        this.rewardRepository = rewardRepository;
        this.userRepository = userRepository;
    }

    @PostMapping
    public ResponseEntity<RewardDto> createReward(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @Valid @RequestBody CreateRewardRequest request) {
        if (principal.getRole() != Role.ADMIN) {
            throw new SecurityException("Only admins can create rewards.");
        }

        if (request.expiresAt() != null && request.expiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("Reward expiry date cannot be in the past.");
        }

        UUID merchantId = request.merchantUserId();
        User merchant = userRepository.findById(merchantId)
                .orElseThrow(() -> new IllegalArgumentException("Merchant not found"));
        
        if (merchant.getRole() != Role.MERCHANT) {
            throw new IllegalArgumentException("User is not a merchant");
        }

        Reward reward = new Reward();
        reward.setName(request.name().trim());
        reward.setDescription(request.description() != null ? request.description().trim() : null);
        reward.setPointsRequired(request.pointsRequired());
        reward.setInventory(request.inventory());
        reward.setStatus(request.inventory() > 0 ? RewardStatus.ACTIVE : RewardStatus.OUT_OF_STOCK);
        reward.setMerchant(merchant);
        reward.setExpiresAt(request.expiresAt());
        
        reward = rewardRepository.save(reward);
        
        return ResponseEntity.ok(new RewardDto(
                reward.getId(),
                reward.getName(),
                reward.getDescription(),
                reward.getPointsRequired(),
                reward.getInventory(),
                reward.getExpiresAt(),
                reward.getMerchant().getFirstName() + " " + reward.getMerchant().getLastName()
        ));
    }
}
