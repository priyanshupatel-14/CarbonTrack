import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge_model.dart';
import '../models/challenge_participation_model.dart';
import '../repositories/challenge_repository.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChallengeRepository(dioClient.dio);
});

final activeChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getChallenges();
});

final myChallengesProvider = FutureProvider.autoDispose<List<ChallengeParticipation>>((ref) {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getMyChallenges();
});

final challengeDetailsProvider = FutureProvider.autoDispose.family<Challenge, String>((ref, id) {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getChallengeDetails(id);
});

final adminChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) {
  final repository = ref.watch(challengeRepositoryProvider);
  return repository.getAdminChallenges();
});
