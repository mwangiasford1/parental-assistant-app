// features/home/theme_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/theme_model.dart';
import '../../data/models/user_model.dart';

class ThemePickerScreen extends StatefulWidget {
  final UserModel user;
  const ThemePickerScreen({required this.user, super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  String? selectedThemeId;
  Map<String, dynamic>? userTheme;
  List<String> unlockedThemes = [];

  @override
  void initState() {
    super.initState();
    userTheme = widget.user.theme ?? {};
    unlockedThemes = List<String>.from(userTheme?['unlockedThemes'] ?? ['default']);
    selectedThemeId = userTheme?['selected'] ?? 'default';
  }

  Future<void> _applyTheme(ThemeModel theme) async {
    final newTheme = {
      'color': theme.color,
      'font': theme.font,
      'unlockedThemes': unlockedThemes,
      'selected': theme.id,
    };
    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({'theme': newTheme});
    setState(() {
      userTheme = newTheme;
      selectedThemeId = theme.id;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Theme applied: ${theme.name}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Picker')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('themes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No themes available.'));
          final themes = docs.map((d) => ThemeModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: themes.length,
            itemBuilder: (context, index) {
              final theme = themes[index];
              final unlocked = unlockedThemes.contains(theme.id);
              final isSelected = selectedThemeId == theme.id;
              return Card(
                color: Color(int.parse(theme.color.replaceFirst('#', '0xff'))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(theme.name, style: TextStyle(fontFamily: theme.font, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Font: ${theme.font}', style: TextStyle(fontFamily: theme.font)),
                    const SizedBox(height: 8),
                    if (!unlocked)
                      Column(
                        children: [
                          const Icon(Icons.lock, color: Colors.red),
                          Text(theme.unlockRequirement, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    if (unlocked)
                      ElevatedButton(
                        onPressed: isSelected ? null : () => _applyTheme(theme),
                        child: Text(isSelected ? 'Selected' : 'Apply'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 