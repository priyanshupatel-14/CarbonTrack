package com.carbontrack.backend.challenge;

import com.carbontrack.backend.action.ActionSubmission;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "challenge_progress_events",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_challenge_submission", columnNames = {"challenge_id", "action_submission_id"})
    }
)
public class ChallengeProgressEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "challenge_id", nullable = false)
    private Challenge challenge;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "participation_id", nullable = false)
    private ChallengeParticipation participation;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "action_submission_id", nullable = false)
    private ActionSubmission submission;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public ChallengeProgressEvent() {}

    public ChallengeProgressEvent(Challenge challenge, ChallengeParticipation participation, ActionSubmission submission) {
        this.challenge = challenge;
        this.participation = participation;
        this.submission = submission;
    }

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public Challenge getChallenge() { return challenge; }
    public void setChallenge(Challenge challenge) { this.challenge = challenge; }
    public ChallengeParticipation getParticipation() { return participation; }
    public void setParticipation(ChallengeParticipation participation) { this.participation = participation; }
    public ActionSubmission getSubmission() { return submission; }
    public void setSubmission(ActionSubmission submission) { this.submission = submission; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
