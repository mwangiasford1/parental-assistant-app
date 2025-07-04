// features/home/emergency_sos_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/sos_alert_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  final String userId = 'demoUser'; // TODO: Replace with actual auth user
  CollectionReference get sosCol =>
      FirebaseFirestore.instance.collection('sos_alerts');
  bool sending = false;

  Future<void> _sendSOS() async {
    setState(() {
      sending = true;
    });
    double? latitude;
    double? longitude;
    String? errorMsg;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        errorMsg = 'Location permission denied.';
      } else {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latitude = pos.latitude;
        longitude = pos.longitude;
      }
    } catch (e) {
      errorMsg = 'Could not get location: $e';
    }
    await sosCol.add({
      'userId': userId,
      'timestamp': Timestamp.now(),
      'latitude': latitude,
      'longitude': longitude,
      'status': 'active',
      'message': 'Help! I need assistance.',
    });
    setState(() {
      sending = false;
    });
    if (mounted) {
      if (errorMsg != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('SOS sent, but: $errorMsg')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('SOS alert sent!')));
      }
    }
  }

  void _confirmAndSendSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Emergency SOS?'),
        content: const Text(
          'Are you sure you want to send an emergency alert?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendSOS();
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearSOSLog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear SOS Log'),
        content: const Text(
          'Are you sure you want to delete all your SOS alerts? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final query = await sosCol.where('userId', isEqualTo: userId).get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('SOS log cleared.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing SOS log: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                onPressed: sending ? null : _confirmAndSendSOS,
                child: const Text(
                  '🚨 EMERGENCY SOS 🚨',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const Text(
              'SOS Alert Map',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: sosCol
                    .orderBy('timestamp', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  final alerts = docs
                      .map(
                        (d) => SOSAlertModel.fromMap(
                          d.data() as Map<String, dynamic>,
                          d.id,
                        ),
                      )
                      .where((a) => a.latitude != null && a.longitude != null)
                      .toList();
                  if (alerts.isEmpty) {
                    return const Center(child: Text('No SOS locations yet.'));
                  }
                  // Basic clustering: group alerts within 0.001 lat/lng
                  final List<List<SOSAlertModel>> clusters = [];
                  for (final alert in alerts) {
                    bool added = false;
                    for (final cluster in clusters) {
                      final first = cluster.first;
                      if ((alert.latitude! - first.latitude!).abs() < 0.001 &&
                          (alert.longitude! - first.longitude!).abs() < 0.001) {
                        cluster.add(alert);
                        added = true;
                        break;
                      }
                    }
                    if (!added) clusters.add([alert]);
                  }
                  final latest = alerts.first;
                  return FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        latest.latitude!,
                        latest.longitude!,
                      ),
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.parental_assistant',
                      ),
                      MarkerLayer(
                        markers: clusters.map((cluster) {
                          final a = cluster.first;
                          return Marker(
                            width: 44,
                            height: 44,
                            point: LatLng(a.latitude!, a.longitude!),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                      cluster.length > 1
                                          ? '${cluster.length} SOS Alerts'
                                          : (a.status == 'active'
                                                ? 'Active SOS'
                                                : 'Resolved SOS'),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: cluster
                                            .map(
                                              (alert) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8.0,
                                                ),
                                                child: Text(
                                                  'User: ${alert.userId}\nTime: ${alert.timestamp.month}/${alert.timestamp.day} ${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}\nStatus: ${alert.status}\nMessage: ${alert.message ?? ''}\n',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color:
                                        cluster.any((c) => c.status == 'active')
                                        ? Colors.red
                                        : Colors.green,
                                    size: 36,
                                  ),
                                  if (cluster.length > 1)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: Text(
                                        '${cluster.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
            const Text(
              'SOS Alert Log',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Clear SOS Log'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _clearSOSLog,
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: sosCol
                    .where('userId', isEqualTo: userId)
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No SOS alerts yet.'));
                  }
                  final alerts = docs
                      .map(
                        (d) => SOSAlertModel.fromMap(
                          d.data() as Map<String, dynamic>,
                          d.id,
                        ),
                      )
                      .toList();
                  return ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final a = alerts[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            a.status == 'active'
                                ? Icons.warning
                                : Icons.check_circle,
                            color: a.status == 'active'
                                ? Colors.red
                                : Colors.green,
                          ),
                          title: Text(
                            '${a.status == 'active' ? 'Active' : 'Resolved'} - ${a.timestamp.month}/${a.timestamp.day} ${a.timestamp.hour}:${a.timestamp.minute.toString().padLeft(2, '0')}',
                          ),
                          subtitle: a.message != null ? Text(a.message!) : null,
                          trailing: a.status == 'active'
                              ? TextButton(
                                  onPressed: () => sosCol.doc(a.id).update({
                                    'status': 'resolved',
                                  }),
                                  child: const Text('Mark Resolved'),
                                )
                              : null,
                        ),
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
