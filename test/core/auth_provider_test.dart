import 'package:flutter_test/flutter_test.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/auth/models.dart';

void main() {
  group('AuthState', () {
    test('default state is unknown with no data', () {
      const state = AuthState();
      expect(state.status, AuthStatus.unknown);
      expect(state.isAuthenticated, false);
      expect(state.isLoading, true);
      expect(state.authResponse, isNull);
      expect(state.userInfo, isNull);
      expect(state.error, isNull);
    });

    test('copyWith updates individual fields', () {
      const state = AuthState();
      final updated = state.copyWith(
        status: AuthStatus.authenticated,
        error: 'test error',
      );
      expect(updated.status, AuthStatus.authenticated);
      expect(updated.error, 'test error');
      expect(updated.isLoading, false);
    });

    test('copyWith clears error when passing error param', () {
      final state = const AuthState().copyWith(error: 'old error');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('isAuthenticated returns true only when status is authenticated', () {
      expect(const AuthState(status: AuthStatus.authenticated).isAuthenticated, true);
      expect(const AuthState(status: AuthStatus.unauthenticated).isAuthenticated, false);
      expect(const AuthState(status: AuthStatus.unknown).isAuthenticated, false);
    });

    test('isLoading is true only when status is unknown', () {
      expect(const AuthState(status: AuthStatus.unknown).isLoading, true);
      expect(const AuthState(status: AuthStatus.authenticated).isLoading, false);
      expect(const AuthState(status: AuthStatus.unauthenticated).isLoading, false);
    });
  });

  group('AuthResponse.fromJson', () {
    test('parses all fields from JSON', () {
      final json = {
        'accessToken': 'abc.def.ghi',
        'refreshToken': 'rft.xyz.789',
        'userId': '123e4567-e89b-12d3-a456-426614174000',
        'displayName': 'Test User',
        'email': 'test@example.com',
        'role': 'Parent',
        'familyId': '223e4567-e89b-12d3-a456-426614174000',
        'familyName': 'Test Family',
        'isNewFamily': true,
      };
      final response = AuthResponse.fromJson(json);
      expect(response.accessToken, 'abc.def.ghi');
      expect(response.userId, '123e4567-e89b-12d3-a456-426614174000');
      expect(response.displayName, 'Test User');
      expect(response.email, 'test@example.com');
      expect(response.role, 'Parent');
      expect(response.familyId, '223e4567-e89b-12d3-a456-426614174000');
      expect(response.familyName, 'Test Family');
      expect(response.isNewFamily, true);
    });
  });

  group('UserInfo.fromJson', () {
    test('parses all fields from JSON', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'displayName': 'Test User',
        'email': 'test@example.com',
        'role': 'Child',
        'pointsBalance': 150,
        'familyId': '223e4567-e89b-12d3-a456-426614174000',
      };
      final user = UserInfo.fromJson(json);
      expect(user.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(user.displayName, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.role, 'Child');
      expect(user.pointsBalance, 150);
      expect(user.familyId, '223e4567-e89b-12d3-a456-426614174000');
    });

    test('pointsBalance defaults to 0 when missing', () {
      final json = {
        'id': '1',
        'displayName': 'Test',
        'email': 't@t.com',
        'role': 'Child',
        'familyId': '2',
      };
      final user = UserInfo.fromJson(json);
      expect(user.pointsBalance, 0);
    });

    test('birthDate is null when not present', () {
      final json = {
        'id': '1',
        'displayName': 'Test',
        'email': 't@t.com',
        'role': 'Child',
        'pointsBalance': 0,
        'familyId': '2',
      };
      final user = UserInfo.fromJson(json);
      expect(user.birthDate, isNull);
    });
  });
}
