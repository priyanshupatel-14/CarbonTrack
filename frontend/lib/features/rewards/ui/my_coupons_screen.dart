import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/coupon_model.dart';
import '../providers/reward_provider.dart';
import 'rewards_screen.dart';

class MyCouponsScreen extends ConsumerWidget {
  const MyCouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(myCouponsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Campus Coupons'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(myCouponsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myCouponsProvider);
        },
        child: couponsAsync.when(
          data: (coupons) {
            if (coupons.isEmpty) {
              return AppEmptyState(
                icon: Icons.confirmation_number_outlined,
                title: 'No Coupons Yet',
                message: 'You have not redeemed any rewards yet. Redeem your earned Green Points for campus discounts!',
                actionLabel: 'Browse Rewards Catalog',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RewardsScreen()),
                  );
                },
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: coupons.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final coupon = coupons[index];
                return _buildCouponCard(context, coupon);
              },
            );
          },
          loading: () => const AppLoadingView(message: 'Loading your coupons...'),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(myCouponsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, Coupon coupon) {
    final isActive = coupon.status.toUpperCase() == 'ACTIVE';

    return AppCard(
      backgroundColor: isActive ? AppColors.surface : AppColors.surfaceSecondary,
      borderColor: isActive ? AppColors.mintBorder : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  coupon.reward.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              StatusBadge(status: coupon.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                coupon.reward.merchantName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Prominent Code Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: isActive ? AppColors.mintSurface : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isActive ? AppColors.mintBorder : AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COUPON CODE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        coupon.code,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: isActive ? AppColors.primaryDark : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy Code',
                  icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: coupon.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coupon code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Instructions & Timestamps
          if (isActive) ...[
            const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Present this code at campus checkout to claim your perk.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (coupon.expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Expires: ${coupon.expiresAt!.split('T')[0]}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ] else if (coupon.status == 'REDEEMED' && coupon.redeemedAt != null) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.statusSuccess),
                const SizedBox(width: 6),
                Text(
                  'Redeemed on ${coupon.redeemedAt!.split('T')[0]}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
