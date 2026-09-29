import 'package:dio/dio.dart';
import '../models/challenge_model.dart';
import '../models/challenge_participation_model.dart';

class ChallengeRepository {
  final Dio _dio;

  ChallengeRepository(this._dio);

  Future<List<Challenge>> getChallenges() async {
    final response = await _dio.get('/challenges');
    final data = response.data as List<dynamic>;
    return data.map((e) => Challenge.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Challenge> getChallengeDetails(String id) async {
    final response = await _dio.get('/challenges/$id');
    return Challenge.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ChallengeParticipation>> getMyChallenges() async {
    final response = await _dio.get('/challenges/my');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ChallengeParticipation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChallengeParticipation> joinChallenge(String id) async {
    final response = await _dio.post('/challenges/$id/join');
    return ChallengeParticipation.fromJson(response.data as Map<String, dynamic>);
  }

  // Admin endpoints
  Future<List<Challenge>> getAdminChallenges() async {
    final response = await _dio.get('/admin/challenges');
    final data = response.data as List<dynamic>;
    return data.map((e) => Challenge.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Challenge> createChallenge(Map<String, dynamic> data) async {
    final response = await _dio.post('/admin/challenges', data: data);
    return Challenge.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Challenge> updateChallenge(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/admin/challenges/$id', data: data);
    return Challenge.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Challenge> updateChallengeStatus(String id, String status) async {
    final response = await _dio.patch(
      '/admin/challenges/$id/status',
      data: {'status': status},
    );
    return Challenge.fromJson(response.data as Map<String, dynamic>);
  }
}
