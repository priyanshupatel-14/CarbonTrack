import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/sustainable_action.dart';
import '../models/action_submission.dart';
import '../repository/action_repository.dart';

final actionRepositoryProvider = Provider<ActionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ActionRepository(dio);
});

final availableActionsProvider = FutureProvider<List<SustainableAction>>((ref) async {
  final repository = ref.watch(actionRepositoryProvider);
  return repository.getActions();
});

final userSubmissionsProvider = FutureProvider<List<ActionSubmission>>((ref) async {
  final repository = ref.watch(actionRepositoryProvider);
  return repository.getSubmissions();
});
