// ignore_for_file: use_null_aware_elements

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';
import 'package:village_app/features/family/models.dart';

/// API client for family-related endpoints.
class FamilyService {
  final Dio _dio;

  FamilyService(this._dio);

  /// Get the current user's family with all members.
  Future<FamilyInfo> getMyFamily() async {
    final response = await _dio.get('/api/families/mine');
    return FamilyInfo.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update family name, currency name, or timezone.
  Future<Map<String, dynamic>> updateFamily({
    String? name,
    String? currencyName,
    String? timezone,
  }) async {
    final response = await _dio.patch('/api/families/mine', data: {
      if (name != null) 'name': name,
      if (currencyName != null) 'currencyName': currencyName,
      if (timezone != null) 'timezone': timezone,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Look up a family by invite code (anonymous).
  Future<InviteCodeLookup?> lookupInviteCode(String code) async {
    try {
      final response = await _dio.get('/api/families/invite/$code');
      return InviteCodeLookup.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

final familyServiceProvider = Provider<FamilyService>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return FamilyService(dio);
});
