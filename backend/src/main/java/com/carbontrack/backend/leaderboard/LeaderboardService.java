package com.carbontrack.backend.leaderboard;

import com.carbontrack.backend.points.PointService;
import com.carbontrack.backend.user.Role;
import com.carbontrack.backend.user.User;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class LeaderboardService {

    private final JdbcTemplate jdbcTemplate;
    private final PointService pointService;

    public LeaderboardService(JdbcTemplate jdbcTemplate, PointService pointService) {
        this.jdbcTemplate = jdbcTemplate;
        this.pointService = pointService;
    }

    private record StudentLeaderboardRow(
            UUID userId,
            String firstName,
            String lastName,
            int points
    ) {}

    public LeaderboardResponse getLeaderboard(User currentUser, int page, int size) {
        int safePage = Math.max(0, page);
        int safeSize = Math.min(Math.max(1, size), 100);

        String sql = """
            SELECT u.id, u.first_name, u.last_name, COALESCE(SUM(pt.points), 0) AS total_points
            FROM users u
            LEFT JOIN point_transactions pt ON pt.user_id = u.id
            WHERE u.role = 'STUDENT'
            GROUP BY u.id, u.first_name, u.last_name, u.created_at
            ORDER BY total_points DESC, u.created_at ASC, u.id ASC
            """;

        List<StudentLeaderboardRow> allRows = jdbcTemplate.query(sql, (rs, rowNum) -> new StudentLeaderboardRow(
                UUID.fromString(rs.getString("id")),
                rs.getString("first_name"),
                rs.getString("last_name"),
                rs.getInt("total_points")
        ));

        int totalEntries = allRows.size();
        int totalPages = totalEntries == 0 ? 0 : (int) Math.ceil((double) totalEntries / safeSize);

        Integer myRank = null;
        Integer myPoints = null;

        if (currentUser != null && currentUser.getRole() == Role.STUDENT) {
            for (int i = 0; i < allRows.size(); i++) {
                if (allRows.get(i).userId().equals(currentUser.getId())) {
                    myRank = i + 1;
                    myPoints = allRows.get(i).points();
                    break;
                }
            }
            if (myPoints == null) {
                myPoints = pointService.getBalance(currentUser);
            }
        }

        int fromIndex = Math.min(safePage * safeSize, totalEntries);
        int toIndex = Math.min(fromIndex + safeSize, totalEntries);

        List<LeaderboardEntryDto> entries = new ArrayList<>();
        for (int i = fromIndex; i < toIndex; i++) {
            StudentLeaderboardRow row = allRows.get(i);
            String displayName = formatStudentName(row.firstName(), row.lastName());
            entries.add(new LeaderboardEntryDto(i + 1, displayName, row.points()));
        }

        return new LeaderboardResponse(
                entries,
                myRank,
                myPoints,
                totalEntries,
                totalPages,
                safePage
        );
    }

    private String formatStudentName(String firstName, String lastName) {
        if (firstName == null && lastName == null) {
            return "Anonymous Student";
        }
        if (firstName == null) {
            return lastName.trim();
        }
        if (lastName == null || lastName.trim().isEmpty()) {
            return firstName.trim();
        }
        return (firstName.trim() + " " + lastName.trim()).trim();
    }
}
