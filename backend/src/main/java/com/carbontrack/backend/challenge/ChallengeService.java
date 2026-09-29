package com.carbontrack.backend.challenge;

import com.carbontrack.backend.action.ActionSubmission;
import com.carbontrack.backend.action.SubmissionStatus;
import com.carbontrack.backend.action.SustainableAction;
import com.carbontrack.backend.action.SustainableActionRepository;
import com.carbontrack.backend.points.PointService;
import com.carbontrack.backend.user.Role;
import com.carbontrack.backend.user.User;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class ChallengeService {

    private final ChallengeRepository challengeRepository;
    private final ChallengeParticipationRepository participationRepository;
    private final ChallengeProgressEventRepository progressEventRepository;
    private final SustainableActionRepository actionRepository;
    private final PointService pointService;

    public ChallengeService(
            ChallengeRepository challengeRepository,
            ChallengeParticipationRepository participationRepository,
            ChallengeProgressEventRepository progressEventRepository,
            SustainableActionRepository actionRepository,
            PointService pointService) {
        this.challengeRepository = challengeRepository;
        this.participationRepository = participationRepository;
        this.progressEventRepository = progressEventRepository;
        this.actionRepository = actionRepository;
        this.pointService = pointService;
    }

    public List<ChallengeDto> getActiveChallengesForStudent(User student) {
        List<Challenge> challenges = challengeRepository.findActiveChallenges();
        return challenges.stream()
                .filter(c -> c.getEffectiveStatus() == ChallengeStatus.ACTIVE)
                .map(c -> mapToChallengeDto(c, student))
                .toList();
    }

    public ChallengeDto getChallengeDetails(User student, UUID challengeId) {
        Challenge challenge = challengeRepository.findById(challengeId)
                .orElseThrow(() -> new IllegalArgumentException("Challenge not found"));
        return mapToChallengeDto(challenge, student);
    }

    public List<ChallengeParticipationDto> getMyChallenges(User student) {
        List<ChallengeParticipation> participations = participationRepository.findByUserOrderByJoinedAtDesc(student);
        return participations.stream()
                .map(this::mapToParticipationDto)
                .toList();
    }

    @Transactional
    public ChallengeParticipationDto joinChallenge(User student, UUID challengeId) {
        if (student.getRole() != Role.STUDENT) {
            throw new SecurityException("Only students can join challenges");
        }

        Challenge challenge = challengeRepository.findById(challengeId)
                .orElseThrow(() -> new IllegalArgumentException("Challenge not found"));

        if (challenge.getEffectiveStatus() != ChallengeStatus.ACTIVE) {
            throw new IllegalStateException("Challenge is not active");
        }

        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(challenge.getStartDate()) || now.isAfter(challenge.getEndDate())) {
            throw new IllegalStateException("Challenge is not currently open for joining");
        }

        if (participationRepository.findByChallengeAndUser(challenge, student).isPresent()) {
            throw new IllegalStateException("You have already joined this challenge");
        }

        if (challenge.getMaxParticipants() != null && challenge.getMaxParticipants() > 0) {
            long currentCount = participationRepository.countActiveParticipantsByChallenge(challenge);
            if (currentCount >= challenge.getMaxParticipants()) {
                throw new IllegalStateException("Challenge has reached maximum participant limit");
            }
        }

        ChallengeParticipation participation = new ChallengeParticipation();
        participation.setChallenge(challenge);
        participation.setUser(student);
        participation.setJoinedAt(now);
        participation.setProgressCount(0);
        participation.setStatus(ParticipationStatus.JOINED);

        try {
            participation = participationRepository.saveAndFlush(participation);
        } catch (DataIntegrityViolationException e) {
            throw new IllegalStateException("You have already joined this challenge");
        }

        return mapToParticipationDto(participation);
    }

    @Transactional
    public void processVerifiedSubmission(ActionSubmission submission) {
        if (submission.getStatus() != SubmissionStatus.VERIFIED) {
            return;
        }

        User user = submission.getUser();
        List<ChallengeParticipation> activeParticipations = participationRepository.findByUserAndStatus(user, ParticipationStatus.JOINED);

        for (ChallengeParticipation participation : activeParticipations) {
            Challenge challenge = participation.getChallenge();

            // Must match target action
            if (!challenge.getTargetAction().getId().equals(submission.getSustainableAction().getId())) {
                continue;
            }

            // Challenge must be currently active
            if (challenge.getEffectiveStatus() != ChallengeStatus.ACTIVE) {
                continue;
            }

            // Submission must have occurred within challenge dates
            LocalDateTime submissionTime = submission.getSubmittedAt() != null ? submission.getSubmittedAt() : submission.getCreatedAt();
            if (submissionTime.isBefore(challenge.getStartDate()) || submissionTime.isAfter(challenge.getEndDate())) {
                continue;
            }

            // Check database-backed idempotency to prevent duplicate increments
            if (progressEventRepository.existsByChallengeAndSubmission(challenge, submission)) {
                continue;
            }

            ChallengeProgressEvent event = new ChallengeProgressEvent(challenge, participation, submission);
            try {
                progressEventRepository.saveAndFlush(event);
            } catch (DataIntegrityViolationException e) {
                // Duplicate progress event detected at DB level; safely skip
                continue;
            }

            int newProgress = participation.getProgressCount() + 1;
            participation.setProgressCount(newProgress);

            if (newProgress >= challenge.getTargetCount() && participation.getStatus() == ParticipationStatus.JOINED) {
                participation.setStatus(ParticipationStatus.COMPLETED);
                participation.setCompletedAt(LocalDateTime.now());
                participationRepository.saveAndFlush(participation);

                // Award bonus points via existing PointTransaction ledger
                if (challenge.getBonusPoints() > 0) {
                    pointService.awardBonusPointsForChallengeCompletion(
                            user,
                            participation.getId(),
                            challenge.getTitle(),
                            challenge.getBonusPoints()
                    );
                }
            } else {
                participationRepository.save(participation);
            }
        }
    }

    // Admin operations
    @Transactional
    public ChallengeDto createChallenge(CreateChallengeRequest request) {
        validateChallengeRequest(request);

        SustainableAction action = actionRepository.findById(request.targetActionId())
                .orElseThrow(() -> new IllegalArgumentException("Target action not found"));

        Challenge challenge = new Challenge();
        challenge.setTitle(request.title().trim());
        challenge.setDescription(request.description());
        challenge.setStartDate(request.startDate());
        challenge.setEndDate(request.endDate());
        challenge.setStatus(request.status() != null ? request.status() : ChallengeStatus.DRAFT);
        challenge.setTargetAction(action);
        challenge.setTargetCount(request.targetCount());
        challenge.setBonusPoints(request.bonusPoints());
        challenge.setMaxParticipants(request.maxParticipants());

        challenge = challengeRepository.save(challenge);
        return mapToChallengeDto(challenge, null);
    }

    @Transactional
    public ChallengeDto updateChallenge(UUID challengeId, CreateChallengeRequest request) {
        validateChallengeRequest(request);

        Challenge challenge = challengeRepository.findById(challengeId)
                .orElseThrow(() -> new IllegalArgumentException("Challenge not found"));

        SustainableAction action = actionRepository.findById(request.targetActionId())
                .orElseThrow(() -> new IllegalArgumentException("Target action not found"));

        challenge.setTitle(request.title().trim());
        challenge.setDescription(request.description());
        challenge.setStartDate(request.startDate());
        challenge.setEndDate(request.endDate());
        if (request.status() != null) {
            challenge.setStatus(request.status());
        }
        challenge.setTargetAction(action);
        challenge.setTargetCount(request.targetCount());
        challenge.setBonusPoints(request.bonusPoints());
        challenge.setMaxParticipants(request.maxParticipants());

        challenge = challengeRepository.save(challenge);
        return mapToChallengeDto(challenge, null);
    }

    @Transactional
    public ChallengeDto updateChallengeStatus(UUID challengeId, ChallengeStatus newStatus) {
        Challenge challenge = challengeRepository.findById(challengeId)
                .orElseThrow(() -> new IllegalArgumentException("Challenge not found"));

        challenge.setStatus(newStatus);
        challenge = challengeRepository.save(challenge);
        return mapToChallengeDto(challenge, null);
    }

    public List<ChallengeDto> getAllChallengesForAdmin() {
        return challengeRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(c -> mapToChallengeDto(c, null))
                .toList();
    }

    private void validateChallengeRequest(CreateChallengeRequest request) {
        if (request.startDate().isAfter(request.endDate())) {
            throw new IllegalArgumentException("Start date must be before end date");
        }
        if (request.targetCount() <= 0) {
            throw new IllegalArgumentException("Target count must be greater than zero");
        }
        if (request.bonusPoints() < 0) {
            throw new IllegalArgumentException("Bonus points cannot be negative");
        }
        if (request.maxParticipants() != null && request.maxParticipants() <= 0) {
            throw new IllegalArgumentException("Max participants must be greater than zero");
        }
    }

    private ChallengeDto mapToChallengeDto(Challenge challenge, User student) {
        long participantCount = participationRepository.countActiveParticipantsByChallenge(challenge);

        boolean joined = false;
        String participationStatus = null;
        Integer progressCount = null;
        LocalDateTime completedAt = null;

        if (student != null) {
            Optional<ChallengeParticipation> participationOpt = participationRepository.findByChallengeAndUser(challenge, student);
            if (participationOpt.isPresent()) {
                ChallengeParticipation p = participationOpt.get();
                joined = true;
                participationStatus = p.getStatus().name();
                progressCount = p.getProgressCount();
                completedAt = p.getCompletedAt();
            }
        }

        return new ChallengeDto(
                challenge.getId(),
                challenge.getTitle(),
                challenge.getDescription(),
                challenge.getStartDate(),
                challenge.getEndDate(),
                challenge.getEffectiveStatus().name(),
                challenge.getTargetAction().getId(),
                challenge.getTargetAction().getTitle(),
                challenge.getTargetCount(),
                challenge.getBonusPoints(),
                challenge.getMaxParticipants(),
                participantCount,
                joined,
                participationStatus,
                progressCount,
                completedAt
        );
    }

    private ChallengeParticipationDto mapToParticipationDto(ChallengeParticipation p) {
        Challenge c = p.getChallenge();
        return new ChallengeParticipationDto(
                p.getId(),
                c.getId(),
                c.getTitle(),
                c.getDescription(),
                c.getTargetAction().getId(),
                c.getTargetAction().getTitle(),
                c.getTargetCount(),
                p.getProgressCount(),
                c.getBonusPoints(),
                p.getStatus().name(),
                p.getJoinedAt(),
                p.getCompletedAt(),
                c.getStartDate(),
                c.getEndDate(),
                c.getEffectiveStatus().name()
        );
    }
}
