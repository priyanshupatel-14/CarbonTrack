package com.carbontrack.backend.carbon;

import com.carbontrack.backend.user.User;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "carbon_activities", indexes = {
    @Index(name = "idx_carbon_activity_user_date", columnList = "user_id, activityDate"),
    @Index(name = "idx_carbon_activity_category", columnList = "category")
})
public class CarbonActivity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Category category;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ActivityType activityType;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal quantity;

    @Column(nullable = false)
    private String unit;

    @Column(nullable = false)
    private LocalDate activityDate;

    @Column(columnDefinition = "TEXT")
    private String metadata; // Simple text or JSON string for extra info

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // One-to-one mapped by calculation
    @OneToOne(mappedBy = "carbonActivity", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private CarbonCalculation calculation;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public Category getCategory() { return category; }
    public void setCategory(Category category) { this.category = category; }
    public ActivityType getActivityType() { return activityType; }
    public void setActivityType(ActivityType activityType) { this.activityType = activityType; }
    public BigDecimal getQuantity() { return quantity; }
    public void setQuantity(BigDecimal quantity) { this.quantity = quantity; }
    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }
    public LocalDate getActivityDate() { return activityDate; }
    public void setActivityDate(LocalDate activityDate) { this.activityDate = activityDate; }
    public String getMetadata() { return metadata; }
    public void setMetadata(String metadata) { this.metadata = metadata; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public CarbonCalculation getCalculation() { return calculation; }
    public void setCalculation(CarbonCalculation calculation) { this.calculation = calculation; }
}
