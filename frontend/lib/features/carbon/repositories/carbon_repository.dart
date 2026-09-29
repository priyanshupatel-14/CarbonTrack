import 'package:dio/dio.dart';
import '../models/carbon_activity.dart';
import '../models/carbon_summary.dart';

class CarbonRepository {
  final Dio _dio;

  CarbonRepository(this._dio);

  Future<CarbonActivity> recordActivity(
    String category,
    String type,
    double quantity,
    String unit,
    String date,
  ) async {
    try {
      final response = await _dio.post(
        '/carbon/activities',
        data: {
          'category': category,
          'activityType': type,
          'quantity': quantity,
          'unit': unit,
          'activityDate': date,
        },
      );
      return CarbonActivity.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception("Invalid request: ${e.response?.data}");
      }
      throw Exception(e.message);
    }
  }

  Future<List<CarbonActivity>> getHistory() async {
    try {
      final response = await _dio.get('/carbon/history');
      final list = response.data as List;
      return list.map((e) => CarbonActivity.fromJson(e)).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<CarbonSummary> getSummary(String? startDate, String? endDate) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get(
        '/carbon/summary',
        queryParameters: queryParams,
      );
      return CarbonSummary.fromJson(response.data);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
