import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:village_app/core/auth/secure_storage.dart';

/// Lightweight SignalR client using the JSON hub protocol over WebSocket.
///
/// Connects to a single hub endpoint, sends handshake, joins a group,
/// and dispatches incoming server invocations to listeners.
class SignalRHubClient {
  final String baseUrl;
  final String hubPath;
  final String joinMethod;
  final SecureStorage storage;
  WebSocketChannel? _channel;
  bool _connected = false;
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  final _streamController = StreamController<SignalRMessage>.broadcast();

  /// Stream of incoming server-side invocations (type: 1).
  Stream<SignalRMessage> get messages => _streamController.stream;

  bool get isConnected => _connected;

  SignalRHubClient({
    required this.baseUrl,
    required this.hubPath,
    required this.joinMethod,
    required this.storage,
  });

  /// Build the WebSocket URL with JWT access token.
  Future<Uri> _buildUri() async {
    final token = await storage.read('jwt_access_token');
    final wsUrl = baseUrl
        .replaceAll('https://', 'wss://')
        .replaceAll('http://', 'ws://');
    final uri = Uri.parse('$wsUrl$hubPath');
    return uri.replace(queryParameters: {
      if (token != null && token.isNotEmpty) 'access_token': token,
    });
  }

  /// Connect to the hub, send handshake, and join the family group.
  Future<void> connect({required String familyId}) async {
    if (_connected) return;

    try {
      final uri = await _buildUri();
      _channel = WebSocketChannel.connect(uri);

      // Send JSON protocol handshake
      _channel!.sink.add(jsonEncode({'protocol': 'json', 'version': 1}));

      // Start listening
      await _channel!.stream.listen(
        (data) {
          final msg = jsonDecode(data as String);
          if (msg is Map<String, dynamic>) {
            // Empty object = handshake accepted
            if (msg.isEmpty) {
              _connected = true;
              // Join the family group for this hub
              _invoke(joinMethod, [familyId]);
              _startKeepAlive();
              return;
            }

            // Type 1 = Invocation from server (push notification)
            if (msg['type'] == 1) {
              _streamController.add(SignalRMessage(
                target: msg['target'] as String? ?? '',
                arguments: (msg['arguments'] as List<dynamic>?) ?? [],
                invocationId: msg['invocationId'] as String?,
              ));
            }
          }
        },
        onError: (error) {
          _connected = false;
          _scheduleReconnect(familyId);
        },
        onDone: () {
          _connected = false;
          _scheduleReconnect(familyId);
        },
        cancelOnError: false,
      ).asFuture();
    } catch (e) {
      _connected = false;
      _scheduleReconnect(familyId);
    }
  }

  /// Send a method invocation to the server.
  void _invoke(String method, List<dynamic> args,
      {String? invocationId}) {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonEncode({
      'type': 1,
      'target': method,
      'arguments': args,
      if (invocationId != null) 'invocationId': invocationId,
    }));
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_connected && _channel != null) {
        _channel!.sink.add(jsonEncode({'type': 6})); // Ping
      }
    });
  }

  void _scheduleReconnect(String familyId) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect(familyId: familyId);
    });
  }

  /// Disconnect cleanly.
  Future<void> disconnect() async {
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    _connected = false;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void dispose() {
    disconnect();
    _streamController.close();
  }
}

/// A parsed SignalR invocation message from the server.
class SignalRMessage {
  final String target;
  final List<dynamic> arguments;
  final String? invocationId;

  const SignalRMessage({
    required this.target,
    required this.arguments,
    this.invocationId,
  });
}

/// Manages connections to all four hubs.
class SignalRService {
  final String baseUrl;
  final SecureStorage storage;
  late final SignalRHubClient familyHub;
  late final SignalRHubClient choresHub;
  late final SignalRHubClient pointsHub;
  late final SignalRHubClient notificationsHub;

  Stream<SignalRMessage> get familyMessages => familyHub.messages;
  Stream<SignalRMessage> get choresMessages => choresHub.messages;
  Stream<SignalRMessage> get pointsMessages => pointsHub.messages;
  Stream<SignalRMessage> get notificationsMessages => notificationsHub.messages;

  SignalRService({required this.baseUrl, required this.storage}) {
    familyHub = SignalRHubClient(
      baseUrl: baseUrl,
      hubPath: '/hubs/family',
      joinMethod: 'JoinFamilyGroup',
      storage: storage,
    );
    choresHub = SignalRHubClient(
      baseUrl: baseUrl,
      hubPath: '/hubs/chores',
      joinMethod: 'JoinChoreGroup',
      storage: storage,
    );
    pointsHub = SignalRHubClient(
      baseUrl: baseUrl,
      hubPath: '/hubs/points',
      joinMethod: 'JoinPointsGroup',
      storage: storage,
    );
    notificationsHub = SignalRHubClient(
      baseUrl: baseUrl,
      hubPath: '/hubs/notifications',
      joinMethod: 'JoinNotificationGroup',
      storage: storage,
    );
  }

  /// Connect to all hubs and join the family/notification groups.
  Future<void> connectAll(String familyId, String userId) async {
    // Connect all hubs in parallel
    await Future.wait([
      familyHub.connect(familyId: familyId),
      choresHub.connect(familyId: familyId),
      pointsHub.connect(familyId: familyId),
      notificationsHub.connect(familyId: userId), // Notifications use user-scoped group
    ]);
  }

  bool get isConnected =>
      familyHub.isConnected &&
      choresHub.isConnected &&
      pointsHub.isConnected &&
      notificationsHub.isConnected;

  Future<void> disconnectAll() async {
    await Future.wait([
      familyHub.disconnect(),
      choresHub.disconnect(),
      pointsHub.disconnect(),
      notificationsHub.disconnect(),
    ]);
  }

  void dispose() {
    familyHub.dispose();
    choresHub.dispose();
    pointsHub.dispose();
    notificationsHub.dispose();
  }
}

/// Riverpod provider for the SignalR service.
final signalRServiceProvider = Provider<SignalRService>((ref) {
  // Empty string = relative to page origin; nginx proxies /hubs/ to the API
  final storage = ref.read(secureStorageProvider);
  final service = SignalRService(baseUrl: '', storage: storage);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
