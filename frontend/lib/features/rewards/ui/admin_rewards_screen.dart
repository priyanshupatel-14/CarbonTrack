import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/reward_model.dart';
import '../providers/reward_provider.dart';

class AdminRewardsScreen extends ConsumerStatefulWidget {
  const AdminRewardsScreen({super.key});

  @override
  ConsumerState<AdminRewardsScreen> createState() => _AdminRewardsScreenState();
}

class _AdminRewardsScreenState extends ConsumerState<AdminRewardsScreen> {
  @override
  Widget build(BuildContext context) {
    final rewardsAsync = ref.watch(activeRewardsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Campus Rewards'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(activeRewardsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Reward'),
        onPressed: () => _showCreateRewardModal(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeRewardsProvider);
        },
        child: rewardsAsync.when(
          data: (rewards) {
            if (rewards.isEmpty) {
              return const AppEmptyState(
                icon: Icons.card_giftcard_rounded,
                title: 'No Active Rewards',
                message: 'No campus rewards configured yet. Tap "Add Reward" below to create one.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: rewards.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return _buildRewardCard(reward);
              },
            );
          },
          loading: () => const AppLoadingView(message: 'Loading rewards...'),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(activeRewardsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(Reward reward) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  reward.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                  '${reward.pointsRequired} pts',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reward.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Merchant: ${reward.merchantName}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const Spacer(),
              const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Stock: ${reward.inventory}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateRewardModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => const _CreateRewardBottomSheet(),
    ).then((_) {
      ref.invalidate(activeRewardsProvider);
    });
  }
}

class _CreateRewardBottomSheet extends ConsumerStatefulWidget {
  const _CreateRewardBottomSheet();

  @override
  ConsumerState<_CreateRewardBottomSheet> createState() => _CreateRewardBottomSheetState();
}

class _CreateRewardBottomSheetState extends ConsumerState<_CreateRewardBottomSheet> {
  static const String _defaultMerchantId = '1842ad5b-a6de-47d4-8a3b-90cbb4fed704';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController(text: '50');
  final _inventoryController = TextEditingController(text: '20');
  late final TextEditingController _merchantIdController;

  String _selectedMerchantType = 'CAMPUS_CAFE';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _merchantIdController = TextEditingController(text: _defaultMerchantId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _pointsController.dispose();
    _inventoryController.dispose();
    _merchantIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(rewardRepositoryProvider).createReward(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            pointsRequired: int.parse(_pointsController.text.trim()),
            inventory: int.parse(_inventoryController.text.trim()),
            merchantUserId: _merchantIdController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward created successfully!'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = formatApiError(e, fallback: 'Failed to create reward. Please verify the inputs.');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
              const Text(
                'Add Campus Partner Reward',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Create a redeemable perk for students using Green Points.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.statusErrorBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: AppColors.statusError)),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Reward Title', hintText: 'e.g. 15% Campus Cafe Discount'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Valid on hot beverage items'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Points Required'),
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n < 1) return 'Min 1';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _inventoryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Initial Inventory'),
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n < 0) return 'Min 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              const Text('Partner Merchant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _selectedMerchantType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'CAMPUS_CAFE',
                    child: Text('Campus Cafe (Default Partner)'),
                  ),
                  DropdownMenuItem(
                    value: 'CUSTOM',
                    child: Text('Custom Merchant UUID...'),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedMerchantType = val ?? 'CAMPUS_CAFE';
                    if (_selectedMerchantType == 'CAMPUS_CAFE') {
                      _merchantIdController.text = _defaultMerchantId;
                    } else {
                      _merchantIdController.clear();
                    }
                  });
                },
              ),
              if (_selectedMerchantType == 'CUSTOM') ...[
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _merchantIdController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant User UUID',
                    hintText: 'e.g. 1842ad5b-a6de-47d4-8a3b-90cbb4fed704',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Merchant UUID is required';
                    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
                    if (!uuidRegex.hasMatch(val.trim())) {
                      return 'Please enter a valid 36-character UUID';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Reward', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
