import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/calendar/calendar_service.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
      23,
      59,
    );

    final eventsAsync = ref.watch(
      calendarEventsProvider(
        CalendarDateRange(start: monthStart, end: monthEnd),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${_monthName(_focusedMonth.month)} ${_focusedMonth.year}'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => setState(
            () => _focusedMonth = _focusedMonth.subtract(
              const Duration(days: 30),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => setState(
              () => _focusedMonth = _focusedMonth.add(const Duration(days: 30)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Today',
            onPressed: () => setState(() {
              _focusedMonth = DateTime.now();
              _selectedDay = DateTime.now();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventSheet(context),
        child: const Icon(Icons.add),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) => Column(
          children: [
            _CalendarGrid(
              focusedMonth: _focusedMonth,
              selectedDay: _selectedDay,
              events: events,
              onDaySelected: (day) => setState(() => _selectedDay = day),
            ),
            if (_selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: VillageTheme.primaryLight.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        size: 18,
                        color: VillageTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Events for ${_selectedDay!.month}/${_selectedDay!.day}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _DayEventsList(day: _selectedDay!, events: events),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateEventSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    DateTime start = DateTime.now().add(const Duration(hours: 1));
    DateTime end = DateTime.now().add(const Duration(hours: 2));
    bool allDay = false;
    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: VillageTheme.primaryLight.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: VillageTheme.primaryLight,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'New Event',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          filled: true,
                          fillColor: VillageTheme.surfaceBase,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          labelText: 'Description (optional)',
                          filled: true,
                          fillColor: VillageTheme.surfaceBase,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locCtrl,
                        decoration: InputDecoration(
                          labelText: 'Location (optional)',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: VillageTheme.surfaceBase,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: start,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: Theme.of(context).colorScheme
                                          .copyWith(
                                            primary: VillageTheme.primaryLight,
                                          ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setDialogState(
                                    () => start = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      start.hour,
                                      start.minute,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: VillageTheme.surfaceBase,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${start.month}/${start.day}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: end,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: Theme.of(context).colorScheme
                                          .copyWith(
                                            primary: VillageTheme.primaryLight,
                                          ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setDialogState(
                                    () => end = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      end.hour,
                                      end.minute,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: VillageTheme.surfaceBase,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${end.month}/${end.day}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: VillageTheme.surfaceBase,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SwitchListTile(
                          title: const Text('All day event'),
                          value: allDay,
                          activeColor: VillageTheme.primaryLight,
                          onChanged: (v) => setDialogState(() => allDay = v),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () async {
                          if (titleCtrl.text.isEmpty) return;
                          await ref
                              .read(calendarServiceProvider)
                              .createEvent(
                                title: titleCtrl.text,
                                description: descCtrl.text.isNotEmpty
                                    ? descCtrl.text
                                    : null,
                                location: locCtrl.text.isNotEmpty
                                    ? locCtrl.text
                                    : null,
                                startTime: start,
                                endTime: end,
                                isAllDay: allDay,
                              );
                          final monthStart = DateTime(
                            _focusedMonth.year, _focusedMonth.month, 1);
                          final monthEnd = DateTime(
                            _focusedMonth.year, _focusedMonth.month + 1,
                            0, 23, 59);
                          // ignore: unused_result
                          ref.refresh(
                            calendarEventsProvider(
                              CalendarDateRange(
                                start: monthStart, end: monthEnd)));
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: VillageTheme.primaryLight,
                        ),
                        child: const Text(
                          'Create Event',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}

// ── Helpers ──

Color _parseHexColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

// ── Calendar Grid ──

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final List<CalendarEventModel> events;
  final void Function(DateTime) onDaySelected;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;

    final dayEvents = <int, List<CalendarEventModel>>{};
    for (final e in events) {
      for (var d = 1; d <= daysInMonth; d++) {
        final day = DateTime(focusedMonth.year, focusedMonth.month, d);
        if (!e.endTime.isBefore(day) &&
            !e.startTime.isAfter(day.add(const Duration(hours: 24)))) {
          dayEvents.putIfAbsent(d, () => []);
          dayEvents[d]!.add(e);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          // Weekday headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: VillageTheme.surfaceBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),
          // Day grid
          ...List.generate(((startWeekday + daysInMonth) / 7).ceil(), (
            weekIndex,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (weekdayIndex) {
                  final dayNum =
                      weekIndex * 7 + weekdayIndex - startWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }

                  final isToday =
                      DateTime.now().day == dayNum &&
                      DateTime.now().month == focusedMonth.month &&
                      DateTime.now().year == focusedMonth.year;
                  final isSelected =
                      selectedDay?.day == dayNum &&
                      selectedDay?.month == focusedMonth.month;
                  final hasEvents = dayEvents.containsKey(dayNum);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDaySelected(
                        DateTime(focusedMonth.year, focusedMonth.month, dayNum),
                      ),
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? VillageTheme.primaryLight
                              : isToday
                              ? VillageTheme.primaryLight.withValues(alpha: 0.1)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: VillageTheme.primaryLight.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontWeight: isToday || isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                    ? VillageTheme.primaryLight
                                    : null,
                              ),
                            ),
                            if (hasEvents)
                              Positioned(
                                bottom: 6,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : VillageTheme.primaryLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Day Events List ──

class _DayEventsList extends ConsumerWidget {
  final DateTime day;
  final List<CalendarEventModel> events;

  const _DayEventsList({required this.day, required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).userInfo?.id;
    final dayEvents = events.where((e) {
      return !e.endTime.isBefore(day) &&
          !e.startTime.isAfter(day.add(const Duration(hours: 24)));
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: VillageTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 28,
                color: VillageTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No events this day',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh context event list
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: dayEvents.length,
        itemBuilder: (ctx, i) {
          final e = dayEvents[i];
          final evColor = e.color != null
              ? _parseHexColor(e.color!)
              : VillageTheme.primaryLight;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            color: VillageTheme.surfaceCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  leading: Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: evColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  title: Text(
                    e.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${e.isAllDay ? 'All day' : '${_formatTime(e.startTime)} - ${_formatTime(e.endTime)}'}${e.location != null ? ' · ${e.location}' : ''}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.grey[400],
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        ref.read(calendarServiceProvider).deleteEvent(e.id);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (userId != null &&
                    e.attendees.any((a) => a.userId == userId)) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _RsvpButton(
                          label: 'Going',
                          icon: Icons.check_circle_rounded,
                          isSelected: e.attendees.any(
                            (a) => a.userId == userId && a.status == 'Accepted',
                          ),
                          selectedColor: VillageTheme.positive,
                          onPressed: () => ref
                              .read(calendarServiceProvider)
                              .rsvp(e.id, 'Accepted'),
                        ),
                        const SizedBox(width: 8),
                        _RsvpButton(
                          label: 'Maybe',
                          icon: Icons.help_rounded,
                          isSelected: e.attendees.any(
                            (a) =>
                                a.userId == userId && a.status == 'Tentative',
                          ),
                          selectedColor: VillageTheme.warning,
                          onPressed: () => ref
                              .read(calendarServiceProvider)
                              .rsvp(e.id, 'Tentative'),
                        ),
                        const SizedBox(width: 8),
                        _RsvpButton(
                          label: 'No',
                          icon: Icons.cancel_rounded,
                          isSelected: e.attendees.any(
                            (a) => a.userId == userId && a.status == 'Declined',
                          ),
                          selectedColor: VillageTheme.danger,
                          onPressed: () => ref
                              .read(calendarServiceProvider)
                              .rsvp(e.id, 'Declined'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _RsvpButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onPressed;

  const _RsvpButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.12)
              : VillageTheme.surfaceBase,
          borderRadius: BorderRadius.circular(10),
          border: !isSelected
              ? Border.all(color: Colors.grey.withValues(alpha: 0.15))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? selectedColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? selectedColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
