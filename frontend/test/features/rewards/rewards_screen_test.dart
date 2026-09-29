import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/points/providers/point_provider.dart';
import 'package:frontend/features/rewards/models/coupon_model.dart';
import 'package:frontend/features/rewards/models/reward_model.dart';
import 'package:frontend/features/rewards/providers/reward_provider.dart';
import 'package:frontend/features/rewards/ui/my_coupons_screen.dart';
import 'package:frontend/features/rewards/ui/rewards_screen.dart';

void main() {
  group('Rewards & Coupons Widget Tests', () {
    testWidgets('RewardsScreen renders balance banner and available rewards', (tester) async {
      final mockRewards = [
        Reward(
          id: 'rew-1',
          name: 'Free Herbal Tea',
          description: 'Valid at Campus Canteen',
          pointsRequired: 50,
          inventory: 25,
          merchantName: 'Campus Canteen',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRewardsProvider.overrideWith((ref) => Future.value(mockRewards)),
            pointBalanceProvider.overrideWith((ref) => Future.value(120)),
          ],
          child: const MaterialApp(
            home: RewardsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Campus Rewards Catalog'), findsOneWidget);
      expect(find.text('120 Points Available'), findsOneWidget);
      expect(find.text('Free Herbal Tea'), findsOneWidget);
      expect(find.text('50 pts'), findsOneWidget);
      expect(find.text('Redeem Reward'), findsOneWidget);
    });

    testWidgets('MyCouponsScreen renders coupon cards with active codes', (tester) async {
      final mockCoupons = [
        Coupon(
          id: 'c-1',
          code: 'CAMPUS-TEA-9999',
          status: 'ACTIVE',
          reward: Reward(
            id: 'rew-1',
            name: 'Free Herbal Tea',
            description: 'Valid at Campus Canteen',
            pointsRequired: 50,
            inventory: 25,
            merchantName: 'Campus Canteen',
          ),
          expiresAt: '2026-12-31T23:59:59Z',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myCouponsProvider.overrideWith((ref) => Future.value(mockCoupons)),
          ],
          child: const MaterialApp(
            home: MyCouponsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Campus Coupons'), findsOneWidget);
      expect(find.text('Free Herbal Tea'), findsOneWidget);
      expect(find.text('CAMPUS-TEA-9999'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });
  });
}
