import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/core/signalr/signalr_service.dart';
import 'package:village_app/features/notifications/notification_service.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/features/chores/chores_service.dart';
import 'package:village_app/features/shopping/shopping_service.dart';

/// Provider that manages SignalR lifecycle — connects when authenticated,
/// disconnects on logout, and invalidates feature providers on push events.
final signalRConnectorProvider = Provider<SignalRConnector>((ref) {
  final connector = SignalRConnector(ref);
  ref.onDispose(() => connector.dispose());
  return connector;
});

class SignalRConnector {
  final Ref _ref;
  final SignalRService _signalR;
  bool _initialized = false;
  StreamSubscription? _familySub;
  StreamSubscription? _choresSub;
  StreamSubscription? _pointsSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _shoppingSub;

  SignalRConnector(this._ref)
      : _signalR = _ref.read(signalRServiceProvider);

  /// Called once from app startup to wire up listeners.
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Watch auth state — connect/disconnect SignalR
    _ref.listen(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated && next.userInfo != null) {
        final familyId = next.userInfo!.familyId;
        final userId = next.userInfo!.id;
        if (familyId.isNotEmpty) {
          _signalR.connectAll(familyId, userId);

          // Subscribe to hub messages (once per session)
          _familySub ??= _signalR.familyMessages.listen((msg) {
            switch (msg.target) {
              case 'MemberJoined':
              case 'MemberLeft':
              case 'FamilyUpdated':
                _ref.invalidate(familyProvider);
                break;
            }
          });

          _choresSub ??= _signalR.choresMessages.listen((msg) {
            switch (msg.target) {
              case 'ChoreCreated':
              case 'ChoreUpdated':
              case 'ChoreDeleted':
                _ref.invalidate(choresListProvider);
                break;
              case 'ChoreAssigned':
              case 'ChoreCompleted':
              case 'ChoreApproved':
              case 'ChoreRejected':
                _ref.invalidate(assignmentsListProvider);
                break;
            }
          });

          _pointsSub ??= _signalR.pointsMessages.listen((msg) {
            switch (msg.target) {
              case 'PointsChanged':
              case 'RewardRedeemed':
              case 'RewardApproved':
                _ref.invalidate(familyProvider);
                break;
            }
          });

          // Listen for real-time notifications
          _notificationsSub ??= _signalR.notificationsMessages.listen((msg) {
            if (msg.target == 'NewNotification' && msg.arguments.isNotEmpty) {
              final data = msg.arguments[0] as Map<String, dynamic>;
              final notification = AppNotification.fromJson(data);
              _ref.read(notificationProvider.notifier).prepend(notification);
            }
          });

          // Listen for shopping list changes
          _shoppingSub ??= _signalR.shoppingMessages.listen((msg) {
            switch (msg.target) {
              case 'ShoppingListCreated':
              case 'ShoppingListDeleted':
              case 'ShoppingItemAdded':
              case 'ShoppingItemToggled':
              case 'ShoppingItemUpdated':
              case 'ShoppingItemDeleted':
                _ref.invalidate(shoppingListsProvider);
                break;
            }
          });
        }
      } else if (next.status == AuthStatus.unauthenticated) {
        _signalR.disconnectAll();
      }
    });
  }

  void dispose() {
    _familySub?.cancel();
    _choresSub?.cancel();
    _pointsSub?.cancel();
    _notificationsSub?.cancel();
    _shoppingSub?.cancel();
    _signalR.dispose();
  }
}
