// data/models/user_model.dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profileImageUrl;
  final bool isParent;
  final int points;
  final String role; // parent, child, nanny
  final List<String> redeemedRewards;
  final Map<String, dynamic>? theme;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.isParent = true,
    this.points = 0,
    this.role = 'parent',
    this.redeemedRewards = const [],
    this.theme,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      isParent: json['isParent'] ?? true,
      points: json['points'] ?? 0,
      role: json['role'] ?? 'parent',
      redeemedRewards: (json['redeemedRewards'] as List<dynamic>?)?.cast<String>() ?? [],
      theme: json['theme'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'isParent': isParent,
      'points': points,
      'role': role,
      'redeemedRewards': redeemedRewards,
      'theme': theme,
    };
  }
}
