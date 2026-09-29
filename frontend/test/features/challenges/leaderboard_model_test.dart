import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/challenges/models/leaderboard_model.dart';

void main() {
  group('Leaderboard Model Tests', () {
    test('fromJson parses leaderboard response correctly', () {
      final json = {
        'entries': [
          {
            'rank': 1,
            'studentName': 'Alice Smith',
            'points': 450,
          },
          {
            'rank': 2,
            'studentName': 'Bob Jones',
            'points': 320,
          }
        ],
        'myRank': 2,
        'myPoints': 320,
        'totalEntries': 2,
        'totalPages': 1,
        'currentPage': 0,
      };

      final leaderboard = LeaderboardData.fromJson(json);

      expect(leaderboard.entries.length, 2);
      expect(leaderboard.myRank, 2);
      expect(leaderboard.myPoints, 320);
      expect(leaderboard.currentPage, 0);
      expect(leaderboard.totalEntries, 2);
      expect(leaderboard.totalPages, 1);

      final entry1 = leaderboard.entries[0];
      expect(entry1.rank, 1);
      expect(entry1.studentName, 'Alice Smith');
      expect(entry1.points, 450);

      final entry2 = leaderboard.entries[1];
      expect(entry2.rank, 2);
      expect(entry2.studentName, 'Bob Jones');
      expect(entry2.points, 320);
    });

    test('handles empty or missing student rank gracefully', () {
      final json = {
        'entries': <Map<String, dynamic>>[],
        'myRank': null,
        'myPoints': null,
        'totalEntries': 0,
        'totalPages': 0,
        'currentPage': 0,
      };

      final leaderboard = LeaderboardData.fromJson(json);
      expect(leaderboard.entries, isEmpty);
      expect(leaderboard.myRank, isNull);
      expect(leaderboard.myPoints, isNull);
    });
  });
}
