import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/action/models/action_submission.dart';
import 'package:frontend/features/action/provider/action_provider.dart';
import 'package:frontend/features/action/ui/my_submissions_screen.dart';

void main() {
  group('MySubmissionsScreen Widget Tests', () {
    testWidgets('renders empty state when there are no submissions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSubmissionsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: MySubmissionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Submissions Yet'), findsOneWidget);
      expect(
        find.text('Perform sustainable campus actions and upload evidence to earn Green Points!'),
        findsOneWidget,
      );
    });

    testWidgets('renders list of submissions with appropriate status badges', (tester) async {
      final mockSubmissions = [
        ActionSubmission(
          id: 'sub-1',
          sustainableActionId: 'act-1',
          actionTitle: 'Cycle to Campus',
          status: 'VERIFIED',
          submittedAt: '2026-09-29T10:00:00Z',
          completedAt: '2026-09-29T10:01:00Z',
        ),
        ActionSubmission(
          id: 'sub-2',
          sustainableActionId: 'act-2',
          actionTitle: 'Plant a Native Tree',
          status: 'REVIEW_REQUIRED',
          submittedAt: '2026-09-29T11:00:00Z',
        ),
        ActionSubmission(
          id: 'sub-3',
          sustainableActionId: 'act-3',
          actionTitle: 'Segregated Recycling',
          status: 'REJECTED',
          submittedAt: '2026-09-29T12:00:00Z',
          completedAt: '2026-09-29T12:02:00Z',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSubmissionsProvider.overrideWith((ref) => Future.value(mockSubmissions)),
          ],
          child: const MaterialApp(
            home: MySubmissionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Titles
      expect(find.text('Cycle to Campus'), findsOneWidget);
      expect(find.text('Plant a Native Tree'), findsOneWidget);
      expect(find.text('Segregated Recycling'), findsOneWidget);

      // Status badges
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);

      // Descriptions
      expect(
        find.text('Automated verification successful. Green Points credited to your account.'),
        findsOneWidget,
      );
      expect(
        find.text('Submitted evidence is pending manual verification by campus administrators.'),
        findsOneWidget,
      );
      expect(
        find.text('Evidence could not be verified (e.g., location mismatch, duplicate image, or expired timestamp).'),
        findsOneWidget,
      );
    });

    testWidgets('renders error view on failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSubmissionsProvider.overrideWith((ref) => Future.error(Exception('Network Error'))),
          ],
          child: const MaterialApp(
            home: MySubmissionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load submissions'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
