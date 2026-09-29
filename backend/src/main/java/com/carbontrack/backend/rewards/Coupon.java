package com.carbontrack.backend.rewards;

import com.carbontrack.backend.user.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "coupons")
public class Coupon {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "redemption_id", nullable = false, unique = true)
    private RewardRedemption redemption;

    @Column(nullable = false, unique = true)
    private String code;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CouponStatus status;

    private LocalDateTime expiresAt;

    private LocalDateTime redeemedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "redeemed_by_merchant_id")
    private User redeemedByMerchant;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public RewardRedemption getRedemption() { return redemption; }
    public void setRedemption(RewardRedemption redemption) { this.redemption = redemption; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public CouponStatus getStatus() { return status; }
    public void setStatus(CouponStatus status) { this.status = status; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
    public LocalDateTime getRedeemedAt() { return redeemedAt; }
    public void setRedeemedAt(LocalDateTime redeemedAt) { this.redeemedAt = redeemedAt; }
    public User getRedeemedByMerchant() { return redeemedByMerchant; }
    public void setRedeemedByMerchant(User redeemedByMerchant) { this.redeemedByMerchant = redeemedByMerchant; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
