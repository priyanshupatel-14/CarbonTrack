import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/point_provider.dart';

class PointsHistoryScreen extends ConsumerWidget {
  const PointsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(pointBalanceProvider);
    final historyAsync = ref.watch(pointHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Green Points Ledger')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.green.shade50,
            width: double.infinity,
            child: Column(
              children: [
                const Text('Current Balance', style: TextStyle(fontSize: 18, color: Colors.green)),
                const SizedBox(height: 8),
                balanceAsync.when(
                  data: (balance) => Text(
                    balance.toString(),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Center(child: Text('No point transactions found.'));
                }
                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final tx = history[index];
                    final isPositive = tx.points > 0;
                    return ListTile(
                      leading: Icon(
                        isPositive ? Icons.add_circle : Icons.remove_circle,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      title: Text(tx.description),
                      subtitle: Text(tx.createdAt.split('T')[0]), // Simple date
                      trailing: Text(
                        '${isPositive ? '+' : ''}${tx.points}',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
