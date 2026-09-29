package com.carbontrack.backend.carbon;

import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/carbon")
public class CarbonController {

    private final CarbonService carbonService;
    private final UserRepository userRepository;

    public CarbonController(CarbonService carbonService, UserRepository userRepository) {
        this.carbonService = carbonService;
        this.userRepository = userRepository;
    }

    private User getAuthenticatedUser(Authentication authentication) {
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @PostMapping("/activities")
    public ResponseEntity<CarbonActivityDto> recordActivity(
            @Valid @RequestBody CarbonActivityRequest request,
            Authentication authentication) {
        User user = getAuthenticatedUser(authentication);
        return ResponseEntity.ok(carbonService.recordActivity(user, request));
    }

    @GetMapping("/activities")
    public ResponseEntity<List<CarbonActivityDto>> getActivities(Authentication authentication) {
        User user = getAuthenticatedUser(authentication);
        return ResponseEntity.ok(carbonService.getHistory(user));
    }

    @GetMapping("/history")
    public ResponseEntity<List<CarbonActivityDto>> getHistory(Authentication authentication) {
        // Alias for activities
        return getActivities(authentication);
    }

    @GetMapping("/summary")
    public ResponseEntity<CarbonSummaryDto> getSummary(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            Authentication authentication) {
        
        User user = getAuthenticatedUser(authentication);
        
        if (startDate == null) {
            startDate = LocalDate.now().withDayOfMonth(1);
        }
        if (endDate == null) {
            endDate = LocalDate.now();
        }
        
        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("startDate cannot be after endDate");
        }

        return ResponseEntity.ok(carbonService.getSummary(user, startDate, endDate));
    }
}
