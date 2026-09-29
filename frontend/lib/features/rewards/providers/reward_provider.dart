import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/reward_repository.dart';
import '../models/reward_model.dart';
import '../models/coupon_model.dart';
import '../../auth/providers/auth_provider.dart';

final rewardRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RewardRepository(dioClient.dio);
});

final activeRewardsProvider = FutureProvider.autoDispose<List<Reward>>((ref) {
  final repository = ref.watch(rewardRepositoryProvider);
  return repository.getActiveRewards();
});

final myCouponsProvider = FutureProvider.autoDispose<List<Coupon>>((ref) {
  final repository = ref.watch(rewardRepositoryProvider);
  return repository.getMyCoupons();
});
