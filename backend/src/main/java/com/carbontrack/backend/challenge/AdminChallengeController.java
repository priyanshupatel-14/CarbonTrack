package com.carbontrack.backend.challenge;

import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.user.Role;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/challenges")
@PreAuthorize("hasRole('ADMIN')")
public class AdminChallengeController {

    private final ChallengeService challengeService;

    public AdminChallengeController(ChallengeService challengeService) {
        this.challengeService = challengeService;
    }

    private void verifyAdminRole(AuthenticatedUserPrincipal principal) {
        if (principal == null || principal.getRole() != Role.ADMIN) {
            throw new SecurityException("Only admins can manage challenges");
        }
    }

    @PostMapping
    public ResponseEntity<ChallengeDto> createChallenge(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @Valid @RequestBody CreateChallengeRequest request) {
        verifyAdminRole(principal);
        ChallengeDto created = challengeService.createChallenge(request);
        return ResponseEntity.ok(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<ChallengeDto> updateChallenge(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @PathVariable("id") UUID id,
            @Valid @RequestBody CreateChallengeRequest request) {
        verifyAdminRole(principal);
        ChallengeDto updated = challengeService.updateChallenge(id, request);
        return ResponseEntity.ok(updated);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ChallengeDto> updateChallengeStatus(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @PathVariable("id") UUID id,
            @Valid @RequestBody UpdateChallengeStatusRequest request) {
        verifyAdminRole(principal);
        ChallengeDto updated = challengeService.updateChallengeStatus(id, request.status());
        return ResponseEntity.ok(updated);
    }

    @GetMapping
    public ResponseEntity<List<ChallengeDto>> getAllChallenges(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal) {
        verifyAdminRole(principal);
        List<ChallengeDto> challenges = challengeService.getAllChallengesForAdmin();
        return ResponseEntity.ok(challenges);
    }
}
