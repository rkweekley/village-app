import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';

// ── Models ──

class Chore {
  final String id;
  final String name;
  final String? description;
  final int pointValue;
  final String recurrence;
  final String difficulty;
  final bool requiresApproval;
  final bool requiresPhoto;
  final String? createdById;

  Chore({
    required this.id,
    required this.name,
    this.description,
    required this.pointValue,
    required this.recurrence,
    required this.difficulty,
    required this.requiresApproval,
    required this.requiresPhoto,
    this.createdById,
  });

  factory Chore.fromJson(Map<String, dynamic> json) => Chore(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        pointValue: json['pointValue'] as int,
        recurrence: json['recurrence'] as String,
        difficulty: json['difficulty'] as String,
        requiresApproval: json['requiresApproval'] as bool,
        requiresPhoto: json['requiresPhoto'] as bool,
        createdById: json['createdById'] as String?,
      );
}

class ChoreAssignment {
  final String id;
  final String choreId;
  final String choreName;
  final int chorePointValue;
  final String assignedToId;
  final String assignedToName;
  final String dueDate;
  final String status;
  final String? completedAt;
  final ChoreCompletion? completion;

  ChoreAssignment({
    required this.id,
    required this.choreId,
    required this.choreName,
    required this.chorePointValue,
    required this.assignedToId,
    required this.assignedToName,
    required this.dueDate,
    required this.status,
    this.completedAt,
    this.completion,
  });

  factory ChoreAssignment.fromJson(Map<String, dynamic> json) => ChoreAssignment(
        id: json['id'] as String,
        choreId: json['choreId'] as String,
        choreName: json['choreName'] as String,
        chorePointValue: json['chorePointValue'] as int,
        assignedToId: json['assignedToId'] as String,
        assignedToName: json['assignedToName'] as String,
        dueDate: json['dueDate'] as String,
        status: json['status'] as String,
        completedAt: json['completedAt'] as String?,
        completion: json['completion'] != null
            ? ChoreCompletion.fromJson(json['completion'] as Map<String, dynamic>)
            : null,
      );
}

class ChoreCompletion {
  final String id;
  final String? note;
  final String? evidencePhotoUrl;
  final String approvalStatus;
  final int pointsAwarded;
  final String? completedById;
  final String? approvedById;
  final String createdAt;
  final String? approvedAt;

  ChoreCompletion({
    required this.id,
    this.note,
    this.evidencePhotoUrl,
    required this.approvalStatus,
    required this.pointsAwarded,
    this.completedById,
    this.approvedById,
    required this.createdAt,
    this.approvedAt,
  });

  factory ChoreCompletion.fromJson(Map<String, dynamic> json) => ChoreCompletion(
        id: json['id'] as String,
        note: json['note'] as String?,
        evidencePhotoUrl: json['evidencePhotoUrl'] as String?,
        approvalStatus: json['approvalStatus'] as String,
        pointsAwarded: json['pointsAwarded'] as int,
        completedById: json['completedById'] as String?,
        approvedById: json['approvedById'] as String?,
        createdAt: json['createdAt'] as String,
        approvedAt: json['approvedAt'] as String?,
      );
}

// ── Service ──

class ChoresService {
  final Dio _dio;
  ChoresService(this._dio);

  Future<List<Chore>> getChores() async {
    final res = await _dio.get('/api/chores');
    return (res.data as List).map((j) => Chore.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> createChore({
    required String name,
    String? description,
    int pointValue = 10,
    String recurrence = 'Once',
    String difficulty = 'Easy',
    bool requiresApproval = true,
    bool requiresPhoto = false,
  }) async {
    final res = await _dio.post('/api/chores', data: {
      'name': name,
      'description': description,
      'pointValue': pointValue,
      'recurrence': recurrence,
      'difficulty': difficulty,
      'requiresApproval': requiresApproval,
      'requiresPhoto': requiresPhoto,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateChore(
    String choreId, {
    required String name,
    String? description,
    required int pointValue,
    required String recurrence,
    required String difficulty,
    required bool requiresApproval,
    required bool requiresPhoto,
  }) async {
    final res = await _dio.put('/api/chores/$choreId', data: {
      'name': name,
      'description': description,
      'pointValue': pointValue,
      'recurrence': recurrence,
      'difficulty': difficulty,
      'requiresApproval': requiresApproval,
      'requiresPhoto': requiresPhoto,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<ChoreAssignment>> getAssignments() async {
    final res = await _dio.get('/api/chores/assignments');
    return (res.data as List).map((j) => ChoreAssignment.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> assignChore(
      String choreId, String assignedToId, String dueDate) async {
    final res = await _dio.post('/api/chores/$choreId/assign', data: {
      'assignedToId': assignedToId,
      'dueDate': dueDate,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeChore(String assignmentId,
      {String? note, String? evidencePhotoUrl}) async {
    final res = await _dio.post(
      '/api/chores/assignments/$assignmentId/complete',
      data: {
        'note': note,
        'evidencePhotoUrl': evidencePhotoUrl,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> approveCompletion(
      String completionId, bool approved) async {
    final res = await _dio.post(
      '/api/chores/completions/$completionId/approve',
      data: {'approved': approved},
    );
    return res.data as Map<String, dynamic>;
  }
}

// ── Provider ──

final choresServiceProvider = Provider<ChoresService>((ref) {
  return ChoresService(ref.watch(authenticatedDioProvider));
});

final choresListProvider = FutureProvider<List<Chore>>((ref) {
  return ref.watch(choresServiceProvider).getChores();
});

final assignmentsListProvider = FutureProvider<List<ChoreAssignment>>((ref) {
  return ref.watch(choresServiceProvider).getAssignments();
});
