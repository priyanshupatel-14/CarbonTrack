package com.carbontrack.backend.rewards;

import com.carbontrack.backend.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface RewardRedemptionRepository extends JpaRepository<RewardRedemption, UUID> {
    List<RewardRedemption> findByUserOrderByCreatedAtDesc(User user);
}
