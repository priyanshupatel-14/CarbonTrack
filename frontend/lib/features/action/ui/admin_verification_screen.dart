import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/action_submission.dart';
import '../provider/action_provider.dart';

class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends ConsumerState<AdminVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Verification Queue'),
        actions: [
          IconButton(
            tooltip: 'Refresh Queue',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(pendingReviewsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingReviewsProvider);
        },
        child: pendingAsync.when(
          data: (submissions) {
            if (submissions.isEmpty) {
              return const AppEmptyState(
                icon: Icons.task_alt_rounded,
                title: 'All Clear!',
                message: 'No submissions currently pending manual verification. All automated decisions have been processed.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: submissions.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final sub = submissions[index];
                return _buildSubmissionCard(sub);
              },
            );
          },
          loading: () => const AppLoadingView(message: 'Loading pending reviews...'),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(pendingReviewsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(ActionSubmission sub) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sub.actionTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              StatusBadge(status: sub.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Submitted: ${_formatDate(sub.submittedAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (sub.id.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '• ID: ${sub.id.length > 8 ? sub.id.substring(0, 8) : sub.id}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.statusWarning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Flagged for manual review due to low AI confidence, geofence mismatch, or potential fraud risk.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Actions
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.analytics_outlined, size: 16, color: AppColors.primary),
            label: const Text('View AI Analysis & Evidence', style: TextStyle(color: AppColors.primary)),
            onPressed: () => _showReviewDetailDialog(sub),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusError,
                    side: const BorderSide(color: AppColors.statusError, width: 1.2),
                    backgroundColor: AppColors.statusErrorBg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _handleDecision(sub.id, false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _handleDecision(sub.id, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showReviewDetailDialog(ActionSubmission sub) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ReviewDetailDialog(
        submission: sub,
        onDecision: (id, approve) {
          _handleDecision(id, approve);
        },
      ),
    ).then((_) {
      ref.invalidate(pendingReviewsProvider);
    });
  }

  Future<void> _handleDecision(String submissionId, bool approve) async {
    final defaultReason = approve
        ? 'Verified by campus admin'
        : 'Failed manual review by campus admin';
    final reasonController = TextEditingController(text: defaultReason);

    final rejectionPresets = [
      'Photo does not show the required action',
      'Duplicate or previously submitted photo',
      'Location is outside verified campus zones',
      'AI flagged high fraud risk or manipulation',
      'Insufficient or blurry visual proof',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: approve ? AppColors.statusSuccessBg : AppColors.statusErrorBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    approve ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: approve ? AppColors.statusSuccess : AppColors.statusError,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  approve ? 'Approve Submission' : 'Reject Submission',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approve
                          ? 'Confirm manual verification? The student will be credited with Green Points and their challenge progress will update immediately.'
                          : 'Are you sure you want to reject this submission? Green Points will NOT be credited to the student. Please provide feedback below:',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    if (!approve) ...[
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Select Common Reason:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: rejectionPresets.map((preset) {
                          final isSelected = reasonController.text == preset;
                          return ChoiceChip(
                            label: Text(
                              preset,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.statusError,
                            backgroundColor: AppColors.surface,
                            onSelected: (_) {
                              setDialogState(() {
                                reasonController.text = preset;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: reasonController,
                      maxLines: approve ? 2 : 3,
                      decoration: InputDecoration(
                        labelText: approve ? 'Admin Approval Notes (Optional)' : 'Rejection Reason (Visible to Student)',
                        hintText: approve ? 'e.g. Verified by campus admin' : 'Explain why this submission was rejected',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: approve ? AppColors.statusSuccess : AppColors.statusError,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: Icon(approve ? Icons.check_rounded : Icons.cancel_outlined, size: 16),
                label: Text(
                  approve ? 'Confirm Approval' : 'Reject Submission',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim().isEmpty ? defaultReason : reasonController.text.trim();
      try {
        final repo = ref.read(actionRepositoryProvider);
        if (approve) {
          await repo.approveSubmission(submissionId, reason: reason);
        } else {
          await repo.rejectSubmission(submissionId, reason: reason);
        }
        ref.invalidate(pendingReviewsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approve ? 'Submission approved successfully.' : 'Submission rejected.'),
              backgroundColor: approve ? AppColors.statusSuccess : AppColors.statusError,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $e'), backgroundColor: AppColors.statusError),
          );
        }
      }
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'In Progress';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _ReviewDetailDialog extends ConsumerStatefulWidget {
  final ActionSubmission submission;
  final void Function(String submissionId, bool approve) onDecision;

  const _ReviewDetailDialog({
    required this.submission,
    required this.onDecision,
  });

  @override
  ConsumerState<_ReviewDetailDialog> createState() => _ReviewDetailDialogState();
}

class _ReviewDetailDialogState extends ConsumerState<_ReviewDetailDialog> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await ref.read(actionRepositoryProvider).getVerificationDetail(widget.submission.id);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuspicious = _detail?['aiSuspicious'] == true || _detail?['aiFraudRisk'] == 'HIGH';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Analysis: ${widget.submission.actionTitle}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: _isLoading
            ? const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()))
            : _error != null
                ? Text('Error loading detail: $_error', style: const TextStyle(color: AppColors.statusError))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSuspicious)
                          Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.statusErrorBg,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.statusError.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppColors.statusError, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'High Fraud Risk Detected: AI or system checks flagged anomalies with this submission.',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.statusError),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildSectionHeader('AI Vision Evaluation'),
                        _buildRow('Status', _detail!['status']?.toString() ?? 'N/A'),
                        _buildRow('AI Confidence', '${((_detail!['confidence'] as num? ?? 0) * 100).toStringAsFixed(1)}%'),
                        _buildRow('AI Provider', _detail!['aiProvider']?.toString() ?? 'None'),
                        _buildRow('AI Model', _detail!['aiModel']?.toString() ?? 'None'),
                        _buildRow('Detected Elements', _detail!['aiDetectedElements']?.toString() ?? 'None'),
                        _buildRow('Fraud Risk Level', _detail!['aiFraudRisk']?.toString() ?? 'LOW',
                            highlightError: _detail!['aiFraudRisk'] == 'HIGH'),
                        _buildRow('Suspicious Flag', _detail!['aiSuspicious'] == true ? 'YES' : 'NO',
                            highlightError: _detail!['aiSuspicious'] == true),
                        _buildRow('Fraud Indicators', _detail!['aiFraudIndicators']?.toString() ?? 'None'),
                        const Divider(height: 24),
                        _buildSectionHeader('System & Geofence Checks'),
                        _buildRow('Geofence Result', _detail!['locationResult']?.toString() ?? 'N/A'),
                        _buildRow('Timestamp Result', _detail!['timestampResult']?.toString() ?? 'N/A'),
                        _buildRow('Duplicate Check', _detail!['duplicateResult']?.toString() ?? 'N/A'),
                        _buildRow('Evaluation Notes', _detail!['reasons']?.toString() ?? 'None'),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.statusError,
            side: const BorderSide(color: AppColors.statusError),
          ),
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.pop(context);
            widget.onDecision(widget.submission.id, false);
          },
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.pop(context);
            widget.onDecision(widget.submission.id, true);
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool highlightError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: highlightError ? AppColors.statusError : AppColors.textPrimary,
                fontWeight: highlightError ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
