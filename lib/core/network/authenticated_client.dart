import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/dio_client.dart';
import 'package:village_app/core/auth/secure_storage.dart';

/// Provider that gives an authenticated Dio instance.
/// The interceptor reads the JWT from secure storage, attaches it,
/// and attempts a token refresh on 401 before triggering logout.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);

  bool _isRefreshing = false;

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read('jwt_access_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401 && !_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await storage.read('jwt_refresh_token');
          final accessToken = await storage.read('jwt_access_token');
          if (refreshToken != null && accessToken != null) {
            // Attempt refresh with a fresh Dio (no auth header)
            final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
            final refreshResponse = await refreshDio.post(
              '/api/auth/refresh',
              data: {
                'accessToken': accessToken,
                'refreshToken': refreshToken,
              },
            );
            final newAccess = refreshResponse.data['accessToken'] as String;
            final newRefresh = refreshResponse.data['refreshToken'] as String;
            await storage.write('jwt_access_token', newAccess);
            await storage.write('jwt_refresh_token', newRefresh);

            // Retry the original request with new token
            error.requestOptions.headers['Authorization'] =
                'Bearer $newAccess';
            final retryResponse = await dio.fetch(error.requestOptions);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh failed — clear tokens and trigger logout
        }
        _isRefreshing = false;
      }

      if (error.response?.statusCode == 401) {
        await storage.delete('jwt_access_token');
        await storage.delete('jwt_refresh_token');
        AuthInterceptorLogoutCallback.logout?.call();
      }
      handler.next(error);
    },
  ));

  return dio;
});

/// Global callback for the 401 interceptor to trigger logout.
/// Set by AuthNotifier during initialization.
class AuthInterceptorLogoutCallback {
  static void Function()? logout;
}
