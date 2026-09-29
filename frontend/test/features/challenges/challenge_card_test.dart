import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/challenges/models/challenge_model.dart';
import 'package:frontend/features/challenges/ui/challenge_card.dart';

void main() {
  group('ChallengeCard Widget Tests', () {
    testWidgets('renders challenge card with Join button when not joined', (tester) async {
      final challenge = Challenge(
        id: 'c-1',
        title: 'Cycle to College',
        description: 'Take your bike for 5 days',
        startDate: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        endDate: DateTime.now().add(const Duration(days: 4)).toIso8601String(),
        status: 'ACTIVE',
        targetActionId: 'a-1',
        targetActionTitle: 'Cycling to College',
        targetCount: 5,
        bonusPoints: 50,
        maxParticipants: 50,
        participantCount: 10,
        joined: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChallengeCard(
                challenge: challenge,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cycle to College'), findsOneWidget);
      expect(find.text('+50 pts'), findsOneWidget);
      expect(find.text('Join Challenge'), findsOneWidget);
    });

    testWidgets('renders challenge card with progress when joined', (tester) async {
      final challenge = Challenge(
        id: 'c-2',
        title: 'Campus Recycling Drive',
        description: 'Recycle bottles',
        startDate: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        endDate: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        status: 'ACTIVE',
        targetActionId: 'a-2',
        targetActionTitle: 'Recycling',
        targetCount: 5,
        bonusPoints: 30,
        participantCount: 20,
        joined: true,
        participationStatus: 'JOINED',
        progressCount: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChallengeCard(
                challenge: challenge,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Campus Recycling Drive'), findsOneWidget);
      expect(find.text('3 / 5 completed'), findsOneWidget);
      expect(find.text('View Progress'), findsOneWidget);
    });

    testWidgets('renders completed badge when completed', (tester) async {
      final challenge = Challenge(
        id: 'c-3',
        title: 'Tree Planting Day',
        description: 'Campus greening',
        startDate: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        endDate: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        status: 'ACTIVE',
        targetActionId: 'a-3',
        targetActionTitle: 'Tree Planting',
        targetCount: 1,
        bonusPoints: 100,
        participantCount: 15,
        joined: true,
        participationStatus: 'COMPLETED',
        progressCount: 1,
        completedAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChallengeCard(
                challenge: challenge,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
    });
  });
}
