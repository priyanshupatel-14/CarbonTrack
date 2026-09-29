import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import 'admin_rewards_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../points/providers/point_provider.dart';
import '../models/reward_model.dart';
import '../providers/reward_provider.dart';
import 'my_coupons_screen.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(activeRewardsProvider);
    final pointsAsync = ref.watch(pointBalanceProvider);
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.role.toUpperCase() == 'ADMIN';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campus Rewards Catalog'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Manage Rewards',
              icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminRewardsScreen()),
                );
              },
            )
          else
            IconButton(
              tooltip: 'My Coupons',
              icon: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyCouponsScreen()),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeRewardsProvider);
          if (!isAdmin) {
            ref.invalidate(pointBalanceProvider);
          }
        },
        child: Column(
          children: [
            // Admin or Student Header Banner
            if (isAdmin)
              Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.mintBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.mintBorder),
                      ),
                      child: const Icon(Icons.store_mall_directory_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Campus Rewards Catalog',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          rewardsAsync.when(
                            data: (rewards) => Text(
                              '${rewards.length} Active Rewards Available',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                            ),
                            loading: () => const Text('Loading catalog...', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                            error: (_, _) => const Text('Catalog', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminRewardsScreen()),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Manage', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.mintBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.mintBorder),
                      ),
                      child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Green Points Balance',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          pointsAsync.when(
                            data: (pts) => Text(
                              '$pts Points Available',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                            ),
                            loading: () => const Text('Loading balance...', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                            error: (_, _) => const Text('Balance unavailable', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyCouponsScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      ),
                      child: const Text('My Coupons', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Rewards List
            Expanded(
              child: rewardsAsync.when(
                data: (rewards) {
                  if (rewards.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.card_giftcard_rounded,
                      title: 'No Active Rewards',
                      message: 'Campus merchants have not published any rewards currently. Check back soon!',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    itemCount: rewards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final reward = rewards[index];
                      final userPoints = pointsAsync.value ?? 0;
                      return _buildRewardCard(context, ref, reward, userPoints, isAdmin);
                    },
                  );
                },
                loading: () => const AppLoadingView(message: 'Loading campus rewards...'),
                error: (e, _) => AppErrorView(
                  message: e.toString(),
                  onRetry: () {
                    ref.invalidate(activeRewardsProvider);
                    if (!isAdmin) {
                      ref.invalidate(pointBalanceProvider);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, WidgetRef ref, Reward reward, int userPoints, bool isAdmin) {
    final canAfford = userPoints >= reward.pointsRequired;
    final inStock = reward.inventory > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  reward.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: inStock ? AppColors.mintSurface : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: inStock ? AppColors.mintBorder : AppColors.border),
                ),
                child: Text(
                  '${reward.pointsRequired} pts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: inStock ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reward.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                reward.merchantName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Icon(
                inStock ? Icons.inventory_2_outlined : Icons.remove_circle_outline,
                size: 15,
                color: inStock ? AppColors.textMuted : AppColors.statusError,
              ),
              const SizedBox(width: 4),
              Text(
                inStock ? '${reward.inventory} remaining' : 'Out of stock',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: inStock ? FontWeight.normal : FontWeight.bold,
                  color: inStock ? AppColors.textMuted : AppColors.statusError,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          if (isAdmin)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Manage in Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminRewardsScreen()),
                  );
                },
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: inStock && canAfford ? AppColors.primary : AppColors.surfaceSecondary,
                  foregroundColor: inStock && canAfford ? Colors.white : AppColors.textMuted,
                ),
                onPressed: inStock && canAfford ? () => _confirmRedeem(context, ref, reward, userPoints) : null,
                child: Text(
                  !inStock
                      ? 'Out of Stock'
                      : !canAfford
                          ? 'Need ${reward.pointsRequired - userPoints} More Points'
                          : 'Redeem Reward',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRedeem(BuildContext context, WidgetRef ref, Reward reward, int currentPoints) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Redeem "${reward.name}" for ${reward.pointsRequired} Green Points?'),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your balance after redemption: ${currentPoints - reward.pointsRequired} pts',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Get Coupon'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(rewardRepositoryProvider).redeemReward(reward.id);
        ref.invalidate(pointBalanceProvider);
        ref.invalidate(pointHistoryProvider);
        ref.invalidate(activeRewardsProvider);
        ref.invalidate(myCouponsProvider);

        messenger.showSnackBar(
          SnackBar(
            content: Text('Coupon generated for ${reward.name}!'),
            backgroundColor: AppColors.statusSuccess,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyCouponsScreen()),
                );
              },
            ),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Redemption failed: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }
}
