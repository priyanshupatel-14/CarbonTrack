import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reward_provider.dart';

class MyCouponsScreen extends ConsumerWidget {
  const MyCouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(myCouponsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Coupons')),
      body: couponsAsync.when(
        data: (coupons) {
          if (coupons.isEmpty) {
            return const Center(child: Text('You have no coupons yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon.reward.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Code: ${coupon.code}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text('Status: ${coupon.status}'),
                      if (coupon.expiresAt != null)
                        Text('Expires: ${coupon.expiresAt!.split('T')[0]}'),
                      if (coupon.status == 'REDEEMED' && coupon.redeemedAt != null)
                        Text('Used On: ${coupon.redeemedAt!.split('T')[0]}'),
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
}
