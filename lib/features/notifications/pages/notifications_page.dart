import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/core/widgets/empty_state.dart';
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
    Future.microtask(() => ref.read(notificationProvider.notifier).load());
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'ChoreAssigned':
        return Icons.assignment_rounded;
      case 'ChoreCompleted':
        return Icons.check_circle_rounded;
      case 'ChoreApproved':
        return Icons.verified_rounded;
      case 'ChoreRejected':
        return Icons.cancel_rounded;
      case 'RewardRedeemed':
        return Icons.card_giftcard_rounded;
      case 'RewardApproved':
        return Icons.celebration_rounded;
      case 'RewardRejected':
        return Icons.sentiment_dissatisfied_rounded;
      case 'PointsChanged':
        return Icons.monetization_on_rounded;
      case 'FamilyMemberJoined':
        return Icons.person_add_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForNotification(String type, String priority) {
    // Use priority-based coloring
    if (priority == 'High') return VillageTheme.mealsCoral;
    if (priority == 'Low') return Colors.grey;
    // Type-based fallback
    if (type.startsWith('Chore')) return VillageTheme.choresGreen;
    if (type.startsWith('Reward')) return VillageTheme.rewardsAmber;
    if (type == 'PointsChanged') return VillageTheme.rewardsAmber;
    if (type == 'FamilyMemberJoined') return VillageTheme.primaryTeal;
    return VillageTheme.primaryTeal;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (state.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Mark all as read',
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_off_rounded,
                  title: 'No notifications yet',
                  iconBgColor: VillageTheme.primaryTeal,
                  iconColor: VillageTheme.primaryTeal,
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 200) {
                      ref.read(notificationProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) {
                      final n = state.items[i];
                      final accentColor =
                          _colorForNotification(n.type, n.priority);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: n.isRead
                            ? VillageTheme.surfaceWarm
                            : VillageTheme.backgroundWarm,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (!n.isRead) {
                              ref
                                  .read(notificationProvider.notifier)
                                  .markRead(n.id);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Accent icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color:
                                        accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _iconForType(n.type),
                                    size: 20,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: n.isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin:
                                                  const EdgeInsets.only(left: 6),
                                              decoration: BoxDecoration(
                                                color: accentColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (n.body.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          n.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: n.isRead
                                                ? Colors.grey[500]
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        _timeAgo(n.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
