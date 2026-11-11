import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/dio_client.dart';
import 'package:village_app/core/auth/secure_storage.dart';

/// Request marker so a request is only replayed once after a token refresh.
const _retriedKey = 'auth_retried';

/// Timeouts for the refresh called from inside the interceptor. The main
/// client has 10s connect/receive timeouts; without these the refresh POST
/// can hang forever on a stalled connection and park every queued request.
const _refreshConnectTimeout = Duration(seconds: 10);
const _refreshReceiveTimeout = Duration(seconds: 10);

/// How long a request will wait on another request's in-flight refresh
/// before giving up and surfacing a retryable error.
const _refreshWaitTimeout = Duration(seconds: 20);

/// Provider that gives an authenticated Dio instance.
/// The interceptor reads the JWT from secure storage, attaches it,
/// and attempts a token refresh on 401 before triggering logout.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(secureStorageProvider);

  // Attach per Dio instance, not per process. The previous implementation
  // used a module-level bool, so any second container (e.g. a nested
  // ProviderScope) or rebuilt Dio was silently returned without auth and
  // could never recover. Checking the interceptor list is idempotent for the
  // same instance and correct for a new one.
  final alreadyAttached = dio.interceptors.any(
    (interceptor) => interceptor is _AuthRefreshInterceptor,
  );
  if (!alreadyAttached) {
    dio.interceptors.add(_AuthRefreshInterceptor(dio: dio, storage: storage));
  }

  return dio;
});

/// Outcome of one attempt to refresh the session.
enum _RefreshOutcome {
  /// A new access token was obtained and persisted.
  refreshed,

  /// The server explicitly rejected the session (401/403 on refresh) or there
  /// is no session at all. The user must log in again.
  rejected,

  /// The refresh could not be completed for a transient reason (timeout,
  /// socket error, 5xx, 429). The session is still believed valid: keep the
  /// tokens and let the caller retry.
  retryable,
}

class _AuthRefreshInterceptor extends Interceptor {
  _AuthRefreshInterceptor({required this.dio, required this.storage});

  final Dio dio;
  final SecureStorage storage;

  /// Shared across requests on this Dio instance so concurrent 401s trigger a
  /// single refresh instead of a stampede.
  Completer<_RefreshOutcome>? _refreshCompleter;

  static bool _isAuthEndpoint(String path) {
    const authPaths = [
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth/refresh',
      '/api/auth/forgot',
      '/api/auth/reset',
    ];
    return authPaths.any(path.contains);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read('jwt_access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;

    if (status != 401 ||
        options.extra[_retriedKey] == true ||
        _isAuthEndpoint(options.path)) {
      return handler.next(err);
    }

    final outcome = await _refreshSession();

    if (outcome == _RefreshOutcome.refreshed) {
      final token = await storage.read('jwt_access_token');
      if (token == null || token.isEmpty) {
        return handler.next(err);
      }
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer $token';
      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        return handler.next(retryError);
      }
    }

    if (outcome == _RefreshOutcome.rejected) {
      // The server told us the session is dead — only now are the tokens
      // discarded.
      await storage.delete('jwt_access_token');
      await storage.delete('jwt_refresh_token');
      AuthInterceptorLogoutCallback.logout?.call();
    }

    // Retryable: keep the tokens so the user stays logged in and can retry.
    handler.next(err);
  }

  /// Returns the outcome of a refresh, joining an in-flight one if present.
  Future<_RefreshOutcome> _refreshSession() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      // Bounded wait: a wedged refresh must never park callers forever.
      return inFlight.future.timeout(
        _refreshWaitTimeout,
        onTimeout: () => _RefreshOutcome.retryable,
      );
    }

    final completer = Completer<_RefreshOutcome>();
    _refreshCompleter = completer;

    _performRefresh()
        .then((outcome) {
          if (!completer.isCompleted) completer.complete(outcome);
        })
        .catchError((Object _) {
          if (!completer.isCompleted) {
            completer.complete(_RefreshOutcome.retryable);
          }
        })
        .whenComplete(() {
          // Always release the slot, even if the refresh threw outside its own
          // try/catch, so a later request can start a fresh attempt.
          if (identical(_refreshCompleter, completer)) {
            _refreshCompleter = null;
          }
        });

    return completer.future;
  }

  Future<_RefreshOutcome> _performRefresh() async {
    final refreshToken = await storage.read('jwt_refresh_token');
    final accessToken = await storage.read('jwt_access_token');
    if (refreshToken == null || accessToken == null) {
      // Nothing to refresh with — this is not a transient failure.
      return _RefreshOutcome.rejected;
    }

    // Reuse the parent client's HTTP adapter rather than letting Dio build a
    // new one: keeps the connection pool/HTTP2 configuration, and makes the
    // refresh path testable. This instance carries no interceptors, so the
    // refresh request cannot recurse into this interceptor.
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: _refreshConnectTimeout,
        receiveTimeout: _refreshReceiveTimeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )..httpClientAdapter = dio.httpClientAdapter;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await refreshDio.post<dynamic>(
          '/api/auth/refresh',
          data: {'accessToken': accessToken, 'refreshToken': refreshToken},
        );

        final data = response.data;
        if (data is! Map) return _RefreshOutcome.retryable;
        final newAccess = data['accessToken'];
        final newRefresh = data['refreshToken'];
        if (newAccess is! String || newRefresh is! String) {
          return _RefreshOutcome.retryable;
        }

        await storage.write('jwt_access_token', newAccess);
        await storage.write('jwt_refresh_token', newRefresh);
        return _RefreshOutcome.refreshed;
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          return _RefreshOutcome.rejected;
        }
        // 429 from the Auth rate limiter is not an auth failure; honour
        // Retry-After once, then give up as retryable.
        if (status == 429 && attempt == 0) {
          await Future<void>.delayed(_retryAfter(error.response));
          continue;
        }
        return _RefreshOutcome.retryable;
      } catch (_) {
        return _RefreshOutcome.retryable;
      }
    }

    return _RefreshOutcome.retryable;
  }

  static Duration _retryAfter(Response<dynamic>? response) {
    final raw = response?.headers.value('retry-after');
    final seconds = int.tryParse(raw?.trim() ?? '');
    if (seconds == null || seconds <= 0) return const Duration(seconds: 1);
    return Duration(seconds: seconds > 5 ? 5 : seconds);
  }
}

/// Global callback for the 401 interceptor to trigger logout.
/// Set by AuthNotifier during initialization.
class AuthInterceptorLogoutCallback {
  static void Function()? logout;
}
