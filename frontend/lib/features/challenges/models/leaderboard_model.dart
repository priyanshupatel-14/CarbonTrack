class LeaderboardEntry {
  final int rank;
  final String studentName;
  final int points;

  LeaderboardEntry({
    required this.rank,
    required this.studentName,
    required this.points,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      studentName: json['studentName'] as String? ?? 'Anonymous',
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'studentName': studentName,
      'points': points,
    };
  }
}

class LeaderboardData {
  final List<LeaderboardEntry> entries;
  final int? myRank;
  final int? myPoints;
  final int totalEntries;
  final int totalPages;
  final int currentPage;

  LeaderboardData({
    required this.entries,
    this.myRank,
    this.myPoints,
    required this.totalEntries,
    required this.totalPages,
    required this.currentPage,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? [];
    return LeaderboardData(
      entries: rawEntries
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      myRank: (json['myRank'] as num?)?.toInt(),
      myPoints: (json['myPoints'] as num?)?.toInt(),
      totalEntries: (json['totalEntries'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
    );
  }
}
