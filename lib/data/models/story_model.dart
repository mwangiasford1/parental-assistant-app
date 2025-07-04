// data/models/story_model.dart

class StoryModel {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String? coverImageUrl;
  final int? duration;
  final List<String> tags;

  StoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    this.coverImageUrl,
    this.duration,
    this.tags = const [],
  });

  factory StoryModel.fromMap(Map<String, dynamic> map, String docId) => StoryModel(
        id: docId,
        title: map['title'],
        description: map['description'],
        audioUrl: map['audioUrl'],
        coverImageUrl: map['coverImageUrl'],
        duration: map['duration'],
        tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'audioUrl': audioUrl,
        'coverImageUrl': coverImageUrl,
        'duration': duration,
        'tags': tags,
      };
} 