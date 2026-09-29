package com.carbontrack.backend.leaderboard;

import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/leaderboard")
public class LeaderboardController {

    private final LeaderboardService leaderboardService;
    private final UserRepository userRepository;

    public LeaderboardController(LeaderboardService leaderboardService, UserRepository userRepository) {
        this.leaderboardService = leaderboardService;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<LeaderboardResponse> getLeaderboard(
            @AuthenticationPrincipal AuthenticatedUserPrincipal principal,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        User currentUser = null;
        if (principal != null) {
            currentUser = userRepository.findById(principal.getId()).orElse(null);
        }
        LeaderboardResponse response = leaderboardService.getLeaderboard(currentUser, page, size);
        return ResponseEntity.ok(response);
    }
}
