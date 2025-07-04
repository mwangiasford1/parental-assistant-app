// features/schedule/schedule_screen.dart
import 'package:flutter/material.dart';
import '../../features/tasks/task_model.dart';
import '../../services/task_storage.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TaskStorage _storage = TaskStorage();

  @override
  void initState() {
    super.initState();
    _storage.generateTodayRecurringTasks();
  }

  void _addTask(String title, TimeOfDay time, RecurrenceType? recurrence) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final newTask = Task(
      id: '', // Firestore will assign the ID
      title: title,
      time: dateTime,
      recurrence: recurrence,
    );
    _storage.addTask(newTask);
  }

  void _showTaskDialog() async {
    String newTitle = '';
    TimeOfDay? newTime;
    RecurrenceType? newRecurrence;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(onChanged: (val) => newTitle = val, decoration: const InputDecoration(labelText: 'Task')),
            ElevatedButton(
              onPressed: () async {
                newTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              },
              child: const Text('Pick Time'),
            ),
            DropdownButtonFormField<RecurrenceType>(
              value: newRecurrence,
              decoration: const InputDecoration(labelText: 'Recurrence'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: RecurrenceType.daily, child: Text('Daily')),
                DropdownMenuItem(value: RecurrenceType.weekly, child: Text('Weekly')),
                DropdownMenuItem(value: RecurrenceType.custom, child: Text('Custom')),
              ],
              onChanged: (val) => newRecurrence = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (newTitle.isNotEmpty && newTime != null) {
                _addTask(newTitle, newTime!, newRecurrence);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Schedule')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTaskDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _storage.streamTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks yet.'));
          }
          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (_, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.title),
                subtitle: Text('${task.time.hour.toString().padLeft(2, '0')}:${task.time.minute.toString().padLeft(2, '0')}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _storage.deleteTask(task.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
