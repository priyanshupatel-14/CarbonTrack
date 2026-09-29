import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../../action/models/sustainable_action.dart';
import '../../action/provider/action_provider.dart';
import '../../carbon/providers/carbon_provider.dart';
import '../models/challenge_model.dart';
import '../providers/challenge_provider.dart';

class AdminChallengesScreen extends ConsumerStatefulWidget {
  const AdminChallengesScreen({super.key});

  @override
  ConsumerState<AdminChallengesScreen> createState() => _AdminChallengesScreenState();
}

class _AdminChallengesScreenState extends ConsumerState<AdminChallengesScreen> {
  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(adminChallengesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Campus Challenges'),
        actions: [
          IconButton(
            tooltip: 'Create Challenge',
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () => _showCreateChallengeModal(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminChallengesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showCreateChallengeModal(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminChallengesProvider);
          ref.invalidate(activeChallengesProvider);
        },
        child: challengesAsync.when(
          data: (challenges) {
            if (challenges.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'No Challenges Created Yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Create campus sustainability challenges to engage and reward students.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateChallengeModal(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create First Challenge'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 80),
              itemCount: challenges.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final c = challenges[index];
                return _buildAdminChallengeCard(c);
              },
            );
          },
          loading: () => const AppLoadingView(message: 'Loading challenges...'),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(adminChallengesProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminChallengeCard(Challenge c) {
    final statusColor = _getStatusColor(c.status);

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
                  c.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: statusColor.withAlpha(60)),
                ),
                child: Text(
                  c.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            c.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.md),

          // Metadata Chips Row
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _buildMetaChip(
                Icons.task_alt_rounded,
                'Goal: ${c.targetCount}x ${c.targetActionTitle}',
                AppColors.surfaceSecondary,
                AppColors.textPrimary,
              ),
              _buildMetaChip(
                Icons.star_rounded,
                '+${c.bonusPoints} pts bonus',
                AppColors.mintSurface,
                AppColors.primaryDark,
              ),
              _buildMetaChip(
                Icons.people_outline_rounded,
                '${c.participantCount} joined',
                AppColors.surfaceSecondary,
                AppColors.textSecondary,
              ),
              _buildMetaChip(
                Icons.calendar_today_outlined,
                '${c.daysRemaining} days left',
                AppColors.surfaceSecondary,
                AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),

          // Action Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (c.status == 'DRAFT')
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Activate Challenge', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  onPressed: () => _updateStatus(c.id, 'ACTIVE'),
                ),
              if (c.status == 'ACTIVE')
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.statusError),
                  label: const Text('Cancel Challenge', style: TextStyle(color: AppColors.statusError)),
                  onPressed: () => _confirmCancel(c),
                ),
              if (c.status == 'CANCELLED')
                TextButton.icon(
                  icon: const Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Reactivate', style: TextStyle(color: AppColors.primary)),
                  onPressed: () => _updateStatus(c.id, 'ACTIVE'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.emerald;
      case 'DRAFT':
        return AppColors.statusWarning;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
      case 'EXPIRED':
        return AppColors.statusError;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _updateStatus(String challengeId, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(challengeRepositoryProvider).updateChallengeStatus(challengeId, newStatus);
      ref.invalidate(adminChallengesProvider);
      ref.invalidate(activeChallengesProvider);
      ref.invalidate(carbonSummaryProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Challenge status updated to $newStatus'),
          backgroundColor: AppColors.statusSuccess,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _confirmCancel(Challenge c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Challenge'),
        content: Text('Are you sure you want to cancel "${c.title}"? Students will no longer be able to participate or earn bonus points.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, Keep Active')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel Challenge'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _updateStatus(c.id, 'CANCELLED');
    }
  }

  void _showCreateChallengeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const _CreateChallengeBottomSheet(),
    ).then((_) {
      ref.invalidate(adminChallengesProvider);
      ref.invalidate(activeChallengesProvider);
      ref.invalidate(carbonSummaryProvider);
    });
  }
}

class _CreateChallengeBottomSheet extends ConsumerStatefulWidget {
  const _CreateChallengeBottomSheet();

  @override
  ConsumerState<_CreateChallengeBottomSheet> createState() => _CreateChallengeBottomSheetState();
}

class _CreateChallengeBottomSheetState extends ConsumerState<_CreateChallengeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetCountController = TextEditingController(text: '3');
  final _bonusPointsController = TextEditingController(text: '50');
  final _durationDaysController = TextEditingController(text: '14');
  final _maxParticipantsController = TextEditingController();

  String? _selectedActionId;
  String _status = 'ACTIVE';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetCountController.dispose();
    _bonusPointsController.dispose();
    _durationDaysController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedActionId == null) {
      setState(() => _errorMessage = 'Please select a target sustainable action.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    final durationDays = int.tryParse(_durationDaysController.text.trim()) ?? 14;
    final endDate = now.add(Duration(days: durationDays));
    final targetCount = int.parse(_targetCountController.text.trim());
    final bonusPoints = int.parse(_bonusPointsController.text.trim());
    final maxPartText = _maxParticipantsController.text.trim();
    final maxParticipants = maxPartText.isNotEmpty ? int.tryParse(maxPartText) : null;

    final payload = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'startDate': now.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': _status,
      'targetActionId': _selectedActionId,
      'targetCount': targetCount,
      'bonusPoints': bonusPoints,
      if (maxParticipants != null && maxParticipants > 0) 'maxParticipants': maxParticipants,
    };

    try {
      await ref.read(challengeRepositoryProvider).createChallenge(payload);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge published successfully!'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = formatApiError(e, fallback: 'Failed to create challenge. Please verify inputs.');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final actionsAsync = ref.watch(availableActionsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: bottomInset + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Campus Challenge',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Text(
                'Define a collective sustainability goal for campus students with bonus Green Points.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.statusErrorBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.statusError.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.statusError),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.statusError, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Challenge Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Challenge Title *',
                  hintText: 'e.g., Bike to Campus Week',
                  prefixIcon: Icon(Icons.emoji_events_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Challenge title is required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Explain the goal and why students should participate...',
                  prefixIcon: Icon(Icons.description_outlined, size: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Target Action Dropdown
              actionsAsync.when(
                data: (actions) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedActionId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Target Sustainable Action *',
                      prefixIcon: Icon(Icons.eco_outlined, size: 20),
                    ),
                    hint: const Text('Select verified action'),
                    items: actions.map((SustainableAction a) {
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Text(
                          '${a.title} (${a.category})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedActionId = val),
                    validator: (val) => val == null ? 'Please select a target action' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text(
                  'Failed to load actions catalog',
                  style: TextStyle(color: AppColors.statusError, fontSize: 12),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Target Count & Bonus Points
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Completions *',
                        hintText: 'e.g. 3',
                        prefixIcon: Icon(Icons.flag_outlined, size: 20),
                      ),
                      validator: (val) {
                        final parsed = int.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed <= 0) return 'Min 1';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _bonusPointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bonus Points *',
                        hintText: 'e.g. 50',
                        prefixIcon: Icon(Icons.star_outline_rounded, size: 20),
                      ),
                      validator: (val) {
                        final parsed = int.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed < 0) return 'Min 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Duration & Initial Status
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (Days) *',
                        hintText: 'e.g. 14',
                        prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                      ),
                      validator: (val) {
                        final parsed = int.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed <= 0) return 'Min 1 day';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Initial Status',
                        prefixIcon: Icon(Icons.toggle_on_outlined, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (Publish Now)')),
                        DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT (Save for later)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Max Participants (Optional)
              TextFormField(
                controller: _maxParticipantsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Participants (Optional)',
                  hintText: 'Leave empty for unlimited',
                  prefixIcon: Icon(Icons.people_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _status == 'ACTIVE' ? 'Publish Challenge' : 'Save as Draft',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
