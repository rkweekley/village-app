import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';

// ── Models ──

class AppNotification {
  final String id;
  final String type;
  final String priority;
  final String title;
  final String body;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final String createdAt;
  final String? readAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        priority: json['priority'] as String? ?? 'Normal',
        title: json['title'] as String,
        body: json['body'] as String? ?? json['title'] as String,
        referenceId: json['referenceId'] as String?,
        referenceType: json['referenceType'] as String?,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt'] as String,
        readAt: json['readAt'] as String?,
      );

  AppNotification copyWith({bool? isRead, String? readAt}) => AppNotification(
        id: id,
        type: type,
        priority: priority,
        title: title,
        body: body,
        referenceId: referenceId,
        referenceType: referenceType,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );
}

class NotificationListResponse {
  final List<AppNotification> items;
  final int total;
  final int limit;
  final int offset;

  NotificationListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      NotificationListResponse(
        items: (json['items'] as List)
            .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        limit: json['limit'] as int,
        offset: json['offset'] as int,
      );
}

// ── Service ──

class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  Future<NotificationListResponse> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get('/api/notifications', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return NotificationListResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/api/notifications/unread-count');
    final data = res.data as Map<String, dynamic>;
    return data['count'] as int;
  }

  Future<void> markAsRead(String id) async {
    await _dio.put('/api/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.put('/api/notifications/read-all');
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/notifications/$id');
  }

  Future<void> deleteAllRead() async {
    await _dio.delete('/api/notifications');
  }
}

// ── Providers ──

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return NotificationApiService(dio);
});

/// Unread count — refreshed on auth change and via SignalR push.
final unreadCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationApiServiceProvider).getUnreadCount();
});

/// Paginated notification list.
final notificationListProvider =
    FutureProvider.family<NotificationListResponse, int>((ref, offset) {
  return ref.watch(notificationApiServiceProvider).getNotifications(offset: offset);
});

/// Simple state holder for notifications that can be appended in real-time.
class NotificationState {
  final List<AppNotification> items;
  final int total;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.items = const [],
    this.total = 0,
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<AppNotification>? items,
    int? total,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      items: items ?? this.items,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

  NotificationApiService get _api => ref.read(notificationApiServiceProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.getNotifications();
      final unread = await _api.getUnreadCount();
      state = NotificationState(
        items: response.items,
        total: response.total,
        unreadCount: unread,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.items.length >= state.total) return;
    final response = await _api.getNotifications(offset: state.items.length);
    state = state.copyWith(
      items: [...state.items, ...response.items],
      total: response.total,
    );
  }

  /// Called when a SignalR NewNotification push arrives.
  void prepend(AppNotification notification) {
    state = state.copyWith(
      items: [notification, ...state.items],
      total: state.total + 1,
      unreadCount: state.unreadCount + 1,
    );
  }

  Future<void> markRead(String id) async {
    await _api.markAsRead(id);
    state = state.copyWith(
      items: state.items.map((n) {
        if (n.id == id) return n.copyWith(isRead: true, readAt: DateTime.now().toIso8601String());
        return n;
      }).toList(),
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
  }

  Future<void> markAllRead() async {
    await _api.markAllAsRead();
    state = state.copyWith(
      items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    );
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
