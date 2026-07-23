import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/features/calendar/calendar_service.dart';

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
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59);

    final eventsAsync = ref.watch(
      calendarEventsProvider(
        DateTimeRange(start: monthStart, end: monthEnd),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () =>
              setState(() => _focusedMonth = _focusedMonth.subtract(const Duration(days: 30))),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () =>
                setState(() => _focusedMonth = _focusedMonth.add(const Duration(days: 30))),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() {
              _focusedMonth = DateTime.now();
              _selectedDay = DateTime.now();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEventDialog(context),
          ),
        ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Events for ${_selectedDay!.month}/${_selectedDay!.day}',
                  style: Theme.of(context).textTheme.titleMedium,
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

  void _showCreateEventDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    DateTime start = DateTime.now().add(const Duration(hours: 1));
    DateTime end = DateTime.now().add(const Duration(hours: 2));
    bool allDay = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('All day'),
                  trailing: Switch(
                    value: allDay,
                    onChanged: (v) => setState(() => allDay = v),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                ref.read(calendarServiceProvider).createEvent(
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      location: locCtrl.text,
                      startTime: start,
                      endTime: end,
                      isAllDay: allDay,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}

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
    final startWeekday = firstDay.weekday % 7; // Sunday = 0
    final daysInMonth = lastDay.day;

    final dayEvents = <int, List<CalendarEventModel>>{};
    for (final e in events) {
      for (var d = 1; d <= daysInMonth; d++) {
        final day = DateTime(focusedMonth.year, focusedMonth.month, d);
        if (!e.endTime.isBefore(day) && !e.startTime.isAfter(
            day.add(const Duration(hours: 24)))) {
          dayEvents.putIfAbsent(d, () => []);
          dayEvents[d]!.add(e);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Day grid
          ...List.generate(
            ((startWeekday + daysInMonth) / 7).ceil(),
            (weekIndex) {
              return Row(
                children: List.generate(7, (weekdayIndex) {
                  final dayNum = weekIndex * 7 + weekdayIndex - startWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final isToday = DateTime.now().day == dayNum &&
                      DateTime.now().month == focusedMonth.month &&
                      DateTime.now().year == focusedMonth.year;
                  final isSelected = selectedDay?.day == dayNum &&
                      selectedDay?.month == focusedMonth.month;
                  final hasEvents = dayEvents.containsKey(dayNum);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDaySelected(
                          DateTime(focusedMonth.year, focusedMonth.month, dayNum)),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontWeight: isToday ? FontWeight.bold : null,
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : null,
                              ),
                            ),
                            if (hasEvents)
                              Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayEventsList extends StatelessWidget {
  final DateTime day;
  final List<CalendarEventModel> events;

  const _DayEventsList({required this.day, required this.events});

  @override
  Widget build(BuildContext context) {
    final dayEvents = events.where((e) {
      return !e.endTime.isBefore(day) &&
          !e.startTime.isAfter(day.add(const Duration(hours: 24)));
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (dayEvents.isEmpty) {
      return const Center(child: Text('No events this day'));
    }

    return ListView.builder(
      itemCount: dayEvents.length,
      itemBuilder: (ctx, i) {
        final e = dayEvents[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: _parseColor(e.color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(e.title),
            subtitle: Text(
              '${e.isAllDay ? 'All day' : '${e.startTime.hour}:${e.startTime.minute.toString().padLeft(2, '0')} - ${e.endTime.hour}:${e.endTime.minute.toString().padLeft(2, '0')}'}${e.location != null ? ' · ${e.location}' : ''}',
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String? color) {
    if (color == null) return Colors.blue;
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }
}
