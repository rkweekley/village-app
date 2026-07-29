import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: '',  // relative to page origin — nginx proxies /api/ to the API
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) {
        if (o is RequestOptions && o.data is Map) {
          final data = Map<String, dynamic>.from(o.data as Map);
          if (data.containsKey('password')) data['password'] = '[REDACTED]';
          debugPrint('[Village API] ${o.method} ${o.path} — body: $data');
        } else {
          debugPrint('[Village API] $o');
        }
      },
    ));
  }

  return dio;
});
