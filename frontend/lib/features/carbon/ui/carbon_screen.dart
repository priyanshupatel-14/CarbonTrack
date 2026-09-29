import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../../action/provider/action_provider.dart';
import '../../action/ui/action_catalog_screen.dart';
import '../../action/ui/admin_verification_screen.dart';
import '../../action/ui/my_submissions_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../challenges/providers/challenge_provider.dart';
import '../../challenges/providers/leaderboard_provider.dart';
import '../../challenges/ui/admin_challenges_screen.dart';
import '../../challenges/ui/challenges_screen.dart';
import '../../challenges/ui/leaderboard_screen.dart';
import '../../points/providers/point_provider.dart';
import '../../points/ui/points_history_screen.dart';
import '../../rewards/providers/reward_provider.dart';
import '../../rewards/ui/admin_rewards_screen.dart';
import '../../rewards/ui/my_coupons_screen.dart';
import '../../rewards/ui/rewards_screen.dart';
import '../providers/carbon_provider.dart';

class CarbonScreen extends ConsumerStatefulWidget {
  const CarbonScreen({super.key});

  @override
  ConsumerState<CarbonScreen> createState() => _CarbonScreenState();
}

class _CarbonScreenState extends ConsumerState<CarbonScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.role == 'ADMIN';

    final List<Widget> screens = [
      CarbonSummaryView(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
      const CarbonHistoryView(),
      const CarbonEntryView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CarbonTrack',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
            ),
            Text(
              user != null ? '${user.firstName} (${user.role})' : 'Campus Sustainability',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Verification Queue',
              icon: const Icon(Icons.fact_check_outlined, color: AppColors.primary),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen()));
              },
            )
          else
            IconButton(
              tooltip: 'Points Activity',
              icon: const Icon(Icons.eco_rounded, color: AppColors.primary),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsHistoryScreen()));
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.mintSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    user != null ? '${user.firstName} ${user.lastName}' : 'CarbonTrack',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user != null ? user.email : 'Campus Sustainability Platform',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: AppColors.primary),
              title: const Text('Dashboard'),
              selected: _currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.nature_people_rounded, color: AppColors.primary),
              title: const Text('Sustainable Actions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ActionCatalogScreen()));
              },
            ),
            if (!isAdmin)
              ListTile(
                leading: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary),
                title: const Text('My Submissions'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MySubmissionsScreen()));
                },
              ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
              title: const Text('Challenges'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard_outlined, color: AppColors.primary),
              title: const Text('Leaderboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary),
              title: const Text('Rewards Catalog'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()));
              },
            ),
            if (!isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                title: const Text('My Coupons'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCouponsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_edu_rounded, color: AppColors.primary),
                title: const Text('Green Points Ledger'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsHistoryScreen()));
                },
              ),
            ],
            if (isAdmin) ...[
              const Divider(height: AppSpacing.lg),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Text('ADMINISTRATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              ),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined, color: AppColors.statusWarning),
                title: const Text('Verification Queue'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.statusWarning),
                title: const Text('Manage Challenges'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChallengesScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.store_mall_directory_outlined, color: AppColors.statusWarning),
                title: const Text('Manage Rewards'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRewardsScreen()));
                },
              ),
            ],
            const Divider(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.statusError),
              title: const Text('Sign Out', style: TextStyle(color: AppColors.statusError)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authStateProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: 'Record',
          ),
        ],
      ),
    );
  }
}

class CarbonSummaryView extends ConsumerWidget {
  final ValueChanged<int> onNavigateToTab;

  const CarbonSummaryView({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.role == 'ADMIN';

    final summaryAsync = ref.watch(carbonSummaryProvider);
    final pointsAsync = isAdmin ? null : ref.watch(pointBalanceProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider(0));
    final myChallengesAsync = isAdmin ? null : ref.watch(myChallengesProvider);

    final pendingReviewsAsync = isAdmin ? ref.watch(pendingReviewsProvider) : null;
    final adminChallengesAsync = isAdmin ? ref.watch(adminChallengesProvider) : null;
    final activeRewardsAsync = isAdmin ? ref.watch(activeRewardsProvider) : null;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(carbonSummaryProvider);
        if (isAdmin) {
          ref.invalidate(pendingReviewsProvider);
          ref.invalidate(adminChallengesProvider);
          ref.invalidate(activeRewardsProvider);
        } else {
          ref.invalidate(pointBalanceProvider);
          ref.invalidate(myChallengesProvider);
        }
        ref.invalidate(leaderboardProvider(0));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome & Action Banner
            AppCard(
              backgroundColor: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAdmin
                                  ? 'Welcome back, ${user?.firstName ?? "Admin"} (Administrator)'
                                  : 'Welcome back, ${user?.firstName ?? "Student"}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAdmin
                                  ? 'Campus Sustainability Management & Verification Portal.'
                                  : 'Track campus carbon footprint & complete sustainable actions.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (isAdmin) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusWarning,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                            icon: const Icon(Icons.fact_check_outlined, size: 18),
                            label: const Text('Review Queue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen()));
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                            icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                            label: const Text('Manage Challenges', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChallengesScreen()));
                            },
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                            icon: const Icon(Icons.nature_people_rounded, size: 18),
                            label: const Text('Take Action', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ActionCatalogScreen()));
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Record Activity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: () => onNavigateToTab(2),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick Stats Row
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.mintBorder),
              ),
              child: Column(
                children: [
                  if (isAdmin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen())),
                          child: _buildStatColumn(
                            'Pending Reviews',
                            pendingReviewsAsync!.when(
                              data: (list) => '${list.length}',
                              loading: () => '...',
                              error: (_, _) => '0',
                            ),
                            Icons.fact_check_outlined,
                            AppColors.statusWarning,
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.mintBorder),
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChallengesScreen())),
                          child: _buildStatColumn(
                            'Active Challenges',
                            adminChallengesAsync!.when(
                              data: (list) => '${list.length}',
                              loading: () => '...',
                              error: (_, _) => '0',
                            ),
                            Icons.emoji_events_rounded,
                            AppColors.primary,
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.mintBorder),
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRewardsScreen())),
                          child: _buildStatColumn(
                            'Active Rewards',
                            activeRewardsAsync!.when(
                              data: (list) => '${list.length}',
                              loading: () => '...',
                              error: (_, _) => '0',
                            ),
                            Icons.card_giftcard_rounded,
                            AppColors.primary,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsHistoryScreen())),
                          child: _buildStatColumn(
                            'Green Points',
                            pointsAsync!.when(
                              data: (pts) => '$pts',
                              loading: () => '...',
                              error: (_, _) => '0',
                            ),
                            Icons.eco_rounded,
                            AppColors.primary,
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.mintBorder),
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                          child: _buildStatColumn(
                            'Campus Rank',
                            leaderboardAsync.when(
                              data: (data) => data.myRank != null ? '#${data.myRank}' : 'Unranked',
                              loading: () => '...',
                              error: (_, _) => '-',
                            ),
                            Icons.leaderboard_rounded,
                            AppColors.primary,
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.mintBorder),
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen())),
                          child: _buildStatColumn(
                            'Active Goals',
                            myChallengesAsync!.when(
                              data: (list) => '${list.where((c) => c.status == "JOINED").length}',
                              loading: () => '...',
                              error: (_, _) => '0',
                            ),
                            Icons.emoji_events_rounded,
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                  // Challenge progress bar only for student
                  if (!isAdmin && myChallengesAsync != null)
                    myChallengesAsync.when(
                      data: (participations) {
                        final activeList = participations.where((c) => c.status == "JOINED").toList();
                        if (activeList.isEmpty) return const SizedBox.shrink();
                        final top = activeList.first;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: AppSpacing.xl, color: AppColors.mintBorder),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Current: ${top.challengeTitle}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${top.progressCount}/${top.targetCount} actions',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.emerald),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: top.progressRatio,
                                backgroundColor: Colors.white,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Carbon Impact Summary Card
            summaryAsync.when(
              data: (summary) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Carbon Footprint',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            summary.reportingPeriod,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${summary.totalCo2e.toStringAsFixed(2)} kg CO2e',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Calculated using Indian campus emission factors (CEA India grid & MoPNG transport baselines).',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const Divider(height: AppSpacing.xl),

                    // Category bars
                    _buildCategoryRow('Transport', summary.transportationCo2e, summary.totalCo2e, AppColors.transport, Icons.directions_car_rounded),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCategoryRow('Electricity', summary.electricityCo2e, summary.totalCo2e, AppColors.electricity, Icons.bolt_rounded),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCategoryRow('Food', summary.foodCo2e, summary.totalCo2e, AppColors.food, Icons.restaurant_rounded),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCategoryRow('Waste', summary.wasteCo2e, summary.totalCo2e, AppColors.waste, Icons.delete_outline_rounded),
                  ],
                ),
              ),
              loading: () => const AppLoadingView(message: 'Calculating carbon footprint...'),
              error: (e, _) => AppErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(carbonSummaryProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(String title, double co2e, double total, Color color, IconData icon) {
    final ratio = total > 0 ? (co2e / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const Spacer(),
            Text('${co2e.toStringAsFixed(2)} kg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.surfaceSecondary,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class CarbonHistoryView extends ConsumerWidget {
  const CarbonHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(carbonHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(carbonHistoryProvider);
        },
        child: historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return const AppEmptyState(
                icon: Icons.history_rounded,
                title: 'No Activities Recorded',
                message: 'You have not recorded any carbon activities yet. Switch to the Record tab to log transport or electricity usage.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final act = history[index];
                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.eco_outlined, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.activityType.replaceAll('_', ' '),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${act.quantity} ${act.unit} • ${act.activityDate}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${act.co2e.toStringAsFixed(2)} kg',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const AppLoadingView(message: 'Loading activity history...'),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(carbonHistoryProvider),
          ),
        ),
      ),
    );
  }
}

class CarbonEntryView extends ConsumerStatefulWidget {
  const CarbonEntryView({super.key});

  @override
  ConsumerState<CarbonEntryView> createState() => _CarbonEntryViewState();
}

class _CarbonEntryViewState extends ConsumerState<CarbonEntryView> {
  final _quantityController = TextEditingController();
  String _selectedCategory = 'TRANSPORTATION';
  String _selectedType = 'PETROL_CAR';
  String _selectedUnit = 'km';
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Log Carbon Activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Record daily campus transportation, electricity, or waste to track emissions.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'TRANSPORTATION', child: Text('Transportation')),
                        DropdownMenuItem(value: 'ELECTRICITY', child: Text('Electricity Consumption')),
                        DropdownMenuItem(value: 'FOOD', child: Text('Food & Meals')),
                        DropdownMenuItem(value: 'WASTE', child: Text('Campus Waste')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val!;
                          if (val == 'TRANSPORTATION') {
                            _selectedType = 'PETROL_CAR';
                            _selectedUnit = 'km';
                          } else if (val == 'ELECTRICITY') {
                            _selectedType = 'ELECTRICITY_CONSUMPTION';
                            _selectedUnit = 'kWh';
                          } else if (val == 'FOOD') {
                            _selectedType = 'VEGETARIAN';
                            _selectedUnit = 'meals';
                          } else {
                            _selectedType = 'GENERAL_WASTE';
                            _selectedUnit = 'kg';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const Text('Activity Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(),
                      items: _getActivityItems(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: AppSpacing.xs),
                              TextFormField(
                                controller: _quantityController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(hintText: 'e.g. 10'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              const SizedBox(height: AppSpacing.xs),
                              TextFormField(
                                initialValue: _selectedUnit,
                                readOnly: true,
                                decoration: const InputDecoration(filled: true, fillColor: AppColors.surfaceSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveActivity,
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Save Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getActivityItems() {
    switch (_selectedCategory) {
      case 'TRANSPORTATION':
        return const [
          DropdownMenuItem(value: 'PETROL_CAR', child: Text('Petrol Car')),
          DropdownMenuItem(value: 'DIESEL_CAR', child: Text('Diesel Car / Cab')),
          DropdownMenuItem(value: 'PETROL_TWO_WHEELER', child: Text('Motorcycle / Scooter')),
          DropdownMenuItem(value: 'PUBLIC_BUS', child: Text('Campus / Public Bus')),
          DropdownMenuItem(value: 'TRAIN', child: Text('Metro / Train Transit')),
          DropdownMenuItem(value: 'CYCLING', child: Text('Bicycle / Cycling (Zero Emission)')),
          DropdownMenuItem(value: 'WALKING', child: Text('Walking (Zero Emission)')),
        ];
      case 'ELECTRICITY':
        return const [
          DropdownMenuItem(value: 'ELECTRICITY_CONSUMPTION', child: Text('Grid Electricity (kWh)')),
        ];
      case 'FOOD':
        return const [
          DropdownMenuItem(value: 'VEGAN', child: Text('Plant-Based Vegan Meal')),
          DropdownMenuItem(value: 'VEGETARIAN', child: Text('Vegetarian Meal')),
          DropdownMenuItem(value: 'MIXED', child: Text('Mixed Diet Meal')),
          DropdownMenuItem(value: 'NON_VEGETARIAN', child: Text('Standard Non-Veg Meal')),
        ];
      case 'WASTE':
      default:
        return const [
          DropdownMenuItem(value: 'GENERAL_WASTE', child: Text('General Landfill Waste')),
          DropdownMenuItem(value: 'PLASTIC', child: Text('Recycled Plastic')),
          DropdownMenuItem(value: 'PAPER', child: Text('Recycled Paper')),
          DropdownMenuItem(value: 'GLASS', child: Text('Recycled Glass')),
          DropdownMenuItem(value: 'METAL', child: Text('Recycled Metal')),
        ];
    }
  }

  Future<void> _saveActivity() async {
    final messenger = ScaffoldMessenger.of(context);
    final qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Please enter a valid positive quantity.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final date = DateTime.now().toIso8601String().split('T')[0];
      await ref.read(carbonRepositoryProvider).recordActivity(
            _selectedCategory,
            _selectedType,
            qty,
            _selectedUnit,
            date,
          );
      ref.invalidate(carbonHistoryProvider);
      ref.invalidate(carbonSummaryProvider);
      _quantityController.clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('Activity logged successfully!'), backgroundColor: AppColors.statusSuccess),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save activity: $e'), backgroundColor: AppColors.statusError),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
