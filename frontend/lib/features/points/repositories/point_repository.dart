import 'package:dio/dio.dart';
import '../models/point_transaction_model.dart';

class PointRepository {
  final Dio _dio;

  PointRepository(this._dio);

  Future<int> getBalance() async {
    final response = await _dio.get('/points/balance');
    return response.data['balance'] as int;
  }

  Future<List<PointTransaction>> getHistory() async {
    final response = await _dio.get('/points/history');
    final data = response.data as List;
    return data.map((e) => PointTransaction.fromJson(e)).toList();
  }
}
