import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reward_provider.dart';
import '../../points/providers/point_provider.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(activeRewardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards Catalog')),
      body: rewardsAsync.when(
        data: (rewards) {
          if (rewards.isEmpty) {
            return const Center(child: Text('No rewards available at the moment.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
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
                              reward.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Chip(
                            label: Text('${reward.pointsRequired} pts'),
                            backgroundColor: Colors.green.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('By: ${reward.merchantName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(reward.description),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Available: ${reward.inventory}'),
                          ElevatedButton(
                            onPressed: reward.inventory > 0
                                ? () => _redeemReward(context, ref, reward.id, reward.name)
                                : null,
                            child: const Text('Redeem'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _redeemReward(BuildContext context, WidgetRef ref, String rewardId, String rewardName) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(rewardRepositoryProvider).redeemReward(rewardId);
      ref.invalidate(pointBalanceProvider);
      ref.invalidate(pointHistoryProvider);
      ref.invalidate(activeRewardsProvider);
      ref.invalidate(myCouponsProvider);
      
      messenger.showSnackBar(
        SnackBar(content: Text('Successfully redeemed $rewardName!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to redeem: $e')),
      );
    }
  }
}
