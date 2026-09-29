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
          Text(
            'Submitted: ${_formatDate(sub.submittedAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Flagged for review due to fraud risk, geofence anomaly, or borderline AI confidence score.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Review Detail'),
                  onPressed: () => _showReviewDetailDialog(sub),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Approve'),
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
      barrierDismissible: false,
      builder: (ctx) => _ReviewDetailDialog(submission: sub),
    ).then((_) {
      ref.invalidate(pendingReviewsProvider);
    });
  }

  Future<void> _handleDecision(String submissionId, bool approve) async {
    final reasonController = TextEditingController(
      text: approve ? 'Verified by campus admin' : 'Failed manual review by campus admin',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve Submission' : 'Reject Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm ${approve ? "approval" : "rejection"} of this submission and credit Green Points accordingly:'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Review Notes / Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppColors.statusSuccess : AppColors.statusError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(actionRepositoryProvider);
        if (approve) {
          await repo.approveSubmission(submissionId, reason: reasonController.text.trim());
        } else {
          await repo.rejectSubmission(submissionId, reason: reasonController.text.trim());
        }
        ref.invalidate(pendingReviewsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approve ? 'Submission approved.' : 'Submission rejected.'),
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

  const _ReviewDetailDialog({required this.submission});

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
    return AlertDialog(
      title: Text('Verification Analysis: ${widget.submission.actionTitle}'),
      content: SizedBox(
        width: 500,
        child: _isLoading
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : _error != null
                ? Text('Error loading detail: $_error', style: const TextStyle(color: AppColors.statusError))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRow('Status', _detail!['status']?.toString() ?? 'N/A'),
                        _buildRow('AI Confidence', '${((_detail!['confidence'] as num? ?? 0) * 100).toStringAsFixed(1)}%'),
                        _buildRow('AI Provider', _detail!['aiProvider']?.toString() ?? 'None'),
                        _buildRow('AI Model', _detail!['aiModel']?.toString() ?? 'None'),
                        _buildRow('Detected Elements', _detail!['aiDetectedElements']?.toString() ?? 'None'),
                        _buildRow('Fraud Risk Level', _detail!['aiFraudRisk']?.toString() ?? 'LOW'),
                        _buildRow('Suspicious Flag', _detail!['aiSuspicious'] == true ? 'YES' : 'NO'),
                        _buildRow('Fraud Indicators', _detail!['aiFraudIndicators']?.toString() ?? 'None'),
                        _buildRow('Geofence Result', _detail!['locationResult']?.toString() ?? 'N/A'),
                        _buildRow('Timestamp Result', _detail!['timestampResult']?.toString() ?? 'N/A'),
                        _buildRow('Duplicate Check', _detail!['duplicateResult']?.toString() ?? 'N/A'),
                        _buildRow('Evaluation Notes', _detail!['reasons']?.toString() ?? 'None'),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
