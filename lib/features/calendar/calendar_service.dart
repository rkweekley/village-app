import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';

// ── Models ──

class CalendarEventModel {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final String? color;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? recurrenceRule;
  final String organizerId;
  final String organizerName;
  final String createdAt;
  final List<CalendarAttendee> attendees;

  CalendarEventModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.color,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    this.recurrenceRule,
    required this.organizerId,
    required this.organizerName,
    required this.createdAt,
    this.attendees = const [],
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) =>
      CalendarEventModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        color: json['color'] as String?,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        isAllDay: json['isAllDay'] as bool,
        recurrenceRule: json['recurrenceRule'] as String?,
        organizerId: json['organizerId'] as String,
        organizerName: json['organizerName'] as String,
        createdAt: json['createdAt'] as String,
        attendees: (json['attendees'] as List?)
                ?.map((a) => CalendarAttendee.fromJson(a))
                .toList() ??
            [],
      );
}

class CalendarAttendee {
  final String userId;
  final String status;

  CalendarAttendee({required this.userId, required this.status});

  factory CalendarAttendee.fromJson(Map<String, dynamic> json) =>
      CalendarAttendee(
        userId: json['userId'] as String,
        status: json['status'] as String,
      );
}

// ── Service ──

class CalendarService {
  final Dio _dio;
  CalendarService(this._dio);

  Future<List<CalendarEventModel>> getEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();

    final res = await _dio.get('/api/calendar', queryParameters: params);
    return (res.data as List)
        .map((j) => CalendarEventModel.fromJson(j))
        .toList();
  }

  Future<CalendarEventModel> getEvent(String id) async {
    final res = await _dio.get('/api/calendar/$id');
    return CalendarEventModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    String? description,
    String? location,
    String? color,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
    String? recurrenceRule,
    List<String>? attendeeIds,
  }) async {
    final res = await _dio.post('/api/calendar', data: {
      'title': title,
      'description': description,
      'location': location,
      'color': color,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAllDay': isAllDay,
      'recurrenceRule': recurrenceRule,
      'attendeeIds': attendeeIds,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateEvent(String id,
      {String? title,
      String? description,
      String? location,
      String? color,
      DateTime? startTime,
      DateTime? endTime,
      bool? isAllDay,
      String? recurrenceRule,
      List<String>? attendeeIds}) async {
    final res = await _dio.put('/api/calendar/$id', data: {
      ?'title': title,
      'description': description,
      'location': location,
      'color': color,
      ?'startTime': startTime?.toIso8601String(),
      ?'endTime': endTime?.toIso8601String(),
      ?'isAllDay': isAllDay,
      'recurrenceRule': recurrenceRule,
      'attendeeIds': attendeeIds,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete('/api/calendar/$id');
  }

  Future<Map<String, dynamic>> rsvp(String eventId, String status) async {
    final res =
        await _dio.post('/api/calendar/$eventId/rsvp', data: {'status': status});
    return res.data as Map<String, dynamic>;
  }
}

// ── Provider ──

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService(ref.watch(authenticatedDioProvider));
});

final calendarEventsProvider =
    FutureProvider.family<List<CalendarEventModel>, CalendarDateRange>((ref, range) {
  return ref
      .watch(calendarServiceProvider)
      .getEvents(from: range.start, to: range.end);
});

class CalendarDateRange {
  final DateTime start;
  final DateTime end;
  CalendarDateRange({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarDateRange &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
