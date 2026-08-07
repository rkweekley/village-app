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

  /// DEPRECATED: Refresh is now handled exclusively by the Dio interceptor in AuthenticatedClient.
  /// Kept for backward compatibility during migration.
  Future<bool> tryRefresh() async {
    // The Dio interceptor handles refresh on 401 automatically.
    // Just check if we still have a valid token.
    try {
      await _dio.get('/api/auth/me');
      return true;
    } catch (_) {
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
    required String email,
  }) async {
    await _dio.post('/api/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
      'email': email,
    });
  }

  /// Update the current user's profile fields. Returns the updated UserInfo.
  Future<UserInfo> updateProfile({
    String? displayName,
    String? email,
    String? birthDate,
  }) async {
    final response = await _dio.put('/api/users/me', data: {
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (birthDate != null) 'birthDate': birthDate,
    });
    return UserInfo.fromJson(response.data);
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(_accessTokenKey, accessToken);
    await _storage.write(_refreshTokenKey, refreshToken);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.read(secureStorageProvider);
  final dio = ref.read(authenticatedDioProvider);
  return AuthService(dio, storage);
});
