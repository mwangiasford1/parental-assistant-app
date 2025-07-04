// data/models/content_model.dart

class ContentModel {
  final String id;
  final String title;
  final String type;
  final List<String> tags;
  final String ageRating;
  final bool approved;
  final String submittedBy;
  final String url;

  ContentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.tags,
    required this.ageRating,
    required this.approved,
    required this.submittedBy,
    required this.url,
  });

  factory ContentModel.fromMap(Map<String, dynamic> map, String docId) => ContentModel(
        id: docId,
        title: map['title'],
        type: map['type'],
        tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        ageRating: map['ageRating'],
        approved: map['approved'] ?? false,
        submittedBy: map['submittedBy'],
        url: map['url'],
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'type': type,
        'tags': tags,
        'ageRating': ageRating,
        'approved': approved,
        'submittedBy': submittedBy,
        'url': url,
      };
} 