// features/home/geofencing_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/geofence_model.dart';
import '../../services/auth_service.dart';

class GeofencingScreen extends StatefulWidget {
  const GeofencingScreen({super.key});

  @override
  State<GeofencingScreen> createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  String get userId => AuthService.currentUserId ?? 'demoUser';
  CollectionReference get fenceCol => FirebaseFirestore.instance.collection('geofences');
  CollectionReference get eventCol => FirebaseFirestore.instance.collection('geofence_events');

  void _showFenceDialog({GeofenceModel? fence}) {
    final labelController = TextEditingController(text: fence?.label ?? '');
    final latController = TextEditingController(text: fence?.latitude.toString() ?? '');
    final lngController = TextEditingController(text: fence?.longitude.toString() ?? '');
    final radiusController = TextEditingController(text: fence?.radius.toString() ?? '200');
    bool enabled = fence?.enabled ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fence == null ? 'Add Zone' : 'Edit Zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: latController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              TextField(
                controller: lngController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
              TextField(
                controller: radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Radius (meters)'),
              ),
              SwitchListTile(
                value: enabled,
                onChanged: (v) => setState(() => enabled = v),
                title: const Text('Enabled'),
              ),
            ],
          ),
        ),
        actions: [
          if (fence != null)
            TextButton(
              onPressed: () async {
                await fenceCol.doc(fence.id).delete();
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text.trim()) ?? 0;
              final lng = double.tryParse(lngController.text.trim()) ?? 0;
              final rad = double.tryParse(radiusController.text.trim()) ?? 200;
              if (labelController.text.trim().isEmpty) return;
              final newFence = GeofenceModel(
                id: fence?.id ?? '',
                userId: userId,
                label: labelController.text.trim(),
                latitude: lat,
                longitude: lng,
                radius: rad,
                enabled: enabled,
              );
              if (fence == null) {
                await fenceCol.add(newFence.toMap());
              } else {
                await fenceCol.doc(fence.id).update(newFence.toMap());
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
        title: const Text('Geofencing Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: () => _showFenceDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fenceCol.where('userId', isEqualTo: userId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No zones yet.'));
                final fences = docs.map((d) => GeofenceModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
                return ListView.builder(
                  itemCount: fences.length,
                  itemBuilder: (context, index) {
                    final f = fences[index];
                    return ListTile(
                      title: Text('${f.label} (${f.radius.toInt()}m)'),
                      subtitle: Text('Lat: ${f.latitude}, Lng: ${f.longitude}'),
                      trailing: Switch(
                        value: f.enabled,
                        onChanged: (v) => fenceCol.doc(f.id).update({'enabled': v}),
                      ),
                      onTap: () => _showFenceDialog(fence: f),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Recent Events', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 120,
            child: StreamBuilder<QuerySnapshot>(
              stream: eventCol
                  .where('userId', isEqualTo: userId)
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No events yet.'));
                // Fix: Use a fallback if GeofenceEventModel is undefined or import it if missing.
                final events = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  // If GeofenceEventModel is not defined, use a fallback map
                  // Replace this with your actual model if available
                  return data.containsKey('eventType') && data.containsKey('timestamp')
                      ? {
                          'eventType': data['eventType'],
                          'timestamp': (data['timestamp'] as Timestamp).toDate(),
                        }
                      : null;
                }).where((e) => e != null).toList();
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final e = events[index];
                    return ListTile(
                      leading: Icon(e?['eventType'] == 'enter' ? Icons.login : Icons.logout, color: e?['eventType'] == 'enter' ? Colors.green : Colors.red),
                      title: Text('${e?['eventType'] == 'enter' ? 'Entered' : 'Exited'} zone'),
                      subtitle: e?['timestamp'] != null
                          ? Text('${e?['timestamp'].month}/${e?['timestamp'].day} ${e?['timestamp'].hour}:${e?['timestamp'].minute.toString().padLeft(2, '0')}')
                          : null,
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