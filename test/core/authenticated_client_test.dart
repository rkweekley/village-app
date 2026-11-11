import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:village_app/core/auth/secure_storage.dart';
import 'package:village_app/core/network/authenticated_client.dart';
import 'package:village_app/core/network/dio_client.dart';

/// In-memory stand-in for the keychain/localStorage-backed store.
class _FakeStorage extends SecureStorage {
  _FakeStorage() : super(null, null);

  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// Adapter that routes requests to a test callback instead of the network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, int status) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

Dio _dioWith(_FakeAdapter adapter) => Dio(
  BaseOptions(
    baseUrl: 'https://test.local',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ),
)..httpClientAdapter = adapter;

/// Counts auth interceptors by type name: dio itself always ships one default
/// interceptor (ImplyContentTypeInterceptor), so counting all of them is wrong.
int _authInterceptorCount(Dio dio) => dio.interceptors
    .where((i) => i.runtimeType.toString() == '_AuthRefreshInterceptor')
    .length;

void main() {
  late _FakeStorage storage;
  late int logoutCalls;

  setUp(() {
    storage = _FakeStorage();
    logoutCalls = 0;
    AuthInterceptorLogoutCallback.logout = () => logoutCalls++;
  });

  tearDown(() {
    AuthInterceptorLogoutCallback.logout = null;
  });

  ProviderContainer containerFor(Dio dio) => ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(dio),
      secureStorageProvider.overrideWithValue(storage),
    ],
  );

  test('a transient refresh failure keeps the session (no logout)', () async {
    storage.data['jwt_access_token'] = 'expired';
    storage.data['jwt_refresh_token'] = 'refresh';

    final adapter = _FakeAdapter((options) async {
      if (options.path.contains('/api/auth/refresh')) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'socket closed',
        );
      }
      return _json('', 401);
    });
    final container = containerFor(_dioWith(adapter));
    addTearDown(container.dispose);

    final dio = container.read(authenticatedDioProvider);

    await expectLater(
      dio.get<dynamic>('/api/chores'),
      throwsA(isA<DioException>()),
    );

    expect(logoutCalls, 0, reason: 'a network failure is not a dead session');
    expect(storage.data['jwt_access_token'], 'expired');
    expect(storage.data['jwt_refresh_token'], 'refresh');
  });

  test('an explicit 401 from refresh logs out and clears tokens', () async {
    storage.data['jwt_access_token'] = 'expired';
    storage.data['jwt_refresh_token'] = 'revoked';

    final adapter = _FakeAdapter((options) async {
      if (options.path.contains('/api/auth/refresh')) {
        return _json('{"error":"invalid refresh token"}', 401);
      }
      return _json('', 401);
    });
    final container = containerFor(_dioWith(adapter));
    addTearDown(container.dispose);

    final dio = container.read(authenticatedDioProvider);

    await expectLater(
      dio.get<dynamic>('/api/chores'),
      throwsA(isA<DioException>()),
    );

    expect(logoutCalls, 1, reason: 'a rejected refresh must end the session');
    expect(storage.data.containsKey('jwt_access_token'), isFalse);
    expect(storage.data.containsKey('jwt_refresh_token'), isFalse);
  });

  test(
    'a successful refresh replays the original request with the new token',
    () async {
      storage.data['jwt_access_token'] = 'expired';
      storage.data['jwt_refresh_token'] = 'refresh';

      final seenAuthHeaders = <String>[];
      final adapter = _FakeAdapter((options) async {
        if (options.path.contains('/api/auth/refresh')) {
          return _json(
            '{"accessToken":"fresh","refreshToken":"fresh-refresh"}',
            200,
          );
        }
        final auth = options.headers['Authorization']?.toString() ?? 'none';
        seenAuthHeaders.add(auth);
        if (auth == 'Bearer fresh') {
          return _json('{"ok":true}', 200);
        }
        return _json('', 401);
      });
      final container = containerFor(_dioWith(adapter));
      addTearDown(container.dispose);

      final dio = container.read(authenticatedDioProvider);

      final response = await dio.get<dynamic>('/api/chores');

      expect(response.statusCode, 200);
      expect(seenAuthHeaders, ['Bearer expired', 'Bearer fresh']);
      expect(storage.data['jwt_access_token'], 'fresh');
      expect(logoutCalls, 0);
    },
  );

  test('concurrent 401s trigger a single refresh', () async {
    storage.data['jwt_access_token'] = 'expired';
    storage.data['jwt_refresh_token'] = 'refresh';

    var refreshCalls = 0;
    final adapter = _FakeAdapter((options) async {
      if (options.path.contains('/api/auth/refresh')) {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _json(
          '{"accessToken":"fresh","refreshToken":"fresh-refresh"}',
          200,
        );
      }
      if (options.headers['Authorization'] == 'Bearer fresh') {
        return _json('{}', 200);
      }
      return _json('', 401);
    });
    final container = containerFor(_dioWith(adapter));
    addTearDown(container.dispose);

    final dio = container.read(authenticatedDioProvider);

    await Future.wait([
      dio.get<dynamic>('/api/chores'),
      dio.get<dynamic>('/api/tasks'),
      dio.get<dynamic>('/api/calendar'),
    ]);

    expect(refreshCalls, 1, reason: 'refresh must be de-duplicated');
    expect(logoutCalls, 0);
  });

  test('#113: every Dio gets its own interceptor, not process-global', () {
    storage.data['jwt_access_token'] = 'abc';

    final firstDio = _dioWith(_FakeAdapter((_) async => _json('{}', 200)));
    final secondDio = _dioWith(_FakeAdapter((_) async => _json('{}', 200)));

    final first = containerFor(firstDio);
    addTearDown(first.dispose);
    final second = containerFor(secondDio);
    addTearDown(second.dispose);

    first.read(authenticatedDioProvider);
    second.read(authenticatedDioProvider);

    expect(_authInterceptorCount(firstDio), 1);
    expect(
      _authInterceptorCount(secondDio),
      1,
      reason: 'the second client must not be left unauthenticated',
    );
  });

  test('reading the provider twice on one Dio does not stack interceptors', () {
    final dio = _dioWith(_FakeAdapter((_) async => _json('{}', 200)));

    final container = containerFor(dio);
    addTearDown(container.dispose);
    // A second container over the same Dio instance must not re-add.
    final other = containerFor(dio);
    addTearDown(other.dispose);

    container.read(authenticatedDioProvider);
    other.read(authenticatedDioProvider);

    expect(_authInterceptorCount(dio), 1);
  });
}
