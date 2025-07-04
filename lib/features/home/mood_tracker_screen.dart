// features/home/mood_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final String userId = 'demoUser'; // TODO: Replace with actual auth user
  final List<String> moods = ['😃', '🙂', '😐', '😢', '😡'];
  String? selectedMood;
  final TextEditingController _noteController = TextEditingController();

  CollectionReference get moodCol => FirebaseFirestore.instance.collection('moods');

  Future<void> _submitMood() async {
    if (selectedMood == null) return;
    await moodCol.add({
      'userId': userId,
      'mood': selectedMood,
      'note': _noteController.text.trim(),
      'timestamp': Timestamp.now(),
    });
    setState(() {
      selectedMood = null;
      _noteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mood submitted!')));
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How are you feeling today?', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: moods.map((mood) => GestureDetector(
                onTap: () => setState(() => selectedMood = mood),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: selectedMood == mood ? Colors.blue[100] : Colors.grey[200],
                  child: Text(mood, style: const TextStyle(fontSize: 28)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: selectedMood == null ? null : _submitMood,
                child: const Text('Submit'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text('Recent Moods', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: moodCol
                    .where('userId', isEqualTo: userId)
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('No moods yet.'));
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final mood = data['mood'] ?? '';
                      final note = data['note'] ?? '';
                      final ts = (data['timestamp'] as Timestamp).toDate();
                      return ListTile(
                        leading: Text(mood, style: const TextStyle(fontSize: 24)),
                        title: Text('${ts.month}/${ts.day} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}'),
                        subtitle: note.isNotEmpty ? Text(note) : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 