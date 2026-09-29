package com.carbontrack.backend.action;

import com.carbontrack.backend.user.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "action_submissions")
public class ActionSubmission {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sustainable_action_id", nullable = false)
    private SustainableAction sustainableAction;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SubmissionStatus status;

    private LocalDateTime submittedAt;
    private LocalDateTime completedAt;

    private LocalDateTime clientTimestamp;
    private LocalDateTime serverTimestamp;

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
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public SustainableAction getSustainableAction() { return sustainableAction; }
    public void setSustainableAction(SustainableAction sustainableAction) { this.sustainableAction = sustainableAction; }
    public SubmissionStatus getStatus() { return status; }
    public void setStatus(SubmissionStatus status) { this.status = status; }
    public LocalDateTime getSubmittedAt() { return submittedAt; }
    public void setSubmittedAt(LocalDateTime submittedAt) { this.submittedAt = submittedAt; }
    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }
    public LocalDateTime getClientTimestamp() { return clientTimestamp; }
    public void setClientTimestamp(LocalDateTime clientTimestamp) { this.clientTimestamp = clientTimestamp; }
    public LocalDateTime getServerTimestamp() { return serverTimestamp; }
    public void setServerTimestamp(LocalDateTime serverTimestamp) { this.serverTimestamp = serverTimestamp; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
