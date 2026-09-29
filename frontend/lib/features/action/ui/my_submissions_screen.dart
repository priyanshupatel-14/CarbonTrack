import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/action_submission.dart';
import '../provider/action_provider.dart';

class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  static const Color primaryGreen = Color(0xFF059669);
  static const Color cardBg = Colors.white;
  static const Color textColor = Color(0xFF064E3B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(userSubmissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Action Submissions'),
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: primaryGreen),
            onPressed: () => ref.invalidate(userSubmissionsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userSubmissionsProvider);
        },
        child: submissionsAsync.when(
          data: (submissions) {
            if (submissions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No Submissions Yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Perform sustainable campus actions and upload evidence to earn Green Points!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: submissions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sub = submissions[index];
                return _buildSubmissionCard(sub);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load submissions: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(userSubmissionsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(ActionSubmission sub) {
    final statusConfig = _getStatusConfig(sub.status);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusConfig.borderColor, width: 1),
      ),
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    sub.actionTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusConfig.bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusConfig.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusConfig.icon, size: 14, color: statusConfig.textColor),
                      const SizedBox(width: 4),
                      Text(
                        statusConfig.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusConfig.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Submitted: ${_formatDate(sub.submittedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (sub.completedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.done_all, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Evaluated: ${_formatDate(sub.completedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              statusConfig.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toUpperCase()) {
      case 'VERIFIED':
        return _StatusConfig(
          label: 'Verified',
          description: 'Automated verification successful. Green Points credited to your account.',
          icon: Icons.check_circle,
          bgColor: const Color(0xFFECFDF5),
          borderColor: const Color(0xFFA7F3D0),
          textColor: const Color(0xFF059669),
        );
      case 'REVIEW_REQUIRED':
        return _StatusConfig(
          label: 'Under Review',
          description: 'Submitted evidence is pending manual verification by campus administrators.',
          icon: Icons.pending_actions,
          bgColor: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFFCD34D),
          textColor: const Color(0xFFD97706),
        );
      case 'REJECTED':
        return _StatusConfig(
          label: 'Rejected',
          description: 'Evidence could not be verified (e.g., location mismatch, duplicate image, or expired timestamp).',
          icon: Icons.cancel,
          bgColor: const Color(0xFFFEE2E2),
          borderColor: const Color(0xFFFCA5A5),
          textColor: const Color(0xFFDC2626),
        );
      case 'PENDING':
      default:
        return _StatusConfig(
          label: 'Pending Evidence',
          description: 'Submission created. Awaiting evidence upload and finalization.',
          icon: Icons.hourglass_empty,
          bgColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFBFDBFE),
          textColor: const Color(0xFF2563EB),
        );
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'In Progress';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}

class _StatusConfig {
  final String label;
  final String description;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.description,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}
