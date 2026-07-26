import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';

// ── Models ──

class Subject {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final int sortOrder;
  final bool isActive;

  Subject({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.sortOrder,
    required this.isActive,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        color: json['color'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );
}

class SchoolWork {
  final String id;
  final String familyId;
  final String subjectId;
  final String title;
  final String? description;
  final String assignedToId;
  final String assignedToName;
  final String dueDate;
  final int pointsPossible;
  final String status;
  final String? submissionNote;
  final int? gradePointsEarned;
  final String? gradedById;
  final String? gradedAt;
  final String createdAt;

  SchoolWork({
    required this.id,
    required this.familyId,
    required this.subjectId,
    required this.title,
    this.description,
    required this.assignedToId,
    required this.assignedToName,
    required this.dueDate,
    required this.pointsPossible,
    required this.status,
    this.submissionNote,
    this.gradePointsEarned,
    this.gradedById,
    this.gradedAt,
    required this.createdAt,
  });

  factory SchoolWork.fromJson(Map<String, dynamic> json) => SchoolWork(
        id: json['id'] as String,
        familyId: json['familyId'] as String,
        subjectId: json['subjectId'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        assignedToId: json['assignedToId'] as String,
        assignedToName: json['assignedToName'] as String,
        dueDate: json['dueDate'] as String,
        pointsPossible: json['pointsPossible'] as int,
        status: json['status'] as String,
        submissionNote: json['submissionNote'] as String?,
        gradePointsEarned: json['gradePointsEarned'] as int?,
        gradedById: json['gradedById'] as String?,
        gradedAt: json['gradedAt'] as String?,
        createdAt: json['createdAt'] as String,
      );
}

// ── Service ──

class SchoolService {
  final Dio _dio;
  SchoolService(this._dio);

  Future<List<Subject>> getSubjects() async {
    final res = await _dio.get('/api/school/subjects');
    return (res.data as List).map((j) => Subject.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> createSubject({
    required String name,
    String? description,
    String? color,
    int sortOrder = 0,
  }) async {
    final res = await _dio.post('/api/school/subjects', data: {
      'name': name,
      'description': description,
      'color': color,
      'sortOrder': sortOrder,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<SchoolWork>> getSchoolWork({String? statusFilter}) async {
    final queryParams = <String, dynamic>{};
    if (statusFilter != null && statusFilter.isNotEmpty) {
      queryParams['status'] = statusFilter;
    }
    final res = await _dio.get('/api/school', queryParameters: queryParams);
    return (res.data as List).map((j) => SchoolWork.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> createSchoolWork({
    required String subjectId,
    required String assignedToId,
    required String title,
    String? description,
    required String dueDate,
    required int pointsPossible,
  }) async {
    final res = await _dio.post('/api/school', data: {
      'subjectId': subjectId,
      'assignedToId': assignedToId,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'pointsPossible': pointsPossible,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Submit school work for grading.
  Future<Map<String, dynamic>> submitSchoolWork(
    String id, {
    String? submissionNote,
  }) async {
    final res = await _dio.put('/api/school/$id', data: {
      'status': 'Submitted',
      'submissionNote': submissionNote,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Grade a submitted school work (parent only).
  Future<Map<String, dynamic>> gradeSchoolWork(
    String id, {
    required int pointsEarned,
  }) async {
    final res = await _dio.put('/api/school/$id', data: {
      'status': 'Graded',
      'pointsEarned': pointsEarned,
    });
    return res.data as Map<String, dynamic>;
  }

  /// Get school work items pending grading (parent view).
  Future<List<SchoolWork>> getPendingGrading() async {
    final res = await _dio.get('/api/school/pending-grading');
    return (res.data as List).map((j) => SchoolWork.fromJson(j)).toList();
  }
}

// ── Providers ──

final schoolServiceProvider = Provider<SchoolService>((ref) {
  return SchoolService(ref.watch(authenticatedDioProvider));
});

final subjectsListProvider = FutureProvider<List<Subject>>((ref) {
  return ref.watch(schoolServiceProvider).getSubjects();
});

final schoolWorkListProvider = FutureProvider<List<SchoolWork>>((ref) {
  return ref.watch(schoolServiceProvider).getSchoolWork();
});

final pendingGradingProvider = FutureProvider<List<SchoolWork>>((ref) {
  return ref.watch(schoolServiceProvider).getPendingGrading();
});
