import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import 'admin_challenges_screen.dart';
import 'challenge_card.dart';
import 'challenge_detail_screen.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color primaryGreen = Color(0xFF059669);
  static const Color accentGreen = Color(0xFFECFDF5);
  static const Color borderColor = Color(0xFFA7F3D0);
  static const Color textColor = Color(0xFF064E3B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Challenges'),
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Manage Challenges',
              icon: const Icon(Icons.admin_panel_settings_outlined, color: primaryGreen),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminChallengesScreen()),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryGreen,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: primaryGreen,
          indicatorWeight: 3,
          tabs: [
            const Tab(text: 'Available'),
            Tab(text: isAdmin ? 'Admin Panel' : 'My Challenges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableTab(),
          isAdmin ? const AdminChallengesScreen() : _buildMyChallengesTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableTab() {
    final challengesAsync = ref.watch(activeChallengesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeChallengesProvider);
        ref.invalidate(myChallengesProvider);
      },
      child: challengesAsync.when(
        data: (challenges) {
          if (challenges.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No Active Challenges',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check back soon for new campus sustainability challenges!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              return ChallengeCard(
                challenge: challenges[index],
                onJoinSuccess: () {
                  ref.invalidate(activeChallengesProvider);
                  ref.invalidate(myChallengesProvider);
                },
              );
            },
          );
        },
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
                Text('Error loading challenges: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(activeChallengesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyChallengesTab() {
    final myChallengesAsync = ref.watch(myChallengesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myChallengesProvider);
      },
      child: myChallengesAsync.when(
        data: (participations) {
          if (participations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No Joined Challenges Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join available challenges to earn bonus Green Points!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _tabController.animateTo(0),
                      child: const Text('Browse Challenges'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: participations.length,
            itemBuilder: (context, index) {
              final p = participations[index];
              final isCompleted = p.isCompleted;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isCompleted ? primaryGreen : borderColor,
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChallengeDetailScreen(challengeId: p.challengeId),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p.challengeTitle,
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
                                color: isCompleted ? accentGreen : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isCompleted ? borderColor : Colors.blue.shade200,
                                ),
                              ),
                              child: Text(
                                isCompleted ? '✓ Completed' : 'In Progress',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? primaryGreen : Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Action: ${p.targetActionTitle}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress: ${p.progressCount} / ${p.targetCount}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isCompleted ? primaryGreen : textColor,
                              ),
                            ),
                            Text(
                              '${(p.progressRatio * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? primaryGreen : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: p.progressRatio,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? primaryGreen : const Color(0xFF10B981),
                            ),
                            minHeight: 8,
                          ),
                        ),
                        if (p.bonusPoints > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                isCompleted
                                    ? 'Earned +${p.bonusPoints} bonus points'
                                    : '+${p.bonusPoints} bonus points upon completion',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error loading participations: $e'),
          ),
        ),
      ),
    );
  }
}
