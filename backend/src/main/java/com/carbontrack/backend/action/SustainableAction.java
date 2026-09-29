package com.carbontrack.backend.action;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "sustainable_actions")
public class SustainableAction {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private String category;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ActionStatus status;

    @Column(nullable = false)
    private int pointsReward = 0;

    @Column(precision = 19, scale = 4)
    private BigDecimal estimatedImpact; // Estimated CO2e

    @Column(columnDefinition = "TEXT")
    private String evidenceRequirements; // e.g., "PHOTO,GPS,TIMESTAMP"

    @Column(columnDefinition = "TEXT")
    private String verificationRequirements; // e.g., "AI,GEOFENCE"

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campus_zone_id")
    private CampusZone campusZone;

    private LocalDateTime startDate;
    private LocalDateTime endDate;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public ActionStatus getStatus() { return status; }
    public void setStatus(ActionStatus status) { this.status = status; }
    public int getPointsReward() { return pointsReward; }
    public void setPointsReward(int pointsReward) { this.pointsReward = pointsReward; }
    public BigDecimal getEstimatedImpact() { return estimatedImpact; }
    public void setEstimatedImpact(BigDecimal estimatedImpact) { this.estimatedImpact = estimatedImpact; }
    public String getEvidenceRequirements() { return evidenceRequirements; }
    public void setEvidenceRequirements(String evidenceRequirements) { this.evidenceRequirements = evidenceRequirements; }
    public String getVerificationRequirements() { return verificationRequirements; }
    public void setVerificationRequirements(String verificationRequirements) { this.verificationRequirements = verificationRequirements; }
    public CampusZone getCampusZone() { return campusZone; }
    public void setCampusZone(CampusZone campusZone) { this.campusZone = campusZone; }
    public LocalDateTime getStartDate() { return startDate; }
    public void setStartDate(LocalDateTime startDate) { this.startDate = startDate; }
    public LocalDateTime getEndDate() { return endDate; }
    public void setEndDate(LocalDateTime endDate) { this.endDate = endDate; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
