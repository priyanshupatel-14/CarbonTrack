import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  final Dio dio;
  final FlutterSecureStorage storage;

  DioClient(this.dio, this.storage) {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      dio.options.baseUrl = envUrl;
    } else if (!kIsWeb && Platform.isAndroid) {
      dio.options.baseUrl = 'http://10.0.2.2:8080/api/v1';
    } else {
      dio.options.baseUrl = 'http://localhost:8080/api/v1';
    }
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }
}
