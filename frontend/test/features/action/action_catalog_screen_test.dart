import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/action/models/sustainable_action.dart';
import 'package:frontend/features/action/provider/action_provider.dart';
import 'package:frontend/features/action/ui/action_catalog_screen.dart';

void main() {
  group('ActionCatalogScreen Widget Tests', () {
    testWidgets('renders category chips and action list', (tester) async {
      final mockActions = [
        SustainableAction(
          id: 'act-1',
          title: 'Plant a Native Tree',
          description: 'Plant a sapling in the designated campus green belt.',
          category: 'WASTE',
          status: 'ACTIVE',
          estimatedImpact: 5.0,
          evidenceRequirements: 'Photo of planted tree with campus geotag',
          verificationRequirements: 'AI vision check for tree sapling and student',
        ),
        SustainableAction(
          id: 'act-2',
          title: 'Campus Cycling Commute',
          description: 'Cycle to lecture halls instead of using motorbikes.',
          category: 'TRANSPORT',
          status: 'ACTIVE',
          estimatedImpact: 1.2,
          evidenceRequirements: 'Photo of bicycle at campus cycle stand',
          verificationRequirements: 'AI vision check for bicycle in campus zone',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableActionsProvider.overrideWith((ref) => Future.value(mockActions)),
          ],
          child: const MaterialApp(
            home: ActionCatalogScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sustainable Actions'), findsOneWidget);
      expect(find.text('All Actions'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Plant a Native Tree'), findsOneWidget);
      expect(find.text('Campus Cycling Commute'), findsOneWidget);
      expect(find.text('-5.0 kg CO2e saved'), findsOneWidget);
      expect(find.text('-1.2 kg CO2e saved'), findsOneWidget);
      expect(find.text('Start & Upload Evidence'), findsNWidgets(2));
    });

    testWidgets('renders empty state when no actions available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableActionsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: ActionCatalogScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Actions Found'), findsOneWidget);
    });
  });
}
