import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await _storage.write(key: 'jwt_token', value: authResponse.token);
      return authResponse.user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception("Invalid credentials");
      }
      throw Exception(e.message);
    }
  }

  Future<User> register(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        },
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await _storage.write(key: 'jwt_token', value: authResponse.token);
      return authResponse.user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception("Registration failed (duplicate email or validation)");
      }
      throw Exception(e.message);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<User?> getCurrentUser() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    try {
      final response = await _dio.get('/users/me');
      return User.fromJson(response.data);
    } catch (e) {
      await logout();
      return null;
    }
  }
}
