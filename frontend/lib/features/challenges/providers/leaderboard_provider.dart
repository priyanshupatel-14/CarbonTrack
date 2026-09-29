import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/leaderboard_model.dart';
import '../repositories/leaderboard_repository.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return LeaderboardRepository(dioClient.dio);
});

final leaderboardProvider = FutureProvider.autoDispose.family<LeaderboardData, int>((ref, page) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getLeaderboard(page: page);
});
