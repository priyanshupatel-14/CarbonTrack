package com.carbontrack.backend.challenge;

import com.carbontrack.backend.action.SustainableAction;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "challenges")
public class Challenge {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDateTime endDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ChallengeStatus status = ChallengeStatus.DRAFT;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "target_action_id", nullable = false)
    private SustainableAction targetAction;

    @Column(name = "target_count", nullable = false)
    private int targetCount;

    @Column(name = "bonus_points", nullable = false)
    private int bonusPoints = 0;

    @Column(name = "max_participants")
    private Integer maxParticipants;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
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

    public ChallengeStatus getEffectiveStatus() {
        if (status == ChallengeStatus.ACTIVE) {
            LocalDateTime now = LocalDateTime.now();
            if (now.isAfter(endDate)) {
                return ChallengeStatus.EXPIRED;
            }
        }
        return status;
    }

    public boolean isCurrentlyActive() {
        if (getEffectiveStatus() != ChallengeStatus.ACTIVE) {
            return false;
        }
        LocalDateTime now = LocalDateTime.now();
        return !now.isBefore(startDate) && !now.isAfter(endDate);
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public LocalDateTime getStartDate() { return startDate; }
    public void setStartDate(LocalDateTime startDate) { this.startDate = startDate; }
    public LocalDateTime getEndDate() { return endDate; }
    public void setEndDate(LocalDateTime endDate) { this.endDate = endDate; }
    public ChallengeStatus getStatus() { return status; }
    public void setStatus(ChallengeStatus status) { this.status = status; }
    public SustainableAction getTargetAction() { return targetAction; }
    public void setTargetAction(SustainableAction targetAction) { this.targetAction = targetAction; }
    public int getTargetCount() { return targetCount; }
    public void setTargetCount(int targetCount) { this.targetCount = targetCount; }
    public int getBonusPoints() { return bonusPoints; }
    public void setBonusPoints(int bonusPoints) { this.bonusPoints = bonusPoints; }
    public Integer getMaxParticipants() { return maxParticipants; }
    public void setMaxParticipants(Integer maxParticipants) { this.maxParticipants = maxParticipants; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
