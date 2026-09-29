import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/carbon_activity.dart';
import '../models/carbon_summary.dart';
import '../repositories/carbon_repository.dart';

final carbonRepositoryProvider = Provider((ref) {
  return CarbonRepository(ref.watch(dioClientProvider).dio);
});

final carbonHistoryProvider = FutureProvider.autoDispose<List<CarbonActivity>>((ref) async {
  return ref.watch(carbonRepositoryProvider).getHistory();
});

final carbonSummaryProvider = FutureProvider.autoDispose<CarbonSummary>((ref) async {
  return ref.watch(carbonRepositoryProvider).getSummary(null, null);
});

