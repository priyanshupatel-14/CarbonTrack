package com.carbontrack.backend.leaderboard;

import java.util.List;

public record LeaderboardResponse(
    List<LeaderboardEntryDto> entries,
    Integer myRank,
    Integer myPoints,
    long totalEntries,
    int totalPages,
    int currentPage
) {}
