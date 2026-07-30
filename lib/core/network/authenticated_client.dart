import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/dio_client.dart';
import 'package:village_app/core/auth/secure_storage.dart';

/// Provider that gives an authenticated Dio instance.
/// The interceptor reads the JWT from secure storage and attaches it.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read('jwt_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        // Token expired — clear it so auto-login doesn't reuse it
        storage.delete('jwt_token');
        // Trigger auth state change via a global callback
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
