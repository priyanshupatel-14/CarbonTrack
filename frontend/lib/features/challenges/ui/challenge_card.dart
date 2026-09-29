import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../points/providers/point_provider.dart';
import '../models/challenge_model.dart';
import '../providers/challenge_provider.dart';
import 'admin_challenges_screen.dart';
import 'challenge_detail_screen.dart';

class ChallengeCard extends ConsumerStatefulWidget {
  final Challenge challenge;
  final VoidCallback? onJoinSuccess;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onJoinSuccess,
  });

  @override
  ConsumerState<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends ConsumerState<ChallengeCard> {
  bool _isJoining = false;

  static const Color primaryGreen = Color(0xFF059669);
  static const Color cardBg = Colors.white;
  static const Color accentGreen = Color(0xFFECFDF5);
  static const Color borderColor = Color(0xFFA7F3D0);
  static const Color textColor = Color(0xFF064E3B);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.role == 'ADMIN';
    final c = widget.challenge;
    final isJoined = c.isJoined;
    final isCompleted = c.isCompleted;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCompleted ? primaryGreen : (isJoined ? borderColor : Colors.grey.shade200),
          width: isCompleted || isJoined ? 1.5 : 1.0,
        ),
      ),
      color: cardBg,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChallengeDetailScreen(challengeId: c.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title + Bonus Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (c.bonusPoints > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentGreen,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            '+${c.bonusPoints} pts',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Description
              Text(
                c.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              // Action requirement tag
              Row(
                children: [
                  Icon(Icons.eco_outlined, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Action: ${c.targetActionTitle}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar if joined
              if (isJoined) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${c.currentProgress} / ${c.targetCount} completed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? primaryGreen : textColor,
                      ),
                    ),
                    Text(
                      '${(c.progressRatio * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: c.progressRatio,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? primaryGreen : const Color(0xFF10B981),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Bottom row: Info & Action button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Ends in ${c.daysRemaining} days',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentGreen,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: primaryGreen),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isJoined)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryGreen,
                        side: const BorderSide(color: primaryGreen),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChallengeDetailScreen(challengeId: c.id),
                          ),
                        );
                      },
                      child: const Text('View Progress', style: TextStyle(fontSize: 12)),
                    )
                  else if (isAdmin)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryGreen,
                        side: const BorderSide(color: primaryGreen),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 14),
                      label: const Text('Manage', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminChallengesScreen(),
                          ),
                        );
                      },
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isJoining ? null : () => _joinChallenge(context),
                      child: _isJoining
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Join Challenge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _joinChallenge(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isJoining = true);
    try {
      await ref.read(challengeRepositoryProvider).joinChallenge(widget.challenge.id);
      ref.invalidate(activeChallengesProvider);
      ref.invalidate(myChallengesProvider);
      ref.invalidate(pointBalanceProvider);

      messenger.showSnackBar(
        SnackBar(
          content: Text('Joined "${widget.challenge.title}"!'),
          backgroundColor: primaryGreen,
        ),
      );
      widget.onJoinSuccess?.call();
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
