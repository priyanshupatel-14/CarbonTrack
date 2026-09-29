import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/sustainable_action.dart';
import '../models/action_submission.dart';

class ActionRepository {
  final Dio _dio;

  ActionRepository(this._dio);

  Future<List<SustainableAction>> getActions() async {
    final response = await _dio.get('/actions');
    return (response.data as List)
        .map((json) => SustainableAction.fromJson(json))
        .toList();
  }

  Future<List<ActionSubmission>> getSubmissions() async {
    final response = await _dio.get('/actions/submissions');
    return (response.data as List)
        .map((json) => ActionSubmission.fromJson(json))
        .toList();
  }

  Future<ActionSubmission> createSubmission(String actionId) async {
    final response = await _dio.post(
      '/actions/submissions',
      data: {
        'sustainableActionId': actionId,
      },
    );
    return ActionSubmission.fromJson(response.data);
  }

  Future<void> addEvidence({
    required String submissionId,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    double? latitude,
    double? longitude,
  }) async {
    var formData = FormData.fromMap({
      'clientTimestamp': DateTime.now().toIso8601String(),
    });
    
    if (latitude != null) formData.fields.add(MapEntry('latitude', latitude.toString()));
    if (longitude != null) formData.fields.add(MapEntry('longitude', longitude.toString()));
    if (fileBytes != null) {
      formData.files.add(MapEntry(
        'file',
        MultipartFile.fromBytes(fileBytes, filename: fileName ?? 'evidence.jpg'),
      ));
    } else if (filePath != null && filePath.isNotEmpty) {
      formData.files.add(MapEntry('file', await MultipartFile.fromFile(filePath)));
    }

    await _dio.post(
      '/actions/submissions/$submissionId/evidence',
      data: formData,
    );
  }

  Future<ActionSubmission> finalizeSubmission(String submissionId) async {
    final response = await _dio.post('/actions/submissions/$submissionId/finalize');
    return ActionSubmission.fromJson(response.data);
  }

  // Admin Methods
  Future<List<ActionSubmission>> getPendingReviews() async {
    final response = await _dio.get('/admin/submissions/review');
    return (response.data as List)
        .map((json) => ActionSubmission.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> getVerificationDetail(String submissionId) async {
    final response = await _dio.get('/admin/submissions/$submissionId/verification');
    return response.data as Map<String, dynamic>;
  }

  Future<void> approveSubmission(String submissionId, {String reason = 'Approved by admin'}) async {
    await _dio.post(
      '/admin/submissions/$submissionId/approve',
      queryParameters: {'reason': reason},
    );
  }

  Future<void> rejectSubmission(String submissionId, {String reason = 'Rejected by admin'}) async {
    await _dio.post(
      '/admin/submissions/$submissionId/reject',
      queryParameters: {'reason': reason},
    );
  }
}

