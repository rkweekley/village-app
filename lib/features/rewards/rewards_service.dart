import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';

// ── Models ──

class Reward {
  final String id;
  final String name;
  final String? description;
  final int pointCost;
  final String category;
  final int? maxRedemptions;
  final bool requiresApproval;
  final int redemptionCount;

  Reward({
    required this.id,
    required this.name,
    this.description,
    required this.pointCost,
    required this.category,
    this.maxRedemptions,
    required this.requiresApproval,
    required this.redemptionCount,
  });

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        pointCost: json['pointCost'] as int,
        category: json['category'] as String,
        maxRedemptions: json['maxRedemptions'] as int?,
        requiresApproval: json['requiresApproval'] as bool,
        redemptionCount: json['redemptionCount'] as int? ?? 0,
      );
}

class RewardRedemption {
  final String id;
  final String rewardId;
  final String rewardName;
  final int rewardPointCost;
  final String userId;
  final String userName;
  final int pointsCost;
  final String status;
  final String createdAt;
  final String? approvedAt;
  final String? approvedById;

  RewardRedemption({
    required this.id,
    required this.rewardId,
    required this.rewardName,
    required this.rewardPointCost,
    required this.userId,
    required this.userName,
    required this.pointsCost,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.approvedById,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) =>
      RewardRedemption(
        id: json['id'] as String,
        rewardId: json['rewardId'] as String,
        rewardName: json['rewardName'] as String,
        rewardPointCost: json['rewardPointCost'] as int,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        pointsCost: json['pointsCost'] as int,
        status: json['status'] as String,
        createdAt: json['createdAt'] as String,
        approvedAt: json['approvedAt'] as String?,
        approvedById: json['approvedById'] as String?,
      );
}

// ── Service ──

class RewardsService {
  final Dio _dio;
  RewardsService(this._dio);

  Future<List<Reward>> getRewards() async {
    final res = await _dio.get('/api/rewards');
    return (res.data as List).map((j) => Reward.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> createReward({
    required String name,
    String? description,
    required int pointCost,
    String category = 'Custom',
    int? maxRedemptions,
    bool requiresApproval = true,
  }) async {
    final res = await _dio.post('/api/rewards', data: {
      'name': name,
      'description': description,
      'pointCost': pointCost,
      'category': category,
      'maxRedemptions': maxRedemptions,
      'requiresApproval': requiresApproval,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    final res = await _dio.post('/api/rewards/$rewardId/redeem');
    return res.data as Map<String, dynamic>;
  }

  Future<List<RewardRedemption>> getRedemptions() async {
    final res = await _dio.get('/api/rewards/redemptions');
    return (res.data as List).map((j) => RewardRedemption.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> approveRedemption(
      String redemptionId, bool approved) async {
    final res = await _dio.post(
      '/api/rewards/redemptions/$redemptionId/approve',
      data: {'approved': approved},
    );
    return res.data as Map<String, dynamic>;
  }
}

// ── Provider ──

final rewardsServiceProvider = Provider<RewardsService>((ref) {
  return RewardsService(ref.watch(authenticatedDioProvider));
});

final rewardsListProvider = FutureProvider<List<Reward>>((ref) {
  return ref.watch(rewardsServiceProvider).getRewards();
});

final redemptionsListProvider = FutureProvider<List<RewardRedemption>>((ref) {
  return ref.watch(rewardsServiceProvider).getRedemptions();
});
