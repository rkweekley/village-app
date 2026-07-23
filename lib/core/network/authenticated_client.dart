import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/dio_client.dart';

/// Provider that gives us an authenticated Dio instance.
/// The interceptor reads the token from secure storage and attaches it.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = ref.watch(dioProvider);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // TODO: load JWT from flutter_secure_storage
      // final storage = ref.read(secureStorageProvider);
      // final token = await storage.read(key: 'jwt_token');
      // if (token != null) {
      //   options.headers['Authorization'] = 'Bearer $token';
      // }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        print('[Village Auth] Token expired — redirecting to login');
      }
      handler.next(error);
    },
  ));

  return dio;
});

/// Placeholder for secure storage provider — will be expanded in auth sprint.
// final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
//   return const FlutterSecureStorage();
// });
