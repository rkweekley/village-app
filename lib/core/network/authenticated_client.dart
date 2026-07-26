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
        // Clear expired token and trigger re-auth
        storage.delete('jwt_token');
      }
      handler.next(error);
    },
  ));

  return dio;
});
