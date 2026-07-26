import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:village_app/core/network/authenticated_client.dart';
import 'package:village_app/core/auth/models.dart';
import 'package:village_app/core/auth/secure_storage.dart';

/// Auth service — makes HTTP calls to the Village API
class AuthService {
  final Dio _dio;
  final SecureStorage _storage;

  AuthService(this._dio, this._storage);

  Future<AuthResponse> register({
    required String email,
    required String displayName,
    required String password,
    String? inviteCode,
  }) async {
    final response = await _dio.post('/api/auth/register', data: {
      'email': email,
      'displayName': displayName,
      'password': password,
      if (inviteCode != null && inviteCode.isNotEmpty) 'inviteCode': inviteCode,
    });
    final data = AuthResponse.fromJson(response.data);
    await _storage.write('jwt_token', data.token);
    return data;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = AuthResponse.fromJson(response.data);
    await _storage.write('jwt_token', data.token);
    return data;
  }

  Future<UserInfo?> getMe() async {
    try {
      final response = await _dio.get('/api/auth/me');
      return UserInfo.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<String?> getToken() async => _storage.read('jwt_token');

  Future<void> logout() async {
    await _storage.delete('jwt_token');
  }

  Future<bool> hasToken() async {
    final token = await _storage.read('jwt_token');
    return token != null && token.isNotEmpty;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.read(secureStorageProvider);
  final dio = ref.watch(authenticatedDioProvider);
  return AuthService(dio, storage);
});
