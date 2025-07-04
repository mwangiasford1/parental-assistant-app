// features/home/shared_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/event_model.dart';

class SharedCalendarScreen extends StatefulWidget {
  const SharedCalendarScreen({super.key});

  @override
  State<SharedCalendarScreen> createState() => _SharedCalendarScreenState();
}

class _SharedCalendarScreenState extends State<SharedCalendarScreen> {
  final String userId = 'demoUser'; // TODO: Replace with actual auth user
  final List<String> allUsers = ['demoUser', 'parent1', 'child1']; // TODO: Fetch from Firestore

  CollectionReference get eventCol => FirebaseFirestore.instance.collection('events');

  void _showEventDialog({EventModel? event}) {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descController = TextEditingController(text: event?.description ?? '');
    DateTime? start = event?.startTime ?? DateTime.now();
    DateTime? end = event?.endTime ?? DateTime.now().add(const Duration(hours: 1));
    List<String> participants = event?.participants.toList() ?? [userId];
    bool isRecurring = event?.isRecurring ?? false;
    String recurrenceRule = event?.recurrenceRule ?? 'none';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event == null ? 'Add Event' : 'Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Start:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: start ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(start ?? DateTime.now()),
                        );
                        if (time != null) {
                          setState(() {
                            start = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                    child: Text('${(start ?? DateTime.now()).month}/${(start ?? DateTime.now()).day} ${(start ?? DateTime.now()).hour}:${(start ?? DateTime.now()).minute.toString().padLeft(2, '0')}'),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('End:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: end ?? DateTime.now().add(const Duration(hours: 1)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(end ?? DateTime.now().add(const Duration(hours: 1))),
                        );
                        if (time != null) {
                          setState(() {
                            end = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                    child: Text('${(end ?? DateTime.now().add(const Duration(hours: 1))).month}/${(end ?? DateTime.now().add(const Duration(hours: 1))).day} ${(end ?? DateTime.now().add(const Duration(hours: 1))).hour}:${(end ?? DateTime.now().add(const Duration(hours: 1))).minute.toString().padLeft(2, '0')}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: allUsers.map((u) => FilterChip(
                  label: Text(u),
                  selected: participants.contains(u),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        participants.add(u);
                      } else {
                        participants.remove(u);
                      }
                    });
                  },
                )).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: isRecurring,
                    onChanged: (v) => setState(() => isRecurring = v ?? false),
                  ),
                  const Text('Recurring'),
                  const SizedBox(width: 8),
                  if (isRecurring)
                    DropdownButton<String>(
                      value: recurrenceRule,
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('None')),
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (v) => setState(() => recurrenceRule = v ?? 'none'),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (event != null)
            TextButton(
              onPressed: () async {
                await eventCol.doc(event.id).delete();
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () async {
              final newEvent = EventModel(
                id: event?.id ?? '',
                title: titleController.text.trim(),
                description: descController.text.trim(),
                startTime: start!,
                endTime: end!,
                participants: participants,
                createdBy: userId,
                isRecurring: isRecurring,
                recurrenceRule: isRecurring ? recurrenceRule : null,
              );
              if (event == null) {
                await eventCol.add(newEvent.toMap());
              } else {
                await eventCol.doc(event.id).update(newEvent.toMap());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEventDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: eventCol
            .where('participants', arrayContains: userId)
            .orderBy('startTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No events yet.'));
          final events = docs.map((d) => EventModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
          return ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = events[index];
              return ListTile(
                title: Text(e.title),
                subtitle: e.startTime != null
                    ? Text('${e.startTime.month}/${e.startTime.day} ${e.startTime.hour}:${e.startTime.minute.toString().padLeft(2, '0')}')
                    : const Text('No start time'),
                trailing: e.isRecurring ? const Icon(Icons.repeat) : null,
                onTap: () => _showEventDialog(event: e),
              );
            },
          );
        },
      ),
    );
  }
} 