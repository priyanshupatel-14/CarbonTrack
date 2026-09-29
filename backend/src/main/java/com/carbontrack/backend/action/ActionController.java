package com.carbontrack.backend.action;

import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.verification.EvidenceDto;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/actions")
public class ActionController {

    private final ActionService actionService;

    public ActionController(ActionService actionService) {
        this.actionService = actionService;
    }

    @GetMapping
    public ResponseEntity<List<ActionDto>> getActions() {
        return ResponseEntity.ok(actionService.getActiveActions());
    }

    @PostMapping("/submissions")
    public ResponseEntity<SubmissionDto> createSubmission(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @RequestBody SubmissionRequest request) {
        return ResponseEntity.ok(actionService.createSubmission(principal, request));
    }

    @GetMapping("/submissions")
    public ResponseEntity<List<SubmissionDto>> getSubmissions(@AuthenticationPrincipal AuthenticatedUserPrincipal principal) {
        return ResponseEntity.ok(actionService.getUserSubmissions(principal));
    }

    @GetMapping("/submissions/{id}")
    public ResponseEntity<SubmissionDto> getSubmission(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @PathVariable UUID id) {
        return ResponseEntity.ok(actionService.getSubmission(principal, id));
    }

    @PostMapping(value = "/submissions/{id}/evidence", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<EvidenceDto> addEvidence(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @PathVariable UUID id,
            @RequestParam(value = "file", required = false) MultipartFile file,
            @RequestParam(value = "latitude", required = false) BigDecimal latitude,
            @RequestParam(value = "longitude", required = false) BigDecimal longitude,
            @RequestParam(value = "clientTimestamp", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime clientTimestamp) throws IOException, NoSuchAlgorithmException {
        if (principal == null) {
            throw new IllegalArgumentException("User principal is null in multipart request");
        }
        return ResponseEntity.ok(actionService.addEvidence(principal, id, file, latitude, longitude, clientTimestamp));
    }

    @PostMapping("/submissions/{id}/finalize")
    public ResponseEntity<SubmissionDto> finalizeSubmission(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @PathVariable UUID id) {
        return ResponseEntity.ok(actionService.finalizeSubmission(principal, id));
    }
}
