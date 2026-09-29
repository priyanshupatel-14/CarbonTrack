import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/leaderboard_model.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider(_currentPage));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campus Sustainability Leaderboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(leaderboardProvider(_currentPage)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaderboardProvider(_currentPage));
        },
        child: leaderboardAsync.when(
          data: (data) => _buildContent(context, data),
          loading: () => const AppLoadingView(message: 'Loading leaderboard...'),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(leaderboardProvider(_currentPage)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LeaderboardData data) {
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.role.toUpperCase() == 'ADMIN';

    return Column(
      children: [
        // Admin or Student Rank Header Card
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
                  child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Campus Leaderboard Overview',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.totalEntries} Ranked Students',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.mintBorder),
                  ),
                  child: const Text('Admin View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Your Rank',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.myRank != null ? '#${data.myRank}' : 'Unranked',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 36, color: AppColors.mintBorder),
                Column(
                  children: [
                    const Text(
                      'Your Green Points',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.myPoints ?? 0}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Table header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
          child: Row(
            children: [
              const SizedBox(
                width: 44,
                child: Text(
                  'Rank',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ),
              const Expanded(
                child: Text(
                  'Student',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ),
              const Text(
                'Green Points',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: data.entries.isEmpty
              ? const AppEmptyState(
                  icon: Icons.leaderboard_outlined,
                  title: 'No Rankings Yet',
                  message: 'Be the first student to earn Green Points on campus!',
                )
              : ListView.separated(
                  itemCount: data.entries.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final entry = data.entries[index];
                    final isCurrentUser = !isAdmin && data.myRank == entry.rank;

                    return Container(
                      color: isCurrentUser ? AppColors.mintSurface : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: _buildRankBadge(entry.rank),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  entry.studentName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                                    color: isCurrentUser ? AppColors.primaryDark : AppColors.textPrimary,
                                  ),
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: const Text(
                                      'You',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCurrentUser ? Colors.white : AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: isCurrentUser ? AppColors.mintBorder : AppColors.border),
                            ),
                            child: Text(
                              '${entry.points} pts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Pagination controls
        if (data.totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  child: const Text('Previous'),
                ),
                Text(
                  'Page ${_currentPage + 1} of ${data.totalPages}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                OutlinedButton(
                  onPressed: _currentPage < data.totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      Color bg;
      Color border;
      Color text;
      if (rank == 1) {
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFCD34D);
        text = const Color(0xFFB45309);
      } else if (rank == 2) {
        bg = const Color(0xFFF1F5F9);
        border = const Color(0xFFCBD5E1);
        text = const Color(0xFF475569);
      } else {
        bg = const Color(0xFFFFF7ED);
        border = const Color(0xFFFDBA74);
        text = const Color(0xFFC2410C);
      }

      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.2),
        ),
        child: Text(
          '$rank',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: text),
        ),
      );
    }
    return Text(
      '#$rank',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
    );
  }
}
