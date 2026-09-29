import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/sustainable_action.dart';
import '../provider/action_provider.dart';
import 'action_submission_screen.dart';
import 'admin_verification_screen.dart';
import 'my_submissions_screen.dart';

class ActionCatalogScreen extends ConsumerStatefulWidget {
  const ActionCatalogScreen({super.key});

  @override
  ConsumerState<ActionCatalogScreen> createState() => _ActionCatalogScreenState();
}

class _ActionCatalogScreenState extends ConsumerState<ActionCatalogScreen> {
  String _selectedCategory = 'ALL';

  @override
  Widget build(BuildContext context) {
    final actionsAsync = ref.watch(availableActionsProvider);
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sustainable Actions'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Verification Queue',
              icon: const Icon(Icons.fact_check_outlined, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
                );
              },
            )
          else
            IconButton(
              tooltip: 'My Submissions',
              icon: const Icon(Icons.history_rounded, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MySubmissionsScreen()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Category filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                _buildCategoryFilter('ALL', 'All Actions'),
                const SizedBox(width: AppSpacing.sm),
                _buildCategoryFilter('TRANSPORT', 'Transport'),
                const SizedBox(width: AppSpacing.sm),
                _buildCategoryFilter('ENERGY', 'Energy Saving'),
                const SizedBox(width: AppSpacing.sm),
                _buildCategoryFilter('WASTE', 'Waste & Recycling'),
                const SizedBox(width: AppSpacing.sm),
                _buildCategoryFilter('FOOD', 'Plant-Based Food'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(availableActionsProvider);
              },
              child: actionsAsync.when(
                data: (actions) {
                  final filtered = _selectedCategory == 'ALL'
                      ? actions
                      : actions.where((a) => a.category.toUpperCase() == _selectedCategory).toList();

                  if (filtered.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.eco_outlined,
                      title: 'No Actions Found',
                      message: 'No sustainable actions found for this category. Check back later!',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final action = filtered[index];
                      return _buildActionCard(action, isAdmin);
                    },
                  );
                },
                loading: () => const AppLoadingView(message: 'Loading campus actions...'),
                error: (e, _) => AppErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(availableActionsProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(String category, String label) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      onSelected: (_) {
        setState(() {
          _selectedCategory = category;
        });
      },
    );
  }

  Widget _buildActionCard(SustainableAction action, bool isAdmin) {
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
                  action.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.mintBorder),
                ),
                child: Text(
                  action.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            action.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Metadata row: Impact & Requirement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, size: 16, color: AppColors.emerald),
                const SizedBox(width: 6),
                Text(
                  '-${action.estimatedImpact.toStringAsFixed(1)} kg CO2e saved',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                const Text(
                  'AI Verification',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: isAdmin
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Review Submissions in Queue'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
                      );
                    },
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Start & Upload Evidence'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActionSubmissionScreen(action: action),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
