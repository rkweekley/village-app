/// Data classes for family API responses.
class FamilyInfo {
  final String id;
  final String name;
  final String inviteCode;
  final String currencyName;
  final String timezone;
  final List<MemberInfo> members;

  FamilyInfo({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.currencyName,
    required this.timezone,
    required this.members,
  });

  factory FamilyInfo.fromJson(Map<String, dynamic> json) {
    return FamilyInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      currencyName: json['currencyName'] as String? ?? 'Points',
      timezone: json['timezone'] as String? ?? 'America/New_York',
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => MemberInfo.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MemberInfo {
  final String id;
  final String displayName;
  final String email;
  final String role;
  final int pointsBalance;
  final String? birthDate;

  MemberInfo({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.pointsBalance,
    this.birthDate,
  });

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      pointsBalance: json['pointsBalance'] as int? ?? 0,
      birthDate: json['birthDate'] as String?,
    );
  }
}

class InviteCodeLookup {
  final String id;
  final String name;
  final String inviteCode;
  final int memberCount;

  InviteCodeLookup({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.memberCount,
  });

  factory InviteCodeLookup.fromJson(Map<String, dynamic> json) {
    return InviteCodeLookup(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      memberCount: json['memberCount'] as int,
    );
  }
}
