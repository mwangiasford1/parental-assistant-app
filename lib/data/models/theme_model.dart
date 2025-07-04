// data/models/theme_model.dart

class ThemeModel {
  final String id;
  final String name;
  final String color;
  final String font;
  final String unlockRequirement;

  ThemeModel({
    required this.id,
    required this.name,
    required this.color,
    required this.font,
    required this.unlockRequirement,
  });

  factory ThemeModel.fromMap(Map<String, dynamic> map, String docId) => ThemeModel(
        id: docId,
        name: map['name'],
        color: map['color'],
        font: map['font'],
        unlockRequirement: map['unlockRequirement'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'color': color,
        'font': font,
        'unlockRequirement': unlockRequirement,
      };
} 