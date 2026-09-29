import 'package:dio/dio.dart';
import '../models/leaderboard_model.dart';

class LeaderboardRepository {
  final Dio _dio;

  LeaderboardRepository(this._dio);

  Future<LeaderboardData> getLeaderboard({int page = 0, int size = 20}) async {
    final response = await _dio.get(
      '/leaderboard',
      queryParameters: {'page': page, 'size': size},
    );
    return LeaderboardData.fromJson(response.data as Map<String, dynamic>);
  }
}
