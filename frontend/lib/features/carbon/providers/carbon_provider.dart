import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/carbon_activity.dart';
import '../models/carbon_summary.dart';
import '../repositories/carbon_repository.dart';

final carbonRepositoryProvider = Provider((ref) {
  return CarbonRepository(ref.watch(dioClientProvider).dio);
});

final carbonHistoryProvider = FutureProvider<List<CarbonActivity>>((ref) async {
  return ref.watch(carbonRepositoryProvider).getHistory();
});

final carbonSummaryProvider =
    FutureProvider.family<CarbonSummary, Map<String, String?>>((
      ref,
      params,
    ) async {
      return ref
          .watch(carbonRepositoryProvider)
          .getSummary(params['startDate'], params['endDate']);
    });
