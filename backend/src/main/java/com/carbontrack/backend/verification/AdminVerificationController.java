package com.carbontrack.backend.verification;

import com.carbontrack.backend.action.SubmissionDto;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/submissions")
@PreAuthorize("hasRole('ADMIN')")
public class AdminVerificationController {

    private final AdminReviewService adminReviewService;

    public AdminVerificationController(AdminReviewService adminReviewService) {
        this.adminReviewService = adminReviewService;
    }

    @GetMapping("/review")
    public ResponseEntity<List<SubmissionDto>> getPendingReviews() {
        return ResponseEntity.ok(adminReviewService.getPendingReviews());
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<Void> approveSubmission(
            @PathVariable UUID id,
            @RequestParam(value = "reason", defaultValue = "Approved by admin") String reason) {
        adminReviewService.reviewSubmission(id, true, reason);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<Void> rejectSubmission(
            @PathVariable UUID id,
            @RequestParam(value = "reason", defaultValue = "Rejected by admin") String reason) {
        adminReviewService.reviewSubmission(id, false, reason);
        return ResponseEntity.ok().build();
    }
}
