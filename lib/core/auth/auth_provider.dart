import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:village_app/core/auth/auth_service.dart';
import 'package:village_app/core/auth/models.dart';
import 'package:village_app/core/network/authenticated_client.dart';

/// Auth state exposed by the notifier
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthResponse? authResponse;
  final UserInfo? userInfo;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.authResponse,
    this.userInfo,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthResponse? authResponse,
    UserInfo? userInfo,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      authResponse: authResponse ?? this.authResponse,
      userInfo: userInfo ?? this.userInfo,
      error: error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.unknown;

  /// Whether the current user can manage chores, rewards, tasks, etc.
  bool get canManage =>
      userInfo?.role == 'Parent' || userInfo?.role == 'Caregiver';
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    AuthInterceptorLogoutCallback.logout = () => logout();
    ref.onDispose(() => AuthInterceptorLogoutCallback.logout = null);
    return const AuthState();
  }

  AuthService get _authService => ref.read(authServiceProvider);

  /// Try to restore session from stored token
  Future<void> tryAutoLogin() async {
    final hasToken = await _authService.hasToken();
    if (!hasToken) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final userInfo = await _authService.getMe();
      if (userInfo != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userInfo: userInfo,
        );
      } else {
        // Token rejected — try refresh before giving up
        final refreshed = await _authService.tryRefresh();
        if (refreshed) {
          final retryUserInfo = await _authService.getMe();
          if (retryUserInfo != null) {
            state = state.copyWith(
              status: AuthStatus.authenticated,
              userInfo: retryUserInfo,
            );
            return;
          }
        }
        await _authService.logout();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        // Network error — stay authenticated with cached token
        state = state.copyWith(status: AuthStatus.authenticated);
      } else if (e.response?.statusCode == 401) {
        // Try refresh
        final refreshed = await _authService.tryRefresh();
        if (refreshed) {
          state = state.copyWith(status: AuthStatus.authenticated);
        } else {
          await _authService.logout();
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          error: 'Could not load profile. Pull to refresh.',
        );
      }
    } catch (_) {
      await _authService.logout();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> register({
    required String email,
    required String displayName,
    required String password,
    String? inviteCode,
  }) async {
    try {
      state = state.copyWith(error: null);
      final authResponse = await _authService.register(
        email: email,
        displayName: displayName,
        password: password,
        inviteCode: inviteCode,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        authResponse: authResponse,
        userInfo: UserInfo(
          id: authResponse.userId,
          displayName: authResponse.displayName,
          email: authResponse.email,
          role: authResponse.role,
          pointsBalance: 0,
          familyId: authResponse.familyId,
        ),
      );
    } on DioException catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(error: msg);
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(error: null);
      final authResponse = await _authService.login(
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        authResponse: authResponse,
        userInfo: UserInfo(
          id: authResponse.userId,
          displayName: authResponse.displayName,
          email: authResponse.email,
          role: authResponse.role,
          pointsBalance: 0,
          familyId: authResponse.familyId,
        ),
      );
    } on DioException catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(error: msg);
      rethrow;
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      state = state.copyWith(error: null);
      await _authService.forgotPassword(email: email);
    } on DioException catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(error: msg);
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String email,
  }) async {
    try {
      state = state.copyWith(error: null);
      await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
        email: email,
      );
    } on DioException catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(error: msg);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Update local user info (called after profile edit).
  void updateUserInfo(UserInfo info) {
    state = state.copyWith(userInfo: info);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _extractError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['error'] as String? ?? 'An error occurred';
      }
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is Map && parsed.containsKey('error')) {
            return parsed['error'] as String;
          }
        } catch (_) {}
        return data;
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet.';
      case DioExceptionType.connectionError:
        return 'Could not connect to server.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
