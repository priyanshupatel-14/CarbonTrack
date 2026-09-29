import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../../../core/network/dio_client.dart';

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final dioProvider = Provider((ref) => Dio());
final dioClientProvider = Provider(
  (ref) => DioClient(ref.watch(dioProvider), ref.watch(secureStorageProvider)),
);

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    ref.watch(dioClientProvider).dio,
    ref.watch(secureStorageProvider),
  );
});

final authStateProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  () => AuthNotifier(),
);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    try {
      return await ref.read(authRepositoryProvider).getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> register(
    String email,
    String password,
    String first,
    String last,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .register(email, password, first, last);
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}

