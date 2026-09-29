package com.carbontrack.backend.points;

import com.carbontrack.backend.security.AuthenticatedUserPrincipal;
import com.carbontrack.backend.user.User;
import com.carbontrack.backend.user.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/points")
public class PointController {

    private final PointService pointService;
    private final PointTransactionRepository transactionRepository;
    private final UserRepository userRepository;

    public PointController(PointService pointService, PointTransactionRepository transactionRepository, UserRepository userRepository) {
        this.pointService = pointService;
        this.transactionRepository = transactionRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/balance")
    public ResponseEntity<?> getBalance(@AuthenticationPrincipal AuthenticatedUserPrincipal principal) {
        User user = userRepository.findById(principal.getId()).orElseThrow();
        int balance = pointService.getBalance(user);
        return ResponseEntity.ok(Map.of("balance", balance));
    }

    @GetMapping("/history")
    public ResponseEntity<List<PointTransactionDto>> getHistory(@AuthenticationPrincipal AuthenticatedUserPrincipal principal) {
        User user = userRepository.findById(principal.getId()).orElseThrow();
        List<PointTransactionDto> history = transactionRepository.findByUserOrderByCreatedAtDesc(user).stream()
                .map(tx -> new PointTransactionDto(
                        tx.getId(),
                        tx.getTransactionType().name(),
                        tx.getPoints(),
                        tx.getReferenceType(),
                        tx.getReferenceId(),
                        tx.getDescription(),
                        tx.getCreatedAt()
                )).toList();
        return ResponseEntity.ok(history);
    }
}
