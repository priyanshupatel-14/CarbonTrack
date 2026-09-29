import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge_model.dart';
import '../providers/challenge_provider.dart';
import '../../points/providers/point_provider.dart';
import 'admin_challenges_screen.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  ConsumerState<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen> {
  bool _isJoining = false;

  static const Color primaryGreen = Color(0xFF059669);
  static const Color accentGreen = Color(0xFFECFDF5);
  static const Color borderColor = Color(0xFFA7F3D0);
  static const Color textColor = Color(0xFF064E3B);

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeDetailsProvider(widget.challengeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Details'),
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: challengeAsync.when(
        data: (challenge) => _buildContent(context, challenge),
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(challengeDetailsProvider(widget.challengeId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Challenge challenge) {
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.role == 'ADMIN';
    final isCompleted = challenge.isCompleted;
    final isJoined = challenge.isJoined;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        challenge.status,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                    if (challenge.bonusPoints > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            '+${challenge.bonusPoints} Green Points',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Progress Section if joined
          if (isJoined) ...[
            const Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${challenge.currentProgress} of ${challenge.targetCount} actions completed',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        '${(challenge.progressRatio * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: challenge.progressRatio,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
                      minHeight: 10,
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: primaryGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Completed! Bonus points awarded.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Details Grid
          const Text(
            'Challenge Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.eco,
                  'Target Action',
                  challenge.targetActionTitle,
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  Icons.flag,
                  'Required Actions',
                  '${challenge.targetCount} verified submissions',
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  Icons.people,
                  'Participants',
                  '${challenge.participantCount} students joined',
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  Icons.date_range,
                  'Time Remaining',
                  '${challenge.daysRemaining} days remaining',
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Action Button
          if (isAdmin)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: const BorderSide(color: primaryGreen, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text(
                  'Manage in Admin Panel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminChallengesScreen()),
                  );
                },
              ),
            )
          else if (!isJoined)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isJoining ? null : () => _joinChallenge(context, challenge),
                child: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Join Challenge Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            )
          else if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: accentGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    'Challenge Completed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'In Progress: Log "${challenge.targetActionTitle}" to advance',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _joinChallenge(BuildContext context, Challenge challenge) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isJoining = true);
    try {
      await ref.read(challengeRepositoryProvider).joinChallenge(challenge.id);
      ref.invalidate(challengeDetailsProvider(challenge.id));
      ref.invalidate(activeChallengesProvider);
      ref.invalidate(myChallengesProvider);
      ref.invalidate(pointBalanceProvider);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Successfully joined "${challenge.title}"!'),
          backgroundColor: primaryGreen,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to join: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }
}
