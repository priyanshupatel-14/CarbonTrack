import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/point_provider.dart';

class PointsHistoryScreen extends ConsumerWidget {
  const PointsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(pointBalanceProvider);
    final historyAsync = ref.watch(pointHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Green Points Activity'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(pointBalanceProvider);
              ref.invalidate(pointHistoryProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pointBalanceProvider);
          ref.invalidate(pointHistoryProvider);
        },
        child: Column(
          children: [
            // Current Balance Card
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.mintBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.mintBorder),
                    ),
                    child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        balanceAsync.when(
                          data: (balance) => Text(
                            '$balance Green Points',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          loading: () => const Text('...', style: TextStyle(fontSize: 20)),
                          error: (_, _) => const Text('0', style: TextStyle(fontSize: 20)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ledger Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ),
            ),
            const Divider(height: AppSpacing.md),

            // History List
            Expanded(
              child: historyAsync.when(
                data: (history) {
                  if (history.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Activity Yet',
                      message: 'Complete sustainable actions and participate in campus challenges to earn Green Points!',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final tx = history[index];
                      final isEarned = tx.points > 0;

                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: isEarned ? AppColors.mintSurface : AppColors.surfaceSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isEarned ? Icons.add_rounded : Icons.remove_rounded,
                                size: 18,
                                color: isEarned ? AppColors.emerald : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(tx.createdAt),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isEarned ? '+' : ''}${tx.points} pts',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isEarned ? AppColors.emerald : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const AppLoadingView(message: 'Loading ledger history...'),
                error: (e, _) => AppErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(pointHistoryProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.split('T')[0];
    }
  }
}
