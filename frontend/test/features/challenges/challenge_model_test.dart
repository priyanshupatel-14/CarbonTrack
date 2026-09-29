import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/challenges/models/challenge_model.dart';

void main() {
  group('Challenge Tests', () {
    test('fromJson parses full challenge JSON correctly', () {
      final json = {
        'id': 'c-123',
        'title': 'Cycle to College',
        'description': 'Save carbon by cycling to campus',
        'startDate': '2026-09-01T00:00:00Z',
        'endDate': '2026-09-30T23:59:59Z',
        'status': 'ACTIVE',
        'targetActionId': 'a-1',
        'targetActionTitle': 'Cycling to College',
        'targetCount': 5,
        'bonusPoints': 50,
        'maxParticipants': 100,
        'participantCount': 12,
        'joined': true,
        'participationStatus': 'JOINED',
        'progressCount': 3,
        'completedAt': null,
      };

      final challenge = Challenge.fromJson(json);

      expect(challenge.id, 'c-123');
      expect(challenge.title, 'Cycle to College');
      expect(challenge.description, 'Save carbon by cycling to campus');
      expect(challenge.status, 'ACTIVE');
      expect(challenge.targetActionTitle, 'Cycling to College');
      expect(challenge.targetCount, 5);
      expect(challenge.bonusPoints, 50);
      expect(challenge.participantCount, 12);
      expect(challenge.isJoined, isTrue);
      expect(challenge.isCompleted, isFalse);
      expect(challenge.currentProgress, 3);
      expect(challenge.progressRatio, 0.6);
    });

    test('progressRatio caps at 1.0 and handles zero targetCount', () {
      final json = {
        'id': 'c-124',
        'title': 'Recycle Plastic',
        'description': 'Recycle bottles',
        'startDate': '2026-09-01T00:00:00Z',
        'endDate': '2026-09-30T23:59:59Z',
        'status': 'ACTIVE',
        'targetActionId': 'a-2',
        'targetActionTitle': 'Recycling',
        'targetCount': 5,
        'bonusPoints': 20,
        'maxParticipants': null,
        'participantCount': 5,
        'joined': true,
        'participationStatus': 'COMPLETED',
        'progressCount': 7,
        'completedAt': '2026-09-15T10:00:00Z',
      };

      final challenge = Challenge.fromJson(json);

      expect(challenge.isCompleted, isTrue);
      expect(challenge.progressRatio, 1.0);
    });

    test('toJson serializes correctly', () {
      final challenge = Challenge(
        id: 'c-125',
        title: 'Tree Planting',
        description: 'Campus greening',
        startDate: '2026-09-01T00:00:00Z',
        endDate: '2026-09-30T23:59:59Z',
        status: 'ACTIVE',
        targetActionId: 'a-3',
        targetActionTitle: 'Tree Planting',
        targetCount: 1,
        bonusPoints: 100,
        maxParticipants: 50,
        participantCount: 25,
        joined: false,
      );

      final map = challenge.toJson();
      expect(map['id'], 'c-125');
      expect(map['title'], 'Tree Planting');
      expect(map['targetCount'], 1);
      expect(map['bonusPoints'], 100);
      expect(map['maxParticipants'], 50);
      expect(map['participantCount'], 25);
      expect(map['joined'], isFalse);
    });
  });
}
