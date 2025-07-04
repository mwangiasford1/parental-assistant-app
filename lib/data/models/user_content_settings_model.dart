// data/models/user_content_settings_model.dart

class UserContentSettingsModel {
  final String userId;
  final List<String> allowedTags;
  final String maxAgeRating;
  final bool approvedOnly;

  UserContentSettingsModel({
    required this.userId,
    this.allowedTags = const [],
    this.maxAgeRating = 'all',
    this.approvedOnly = true,
  });

  factory UserContentSettingsModel.fromMap(Map<String, dynamic> map, String userId) => UserContentSettingsModel(
        userId: userId,
        allowedTags: (map['allowedTags'] as List<dynamic>?)?.cast<String>() ?? [],
        maxAgeRating: map['maxAgeRating'] ?? 'all',
        approvedOnly: map['approvedOnly'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'allowedTags': allowedTags,
        'maxAgeRating': maxAgeRating,
        'approvedOnly': approvedOnly,
      };
} 