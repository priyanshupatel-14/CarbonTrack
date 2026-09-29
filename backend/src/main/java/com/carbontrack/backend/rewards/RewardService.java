package com.carbontrack.backend.rewards;

import com.carbontrack.backend.points.PointService;
import com.carbontrack.backend.points.PointTransaction;
import com.carbontrack.backend.points.PointTransactionRepository;
import com.carbontrack.backend.points.TransactionType;
import com.carbontrack.backend.user.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Service
public class RewardService {

    private final RewardRepository rewardRepository;
    private final RewardRedemptionRepository redemptionRepository;
    private final CouponRepository couponRepository;
    private final PointService pointService;
    private final PointTransactionRepository pointTransactionRepository;

    private final SecureRandom secureRandom = new SecureRandom();

    public RewardService(RewardRepository rewardRepository,
                         RewardRedemptionRepository redemptionRepository,
                         CouponRepository couponRepository,
                         PointService pointService,
                         PointTransactionRepository pointTransactionRepository) {
        this.rewardRepository = rewardRepository;
        this.redemptionRepository = redemptionRepository;
        this.couponRepository = couponRepository;
        this.pointService = pointService;
        this.pointTransactionRepository = pointTransactionRepository;
    }

    public List<RewardDto> getActiveRewards() {
        return rewardRepository.findByStatus(RewardStatus.ACTIVE).stream()
                .filter(r -> r.getInventory() > 0 && (r.getExpiresAt() == null || r.getExpiresAt().isAfter(LocalDateTime.now())))
                .map(this::mapToRewardDto)
                .toList();
    }

    @Transactional
    public CouponDto redeemReward(User user, UUID rewardId) {
        Reward reward = rewardRepository.findByIdWithLock(rewardId)
                .orElseThrow(() -> new IllegalArgumentException("Reward not found"));
        
        if (reward.getStatus() != RewardStatus.ACTIVE) {
            throw new IllegalStateException("Reward is not active.");
        }
        if (reward.getExpiresAt() != null && reward.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("Reward is expired.");
        }
        if (reward.getInventory() <= 0) {
            throw new IllegalStateException("Reward is out of stock.");
        }
        
        int balance = pointService.getBalance(user);
        if (balance < reward.getPointsRequired()) {
            throw new IllegalStateException("Insufficient green points.");
        }
        
        RewardRedemption redemption = new RewardRedemption();
        redemption.setUser(user);
        redemption.setReward(reward);
        redemption.setPointsSpent(reward.getPointsRequired());
        redemption.setStatus(RedemptionStatus.ACTIVE);
        redemption = redemptionRepository.save(redemption);
        
        PointTransaction pt = new PointTransaction();
        pt.setUser(user);
        pt.setTransactionType(TransactionType.REDEEM);
        pt.setPoints(-reward.getPointsRequired());
        pt.setReferenceType("REWARD_REDEMPTION");
        pt.setReferenceId(redemption.getId().toString());
        pt.setDescription("Redeemed: " + reward.getName());
        pointTransactionRepository.save(pt);
        
        Coupon coupon = new Coupon();
        coupon.setRedemption(redemption);
        coupon.setCode(generateSecureCode());
        coupon.setStatus(CouponStatus.ACTIVE);
        if (reward.getExpiresAt() != null) {
            coupon.setExpiresAt(reward.getExpiresAt());
        }
        coupon = couponRepository.save(coupon);
        
        reward.setInventory(reward.getInventory() - 1);
        if (reward.getInventory() == 0) {
            reward.setStatus(RewardStatus.OUT_OF_STOCK);
        }
        rewardRepository.save(reward);
        
        return mapToCouponDto(coupon);
    }

    public List<CouponDto> getMyCoupons(User user) {
        return couponRepository.findByRedemptionUserOrderByCreatedAtDesc(user).stream()
                .map(this::mapToCouponDto)
                .toList();
    }

    @Transactional
    public CouponDto validateCouponByMerchant(User merchant, String code) {
        Coupon coupon = couponRepository.findByCode(code)
                .orElseThrow(() -> new IllegalArgumentException("Invalid coupon code"));

        if (!coupon.getRedemption().getReward().getMerchant().getId().equals(merchant.getId())) {
            throw new SecurityException("Merchant not authorized for this coupon");
        }

        if (coupon.getStatus() != CouponStatus.ACTIVE) {
            throw new IllegalStateException("Coupon is not active. Status: " + coupon.getStatus());
        }

        if (coupon.getExpiresAt() != null && coupon.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("Coupon is expired.");
        }

        return mapToCouponDto(coupon);
    }

    @Transactional
    public CouponDto consumeCoupon(User merchant, String code) {
        Coupon coupon = couponRepository.findByCode(code)
                .orElseThrow(() -> new IllegalArgumentException("Invalid coupon code"));

        if (!coupon.getRedemption().getReward().getMerchant().getId().equals(merchant.getId())) {
            throw new SecurityException("Merchant not authorized for this coupon");
        }

        if (coupon.getStatus() != CouponStatus.ACTIVE) {
            throw new IllegalStateException("Coupon is not active. Status: " + coupon.getStatus());
        }
        if (coupon.getExpiresAt() != null && coupon.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("Coupon is expired.");
        }

        coupon.setStatus(CouponStatus.REDEEMED);
        coupon.setRedeemedAt(LocalDateTime.now());
        coupon.setRedeemedByMerchant(merchant);
        
        RewardRedemption redemption = coupon.getRedemption();
        redemption.setStatus(RedemptionStatus.REDEEMED);
        redemption.setRedeemedAt(LocalDateTime.now());
        
        redemptionRepository.save(redemption);
        return mapToCouponDto(couponRepository.save(coupon));
    }

    private String generateSecureCode() {
        byte[] randomBytes = new byte[8];
        secureRandom.nextBytes(randomBytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes).toUpperCase();
    }

    private RewardDto mapToRewardDto(Reward reward) {
        return new RewardDto(
                reward.getId(),
                reward.getName(),
                reward.getDescription(),
                reward.getPointsRequired(),
                reward.getInventory(),
                reward.getExpiresAt(),
                reward.getMerchant().getFirstName() + " " + reward.getMerchant().getLastName() // Simplistic for now
        );
    }

    private CouponDto mapToCouponDto(Coupon coupon) {
        return new CouponDto(
                coupon.getId(),
                coupon.getCode(),
                coupon.getStatus().name(),
                coupon.getExpiresAt(),
                coupon.getRedeemedAt(),
                mapToRewardDto(coupon.getRedemption().getReward())
        );
    }
}
