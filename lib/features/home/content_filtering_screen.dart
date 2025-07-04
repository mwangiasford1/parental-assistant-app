// features/home/content_filtering_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_content_settings_model.dart';

class ContentFilteringScreen extends StatefulWidget {
  const ContentFilteringScreen({super.key});

  @override
  State<ContentFilteringScreen> createState() => _ContentFilteringScreenState();
}

class _ContentFilteringScreenState extends State<ContentFilteringScreen> {
  final String userId = 'demoUser'; // TODO: Replace with actual auth user
  final List<String> allTags = ['folktale', 'lullaby', 'bedtime', 'educational'];
  final List<String> ageRatings = ['all', '7+', '13+'];
  bool isParent = true; // TODO: Replace with actual user role check

  late UserContentSettingsModel settings;
  bool loadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance.collection('user_content_settings').doc(userId).get();
    setState(() {
      settings = doc.exists
          ? UserContentSettingsModel.fromMap(doc.data()!, userId)
          : UserContentSettingsModel(userId: userId, allowedTags: allTags, maxAgeRating: 'all', approvedOnly: true);
      loadingSettings = false;
    });
  }

  Future<void> _updateSettings({List<String>? allowedTags, String? maxAgeRating, bool? approvedOnly}) async {
    settings = UserContentSettingsModel(
      userId: settings.userId,
      allowedTags: allowedTags ?? settings.allowedTags,
      maxAgeRating: maxAgeRating ?? settings.maxAgeRating,
      approvedOnly: approvedOnly ?? settings.approvedOnly,
    );
    await FirebaseFirestore.instance.collection('user_content_settings').doc(userId).set(settings.toMap());
    setState(() {});
  }

  Future<void> _approveContent(String contentId) async {
    await FirebaseFirestore.instance.collection('content').doc(contentId).update({'approved': true});
    setState(() {});
  }

  Future<void> _denyContent(String contentId) async {
    await FirebaseFirestore.instance.collection('content').doc(contentId).update({'approved': false});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Content Filtering & Parental Controls')),
      body: loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ExpansionTile(
                  title: const Text('Parental Controls'),
                  children: [
                    Wrap(
                      spacing: 8,
                      children: allTags.map((tag) => FilterChip(
                        label: Text(tag),
                        selected: settings.allowedTags.contains(tag),
                        onSelected: (v) {
                          final updatedTags = List<String>.from(settings.allowedTags);
                          if (v) {
                            updatedTags.add(tag);
                          } else {
                            updatedTags.remove(tag);
                          }
                          _updateSettings(allowedTags: updatedTags);
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: settings.maxAgeRating,
                      items: ageRatings.map((r) => DropdownMenuItem(value: r, child: Text('Max Age: $r'))).toList(),
                      onChanged: (v) {
                        _updateSettings(maxAgeRating: v ?? 'all');
                      },
                    ),
                    SwitchListTile(
                      value: settings.approvedOnly,
                      onChanged: (v) {
                        _updateSettings(approvedOnly: v);
                      },
                      title: const Text('Approved Only'),
                    ),
                  ],
                ),
                if (isParent) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Pending Content Approvals', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('content').where('approved', isEqualTo: false).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) return const Center(child: Text('No pending content.'));
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final id = docs[index].id;
                            return Card(
                              child: ListTile(
                                title: Text(data['title'] ?? 'Untitled'),
                                subtitle: Text('Type: ${data['type'] ?? ''} | Tags: ${(data['tags'] as List<dynamic>?)?.join(", ") ?? ''}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      tooltip: 'Approve',
                                      onPressed: () => _approveContent(id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      tooltip: 'Deny',
                                      onPressed: () => _denyContent(id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Available Content', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('content').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      final filtered = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final tags = (data['tags'] as List<dynamic>?)?.cast<String>() ?? [];
                        final age = data['ageRating'] ?? 'all';
                        final approved = data['approved'] ?? false;
                        final tagOk = tags.any((t) => settings.allowedTags.contains(t));
                        final ageOk = settings.maxAgeRating == 'all' || age == 'all' || age == settings.maxAgeRating;
                        final approvedOk = !settings.approvedOnly || approved;
                        return tagOk && ageOk && approvedOk;
                      }).toList();
                      if (filtered.isEmpty) return const Center(child: Text('No content available.'));
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final data = filtered[index].data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              title: Text(data['title'] ?? 'Untitled'),
                              subtitle: Text('Type: ${data['type'] ?? ''} | Tags: ${(data['tags'] as List<dynamic>?)?.join(", ") ?? ''}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
} 