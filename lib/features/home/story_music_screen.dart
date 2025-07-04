// features/home/story_music_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/models/story_model.dart';

class StoryMusicScreen extends StatefulWidget {
  const StoryMusicScreen({super.key});

  @override
  State<StoryMusicScreen> createState() => _StoryMusicScreenState();
}

class _StoryMusicScreenState extends State<StoryMusicScreen> {
  String selectedTag = 'all';
  final List<String> tags = ['all', 'folktale', 'lullaby', 'bedtime'];

  @override
  Widget build(BuildContext context) {
    final storyCol = FirebaseFirestore.instance.collection('stories');
    return Scaffold(
      appBar: AppBar(title: const Text('Story & Music Time')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: tags
                  .map(
                    (tag) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8,
                      ),
                      child: ChoiceChip(
                        label: Text(tag[0].toUpperCase() + tag.substring(1)),
                        selected: selectedTag == tag,
                        onSelected: (_) => setState(() => selectedTag = tag),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedTag == 'all'
                  ? storyCol.snapshots()
                  : storyCol
                        .where('tags', arrayContains: selectedTag)
                        .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No stories found.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final story = StoryModel.fromMap(data, docs[index].id);
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoryPlayerScreen(story: story),
                        ),
                      ),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: story.coverImageUrl != null
                                  ? Image.network(
                                      story.coverImageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.grey[300]),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                story.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (story.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  story.tags.join(', '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStoryDialog(context, storyCol),
        tooltip: 'Add Story or Music',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddStoryDialog(BuildContext context, CollectionReference storyCol) {
    final titleController = TextEditingController();
    final coverController = TextEditingController();
    final audioController = TextEditingController();
    final tagsController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Story or Music'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: coverController,
                decoration: const InputDecoration(labelText: 'Cover Image URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: audioController,
                decoration: const InputDecoration(labelText: 'Audio URL'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final cover = coverController.text.trim();
              final audio = audioController.text.trim();
              final tags = tagsController.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              if (title.isEmpty || audio.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Title and audio URL are required.'),
                  ),
                );
                return;
              }
              await storyCol.add({
                'title': title,
                'coverImageUrl': cover,
                'audioUrl': audio,
                'tags': tags,
                'description': '',
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Story/Music added!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class StoryPlayerScreen extends StatefulWidget {
  final StoryModel story;
  const StoryPlayerScreen({required this.story, super.key});

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((d) => setState(() => duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => position = p));
    _audioPlayer.setSourceUrl(widget.story.audioUrl);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.story.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.story.coverImageUrl != null)
            Image.network(
              widget.story.coverImageUrl!,
              height: 220,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.story.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(widget.story.description),
          ),
          const SizedBox(height: 16),
          Slider(
            value: position.inSeconds.toDouble(),
            min: 0,
            max: duration.inSeconds.toDouble() > 0
                ? duration.inSeconds.toDouble()
                : 1,
            onChanged: (value) async {
              final pos = Duration(seconds: value.toInt());
              await _audioPlayer.seek(pos);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position)),
                Text(_formatDuration(duration)),
              ],
            ),
          ),
          Center(
            child: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 64,
              ),
              onPressed: () async {
                if (isPlaying) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.play(UrlSource(widget.story.audioUrl));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
