import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/features/notifications/notification_service.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Load notifications on first build
    Future.microtask(() => ref.read(notificationProvider.notifier).load());
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'ChoreAssigned':
        return Icons.assignment;
      case 'ChoreCompleted':
        return Icons.check_circle_outline;
      case 'ChoreApproved':
        return Icons.verified;
      case 'ChoreRejected':
        return Icons.cancel_outlined;
      case 'RewardRedeemed':
        return Icons.card_giftcard;
      case 'RewardApproved':
        return Icons.celebration;
      case 'RewardRejected':
        return Icons.sentiment_dissatisfied;
      case 'PointsChanged':
        return Icons.monetization_on;
      case 'FamilyMemberJoined':
        return Icons.person_add;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForPriority(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Low':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                      ref.read(notificationProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = state.items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _colorForPriority(n.priority).withValues(alpha: 0.1),
                          child: Icon(_iconForType(n.type), size: 20, color: _colorForPriority(n.priority)),
                        ),
                        title: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: n.isRead ? null : Colors.grey.shade700,
                          ),
                        ),
                        trailing: n.isRead
                            ? Text(
                                _timeAgo(n.createdAt),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _timeAgo(n.createdAt),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                        onTap: () {
                          if (!n.isRead) {
                            ref.read(notificationProvider.notifier).markRead(n.id);
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }
}
