import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:village_app/core/network/authenticated_client.dart';
import 'package:village_app/core/auth/models.dart';
import 'package:village_app/core/auth/secure_storage.dart';

/// Auth service — makes HTTP calls to the Village API
class AuthService {
  final Dio _dio;
  final SecureStorage _storage;

  static const _accessTokenKey = 'jwt_access_token';
  static const _refreshTokenKey = 'jwt_refresh_token';

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
      if (inviteCode != null && inviteCode.isNotEmpty)
        'inviteCode': inviteCode,
    });
    final data = AuthResponse.fromJson(response.data);
    await _saveTokens(data.accessToken, data.refreshToken);
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
    await _saveTokens(data.accessToken, data.refreshToken);
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

  /// Try to refresh the access token using the stored refresh token.
  /// Returns true if successful, false if refresh failed.
  Future<bool> tryRefresh() async {
    final accessToken = await _storage.read(_accessTokenKey);
    final refreshToken = await _storage.read(_refreshTokenKey);
    if (accessToken == null || refreshToken == null) return false;

    try {
      final response = await _dio.post('/api/auth/refresh', data: {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      });
      final newAccess = response.data['accessToken'] as String;
      final newRefresh = response.data['refreshToken'] as String;
      await _saveTokens(newAccess, newRefresh);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<String?> getAccessToken() async => _storage.read(_accessTokenKey);

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {
      // Server may be unreachable — clear local tokens regardless
    }
    await _storage.delete(_accessTokenKey);
    await _storage.delete(_refreshTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(_accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post('/api/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post('/api/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(_accessTokenKey, accessToken);
    await _storage.write(_refreshTokenKey, refreshToken);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.read(secureStorageProvider);
  final dio = ref.watch(authenticatedDioProvider);
  return AuthService(dio, storage);
});
