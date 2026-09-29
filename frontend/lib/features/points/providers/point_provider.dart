import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/point_repository.dart';
import '../models/point_transaction_model.dart';
import '../../auth/providers/auth_provider.dart';

final pointRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return PointRepository(dioClient.dio);
});

final pointBalanceProvider = FutureProvider.autoDispose<int>((ref) {
  final repository = ref.watch(pointRepositoryProvider);
  return repository.getBalance();
});

final pointHistoryProvider = FutureProvider.autoDispose<List<PointTransaction>>((ref) {
  final repository = ref.watch(pointRepositoryProvider);
  return repository.getHistory();
});
