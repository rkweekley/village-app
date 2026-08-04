/// Data models for auth responses
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String displayName;
  final String email;
  final String role;
  final String familyId;
  final String familyName;
  final bool isNewFamily;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.familyId,
    required this.familyName,
    required this.isNewFamily,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      familyId: json['familyId'] as String,
      familyName: json['familyName'] as String,
      isNewFamily: json['isNewFamily'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
        'displayName': displayName,
        'email': email,
        'role': role,
        'familyId': familyId,
        'familyName': familyName,
        'isNewFamily': isNewFamily,
      };
}

class UserInfo {
  final String id;
  final String displayName;
  final String email;
  final String role;
  final int pointsBalance;
  final String? birthDate;
  final String familyId;

  UserInfo({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.pointsBalance,
    this.birthDate,
    required this.familyId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      pointsBalance: json['pointsBalance'] as int? ?? 0,
      birthDate: json['birthDate'] as String?,
      familyId: json['familyId'] as String,
    );
  }
}
