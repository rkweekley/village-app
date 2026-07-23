import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/signalr/signalr_service.dart';

/// Provider that manages SignalR lifecycle — connects when authenticated,
/// disconnects on logout, and invalidates feature providers on push events.
final signalRConnectorProvider = Provider<SignalRConnector>((ref) {
  final connector = SignalRConnector(ref);
  ref.onDispose(() => connector.dispose());
  return connector;
});

class SignalRConnector {
  final Ref _ref;
  bool _initialized = false;
  StreamSubscription? _familySub;
  StreamSubscription? _choresSub;
  StreamSubscription? _pointsSub;

  SignalRConnector(this._ref);

  /// Called once from app startup to wire up listeners.
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Watch auth state — connect/disconnect SignalR
    _ref.listen(authProvider, (prev, next) {
      final signalR = _ref.read(signalRServiceProvider);

      if (next.status == AuthStatus.authenticated && next.userInfo != null) {
        final familyId = next.userInfo!.familyId;
        if (familyId != null && familyId.isNotEmpty) {
          signalR.connectAll(familyId);

          // Subscribe to hub messages (once per session)
          _familySub ??= signalR.familyMessages.listen((msg) {
            switch (msg.target) {
              case 'MemberJoined':
              case 'MemberLeft':
              case 'FamilyUpdated':
                _ref.invalidate(familyProvider);
                break;
            }
          });

          _choresSub ??= signalR.choresMessages.listen((msg) {
            switch (msg.target) {
              case 'ChoreCreated':
              case 'ChoreUpdated':
              case 'ChoreDeleted':
              case 'ChoreAssigned':
              case 'ChoreCompleted':
              case 'ChoreApproved':
                _ref.invalidate(familyProvider);
                break;
            }
          });

          _pointsSub ??= signalR.pointsMessages.listen((msg) {
            switch (msg.target) {
              case 'PointsChanged':
              case 'RewardRedeemed':
              case 'RewardApproved':
                _ref.invalidate(familyProvider);
                break;
            }
          });
        }
      } else if (next.status == AuthStatus.unauthenticated) {
        signalR.disconnectAll();
      }
    });
  }

  void dispose() {
    _familySub?.cancel();
    _choresSub?.cancel();
    _pointsSub?.cancel();
    _ref.read(signalRServiceProvider).dispose();
  }
}
