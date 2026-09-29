import 'package:dio/dio.dart';
import '../models/sustainable_action.dart';
import '../models/action_submission.dart';

class ActionRepository {
  final Dio _dio;

  ActionRepository(this._dio);

  Future<List<SustainableAction>> getActions() async {
    final response = await _dio.get('/api/v1/actions');
    return (response.data as List)
        .map((json) => SustainableAction.fromJson(json))
        .toList();
  }

  Future<List<ActionSubmission>> getSubmissions() async {
    final response = await _dio.get('/api/v1/actions/submissions');
    return (response.data as List)
        .map((json) => ActionSubmission.fromJson(json))
        .toList();
  }

  Future<ActionSubmission> createSubmission(String actionId) async {
    final response = await _dio.post(
      '/api/v1/actions/submissions',
      data: {
        'sustainableActionId': actionId,
        'clientTimestamp': DateTime.now().toIso8601String(),
      },
    );
    return ActionSubmission.fromJson(response.data);
  }

  Future<void> addEvidence({
    required String submissionId,
    String? filePath,
    double? latitude,
    double? longitude,
  }) async {
    var formData = FormData.fromMap({
      'clientTimestamp': DateTime.now().toIso8601String(),
    });
    
    if (latitude != null) formData.fields.add(MapEntry('latitude', latitude.toString()));
    if (longitude != null) formData.fields.add(MapEntry('longitude', longitude.toString()));
    if (filePath != null) {
      formData.files.add(MapEntry('file', await MultipartFile.fromFile(filePath)));
    }

    await _dio.post(
      '/api/v1/actions/submissions/$submissionId/evidence',
      data: formData,
    );
  }

  Future<ActionSubmission> finalizeSubmission(String submissionId) async {
    final response = await _dio.post('/api/v1/actions/submissions/$submissionId/finalize');
    return ActionSubmission.fromJson(response.data);
  }
}
