package com.carbontrack.backend.challenge;

import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.user.Role;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/challenges")
public class ChallengeController {

    private final ChallengeService challengeService;
    private final UserRepository userRepository;

    public ChallengeController(ChallengeService challengeService, UserRepository userRepository) {
        this.challengeService = challengeService;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<List<ChallengeDto>> getChallenges(@AuthenticationPrincipal AuthenticatedUserPrincipal principal) {
        User user = null;
        if (principal != null) {
            user = userRepository.findById(principal.getId()).orElse(null);
        }
        List<ChallengeDto> challenges = challengeService.getActiveChallengesForStudent(user);
        return ResponseEntity.ok(challenges);
    }

    @GetMapping("/my")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<List<ChallengeParticipationDto>> getMyChallenges(@AuthenticationPrincipal AuthenticatedUserPrincipal principal) {
        if (principal.getRole() != Role.STUDENT) {
            throw new SecurityException("Only students can view their challenge participations");
        }
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        List<ChallengeParticipationDto> myChallenges = challengeService.getMyChallenges(user);
        return ResponseEntity.ok(myChallenges);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ChallengeDto> getChallengeDetails(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @PathVariable("id") UUID id) {
        User user = null;
        if (principal != null) {
            user = userRepository.findById(principal.getId()).orElse(null);
        }
        ChallengeDto challenge = challengeService.getChallengeDetails(user, id);
        return ResponseEntity.ok(challenge);
    }

    @PostMapping("/{id}/join")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ChallengeParticipationDto> joinChallenge(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @PathVariable("id") UUID id) {
        if (principal.getRole() != Role.STUDENT) {
            throw new SecurityException("Only students can join challenges");
        }
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        ChallengeParticipationDto participation = challengeService.joinChallenge(user, id);
        return ResponseEntity.ok(participation);
    }
}
