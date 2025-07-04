// services/task_storage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/tasks/task_model.dart';

class TaskStorage {
  final _collection = FirebaseFirestore.instance.collection('tasks');

  Stream<List<Task>> streamTasks() {
    return _collection.orderBy('time').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Task.fromFirestore(doc.data(), doc.id)).toList()
    );
  }

  Future<void> addTask(Task task) async {
    await _collection.add(task.toFirestore());
  }

  Future<void> deleteTask(String id) async {
    await _collection.doc(id).delete();
  }

  Future<void> generateTodayRecurringTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final snapshot = await _collection.get();
    final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc.data(), doc.id)).toList();
    for (final task in tasks) {
      if (task.recurrence == RecurrenceType.daily ||
          (task.recurrence == RecurrenceType.weekly && task.time.weekday == today.weekday)) {
        // Check if a task for today with the same title already exists
        final exists = tasks.any((t) =>
          t.title == task.title &&
          t.time.year == today.year &&
          t.time.month == today.month &&
          t.time.day == today.day
        );
        if (!exists) {
          final newTask = Task(
            id: '',
            title: task.title,
            time: DateTime(today.year, today.month, today.day, task.time.hour, task.time.minute),
            recurrence: task.recurrence,
            color: task.color,
          );
          await addTask(newTask);
        }
      }
    }
  }
}
