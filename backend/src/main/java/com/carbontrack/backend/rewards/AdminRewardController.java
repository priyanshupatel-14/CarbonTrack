package com.carbontrack.backend.rewards;

import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.user.Role;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/rewards")
public class AdminRewardController {

    private final RewardRepository rewardRepository;
    private final UserRepository userRepository;

    public AdminRewardController(RewardRepository rewardRepository, UserRepository userRepository) {
        this.rewardRepository = rewardRepository;
        this.userRepository = userRepository;
    }

    @PostMapping
    public ResponseEntity<RewardDto> createReward(@AuthenticationPrincipal AuthenticatedUserPrincipal principal, @RequestBody Map<String, Object> request) {
        if (principal.getRole() != Role.ADMIN) {
            throw new SecurityException("Only admins can create rewards.");
        }

        UUID merchantId = UUID.fromString((String) request.get("merchantUserId"));
        User merchant = userRepository.findById(merchantId).orElseThrow(() -> new IllegalArgumentException("Merchant not found"));
        
        if (merchant.getRole() != Role.MERCHANT) {
            throw new IllegalArgumentException("User is not a merchant");
        }

        Reward reward = new Reward();
        reward.setName((String) request.get("name"));
        reward.setDescription((String) request.get("description"));
        reward.setPointsRequired((Integer) request.get("pointsRequired"));
        reward.setInventory((Integer) request.get("inventory"));
        reward.setStatus(RewardStatus.ACTIVE);
        reward.setMerchant(merchant);
        
        // optional expiresAt
        // String expiresAtStr = (String) request.get("expiresAt");
        // if (expiresAtStr != null) reward.setExpiresAt(LocalDateTime.parse(expiresAtStr));
        
        reward = rewardRepository.save(reward);
        
        return ResponseEntity.ok(new RewardDto(
                reward.getId(),
                reward.getName(),
                reward.getDescription(),
                reward.getPointsRequired(),
                reward.getInventory(),
                reward.getExpiresAt(),
                reward.getMerchant().getFirstName()
        ));
    }
}
