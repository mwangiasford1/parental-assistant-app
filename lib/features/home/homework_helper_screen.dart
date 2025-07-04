// features/home/homework_helper_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkHelperScreen extends StatefulWidget {
  const HomeworkHelperScreen({super.key});

  @override
  State<HomeworkHelperScreen> createState() => _HomeworkHelperScreenState();
}

class _HomeworkHelperScreenState extends State<HomeworkHelperScreen>
    with SingleTickerProviderStateMixin {
  final String userId = 'demoUser'; // TODO: Replace with actual auth user
  late TabController _tabController;

  int _currentTab = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDialog(BuildContext context) {
    if (_currentTab == 0) {
      _showAddFlashcardDialog(context);
    } else {
      _showAddHomeworkDialog(context);
    }
  }

  void _showAddFlashcardDialog(BuildContext context) {
    final qController = TextEditingController();
    final aController = TextEditingController();
    final sController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qController,
              decoration: InputDecoration(labelText: 'Question'),
            ),
            TextField(
              controller: aController,
              decoration: InputDecoration(labelText: 'Answer'),
            ),
            TextField(
              controller: sController,
              decoration: InputDecoration(labelText: 'Subject'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('flashcards').add({
                'userId': userId,
                'question': qController.text,
                'answer': aController.text,
                'subject': sController.text,
                'timestamp': DateTime.now(),
              });
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddHomeworkDialog(BuildContext context) {
    final tController = TextEditingController();
    final nController = TextEditingController();
    DateTime? dueDate;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Homework'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: nController,
                decoration: InputDecoration(labelText: 'Notes'),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    dueDate == null
                        ? 'Pick Due Date'
                        : 'Due: \\${dueDate!.month}/\\${dueDate!.day}/\\${dueDate!.year}',
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(Duration(days: 365)),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) setState(() => dueDate = picked);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dueDate == null) return;
                await FirebaseFirestore.instance.collection('homework').add({
                  'userId': userId,
                  'title': tController.text,
                  'notes': nController.text,
                  'dueDate': dueDate,
                  'isCompleted': false,
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllHomeworkComplete() async {
    final homeworkCol = FirebaseFirestore.instance.collection('homework');
    final snapshot = await homeworkCol.where('userId', isEqualTo: userId).get();
    for (var doc in snapshot.docs) {
      await homeworkCol.doc(doc.id).update({'isCompleted': true});
    }
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('All homework marked as complete')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Helper'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Flashcards', icon: Icon(Icons.style)),
            Tab(text: 'Homework', icon: Icon(Icons.assignment)),
          ],
        ),
        actions: [
          if (_currentTab == 1)
            IconButton(
              icon: Icon(Icons.done_all),
              tooltip: 'Mark All as Complete',
              onPressed: _markAllHomeworkComplete,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _currentTab == 0
                    ? 'Search flashcards...'
                    : 'Search homework...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FlashcardsTab(userId: userId, searchQuery: _searchQuery),
                _HomeworkTab(userId: userId, searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: _currentTab == 0 ? 'Add Flashcard' : 'Add Homework',
        child: Icon(_currentTab == 0 ? Icons.add : Icons.assignment_add),
      ),
    );
  }
}

class _FlashcardsTab extends StatelessWidget {
  final String userId;
  final String searchQuery;
  const _FlashcardsTab({required this.userId, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final flashcardCol = FirebaseFirestore.instance.collection('flashcards');
    return StreamBuilder<QuerySnapshot>(
      stream: flashcardCol
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final q = data['question']?.toString().toLowerCase() ?? '';
          final a = data['answer']?.toString().toLowerCase() ?? '';
          final s = data['subject']?.toString().toLowerCase() ?? '';
          return searchQuery.isEmpty ||
              q.contains(searchQuery.toLowerCase()) ||
              a.contains(searchQuery.toLowerCase()) ||
              s.contains(searchQuery.toLowerCase());
        }).toList();
        if (docs.isEmpty) {
          return const Center(child: Text('No flashcards yet.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final question = data['question'] ?? '';
            final answer = data['answer'] ?? '';
            final subject = data['subject'] ?? '';
            return Dismissible(
              key: ValueKey(docs[index].id),
              background: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 20),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              secondaryBackground: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              onDismissed: (_) async {
                await flashcardCol.doc(docs[index].id).delete();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Flashcard deleted')));
              },
              child: GestureDetector(
                onTap: () => _showEditFlashcardDialog(
                  context,
                  docs[index].id,
                  data,
                  flashcardCol,
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  elevation: 3,
                  child: ExpansionTile(
                    leading: Icon(
                      Icons.style,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      question,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: subject.isNotEmpty
                        ? Text(
                            subject,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          )
                        : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Answer: $answer',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditFlashcardDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    CollectionReference flashcardCol,
  ) {
    final qController = TextEditingController(text: data['question'] ?? '');
    final aController = TextEditingController(text: data['answer'] ?? '');
    final sController = TextEditingController(text: data['subject'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qController,
              decoration: InputDecoration(labelText: 'Question'),
            ),
            TextField(
              controller: aController,
              decoration: InputDecoration(labelText: 'Answer'),
            ),
            TextField(
              controller: sController,
              decoration: InputDecoration(labelText: 'Subject'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await flashcardCol.doc(docId).update({
                'question': qController.text,
                'answer': aController.text,
                'subject': sController.text,
              });
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _HomeworkTab extends StatelessWidget {
  final String userId;
  final String searchQuery;
  const _HomeworkTab({required this.userId, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final homeworkCol = FirebaseFirestore.instance.collection('homework');
    return StreamBuilder<QuerySnapshot>(
      stream: homeworkCol
          .where('userId', isEqualTo: userId)
          .orderBy('dueDate')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final t = data['title']?.toString().toLowerCase() ?? '';
          final n = data['notes']?.toString().toLowerCase() ?? '';
          return searchQuery.isEmpty ||
              t.contains(searchQuery.toLowerCase()) ||
              n.contains(searchQuery.toLowerCase());
        }).toList();
        if (docs.isEmpty) return const Center(child: Text('No homework yet.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final dueDate = (data['dueDate'] as Timestamp).toDate();
            final isCompleted = data['isCompleted'] ?? false;
            final notes = data['notes'] ?? '';
            final daysLeft = dueDate.difference(DateTime.now()).inDays;
            final overdue = !isCompleted && dueDate.isBefore(DateTime.now());
            final dueSoon = !isCompleted && daysLeft <= 2 && daysLeft >= 0;
            final reminder = data['reminder'] ?? false;
            return Dismissible(
              key: ValueKey(docs[index].id),
              background: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 20),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              secondaryBackground: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              onDismissed: (_) async {
                await homeworkCol.doc(docs[index].id).delete();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Homework deleted')));
              },
              child: GestureDetector(
                onTap: () => _showEditHomeworkDialog(
                  context,
                  docs[index].id,
                  data,
                  homeworkCol,
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  color: overdue
                      ? Theme.of(
                          context,
                        ).colorScheme.errorContainer.withOpacity(0.1)
                      : dueSoon
                      ? Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer.withOpacity(0.1)
                      : null,
                  elevation: 3,
                  child: ListTile(
                    leading: Icon(
                      Icons.assignment,
                      color: overdue
                          ? Theme.of(context).colorScheme.error
                          : dueSoon
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.secondary,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                        ),
                        if (overdue)
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Overdue',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onError,
                                  ),
                            ),
                          )
                        else if (dueSoon)
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Due Soon',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onTertiary,
                                  ),
                            ),
                          )
                        else if (!isCompleted)
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$daysLeft days left',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondary,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Due: ${dueDate.month}/${dueDate.day}'),
                        if (notes.isNotEmpty) Text(notes),
                        Row(
                          children: [
                            Switch(
                              value: reminder,
                              onChanged: (val) async {
                                await homeworkCol.doc(docs[index].id).update({
                                  'reminder': val,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      val ? 'Reminder set' : 'Reminder removed',
                                    ),
                                  ),
                                );
                              },
                            ),
                            Text('Reminder'),
                          ],
                        ),
                      ],
                    ),
                    trailing: Checkbox(
                      value: isCompleted,
                      onChanged: (val) {
                        homeworkCol.doc(docs[index].id).update({
                          'isCompleted': val,
                        });
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditHomeworkDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    CollectionReference homeworkCol,
  ) {
    final tController = TextEditingController(text: data['title'] ?? '');
    final nController = TextEditingController(text: data['notes'] ?? '');
    DateTime? dueDate = (data['dueDate'] as Timestamp).toDate();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Homework'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: nController,
                decoration: InputDecoration(labelText: 'Notes'),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    dueDate == null
                        ? 'Pick Due Date'
                        : 'Due: \\${dueDate!.month}/\\${dueDate!.day}/\\${dueDate!.year}',
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(Duration(days: 365)),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (picked != null) setState(() => dueDate = picked);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dueDate == null) return;
                await homeworkCol.doc(docId).update({
                  'title': tController.text,
                  'notes': nController.text,
                  'dueDate': dueDate,
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
