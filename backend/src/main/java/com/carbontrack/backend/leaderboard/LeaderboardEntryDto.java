package com.carbontrack.backend.leaderboard;

public record LeaderboardEntryDto(
    int rank,
    String studentName,
    int points
) {}
