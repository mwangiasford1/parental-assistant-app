// features/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../schedule/schedule_screen.dart';
import '../rewards/rewards_screen.dart';
import 'settings_screen.dart';
import 'mood_tracker_screen.dart';
import 'homework_helper_screen.dart';
import 'story_music_screen.dart';
import 'shared_calendar_screen.dart';
import 'expense_tracker_screen.dart';
import 'geofencing_screen.dart';
import 'content_filtering_screen.dart';
import 'emergency_sos_screen.dart';
import 'password_backup_screen.dart';
import 'profile_screen.dart';
import '../../data/models/user_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/auth_service.dart';
import 'dart:convert';
import '../chat/user_chat_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double fontSize = 16;
  bool isHighContrast = false;

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('No new notifications'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final role = user?.role ?? 'parent';
    // Define allowed features per role
    final List<_FeatureTile> tiles = [
      _FeatureTile(
        icon: Icons.schedule,
        label: 'Schedule',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScheduleScreen()),
          );
        },
      ),
      if (role != 'nanny')
        _FeatureTile(
          icon: Icons.star,
          label: 'Rewards',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RewardsScreen()),
            );
          },
        ),
      _FeatureTile(
        icon: Icons.settings,
        label: 'Settings',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SettingsScreen(user: user)),
          );
        },
      ),
      _FeatureTile(
        icon: Icons.person,
        label: 'Profile',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
          );
        },
      ),
      if (role != 'parent')
        _FeatureTile(
          icon: Icons.emoji_emotions,
          label: 'Mood Tracker',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
            );
          },
        ),
      _FeatureTile(
        icon: Icons.school,
        label: 'Homework Helper',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomeworkHelperScreen()),
          );
        },
      ),
      _FeatureTile(
        icon: Icons.library_music,
        label: 'Story & Music',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StoryMusicScreen()),
          );
        },
      ),
      _FeatureTile(
        icon: Icons.calendar_today,
        label: 'Shared Calendar',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SharedCalendarScreen()),
          );
        },
      ),
      if (role == 'parent')
        _FeatureTile(
          icon: Icons.attach_money,
          label: 'Expense Tracker',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseTrackerScreen()),
            );
          },
        ),
      if (role == 'parent')
        _FeatureTile(
          icon: Icons.location_on,
          label: 'Geofencing Alerts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeofencingScreen()),
            );
          },
        ),
      if (role == 'parent')
        _FeatureTile(
          icon: Icons.filter_alt,
          label: 'Content Filtering',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContentFilteringScreen()),
            );
          },
        ),
      if (role == 'parent')
        _FeatureTile(
          icon: Icons.lock,
          label: 'Password Backup',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PasswordBackupScreen()),
            );
          },
        ),
      _FeatureTile(
        icon: Icons.warning,
        label: 'Emergency SOS',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencySOSScreen()),
          );
        },
      ),
    ];
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildLeftDrawer(context),
      // endDrawer removed
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Parental Assistant'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: _showNotifications,
          ),
          if (user != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('recipientId', isEqualTo: user.uid)
                  .where('read', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final unread = snapshot.hasData ? snapshot.data!.size : 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble),
                      tooltip: 'Messages',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserChatEntryScreen(currentUser: user),
                          ),
                        );
                      },
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.warning),
            tooltip: 'SOS',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencySOSScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: tiles,
        ),
      ),
    );
  }

  Widget _buildLeftDrawer(BuildContext context) {
    // You can expand this as needed for your primary features
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.family_restroom,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Parental Assistant',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context), // Close drawer
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(user: widget.user),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text('Logout', style: TextStyle(color: Colors.red.shade700)),
            onTap: () async {
              await AuthService.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  // _buildRightDrawer and related code removed

  Future<void> _backupUserData(BuildContext context, String uid) async {
    try {
      if (!(await Permission.storage.request().isGranted)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied.')),
        );
        return;
      }
      final firestore = FirebaseFirestore.instance;
      // Fetch user document
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) throw Exception('User data not found');
      final userData = userDoc.data();
      // Fetch all user-specific collections
      Future<List<Map<String, dynamic>>> fetchCol(
        String col, [
        String field = 'userId',
      ]) async {
        final snap = await firestore
            .collection(col)
            .where(field, isEqualTo: uid)
            .get();
        return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
      }

      // For events, include those where user is participant or creator
      final eventsSnap = await firestore
          .collection('events')
          .where('participants', arrayContains: uid)
          .get();
      final createdEventsSnap = await firestore
          .collection('events')
          .where('createdBy', isEqualTo: uid)
          .get();
      final events = [
        ...eventsSnap.docs,
        ...createdEventsSnap.docs.where(
          (d) => !eventsSnap.docs.any((e) => e.id == d.id),
        ),
      ].map((d) => {...d.data(), 'id': d.id}).toList();
      final backup = {
        'user': userData,
        'activities': await fetchCol('activities'),
        'expenses': await fetchCol('expenses'),
        'tasks': await fetchCol('tasks'),
        'flashcards': await fetchCol('flashcards'),
        'homework': await fetchCol('homework'),
        'moods': await fetchCol('moods'),
        'events': events,
        'geofences': await fetchCol('geofences'),
        'geofence_events': await fetchCol('geofence_events'),
        'sos_alerts': await fetchCol('sos_alerts'),
        'user_content_settings': await fetchCol(
          'user_content_settings',
          'userId',
        ),
      };
      final jsonStr = jsonEncode(backup);
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/parental_assistant_backup_$uid.json';
      final file = File(filePath);
      await file.writeAsString(jsonStr);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup As',
        fileName: 'parental_assistant_backup_$uid.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        await file.copy(result);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup saved!')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup cancelled.')));
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup Failed'),
          content: Text('Error: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _restoreUserData(BuildContext context, String uid) async {
    try {
      if (!(await Permission.storage.request().isGranted)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied.')),
        );
        return;
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Restore cancelled.')));
        return;
      }
      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr);
      final firestore = FirebaseFirestore.instance;
      // Restore user document
      if (data['user'] != null) {
        await firestore
            .collection('users')
            .doc(uid)
            .set(
              Map<String, dynamic>.from(data['user']),
              SetOptions(merge: true),
            );
      }
      // Helper to restore a collection
      Future<void> restoreCol(String col, List<dynamic>? docs) async {
        if (docs == null) return;
        for (final doc in docs) {
          final map = Map<String, dynamic>.from(doc);
          final id = map.remove('id');
          if (id != null) {
            await firestore
                .collection(col)
                .doc(id)
                .set(map, SetOptions(merge: true));
          } else {
            await firestore.collection(col).add(map);
          }
        }
      }

      await restoreCol('activities', data['activities']);
      await restoreCol('expenses', data['expenses']);
      await restoreCol('tasks', data['tasks']);
      await restoreCol('flashcards', data['flashcards']);
      await restoreCol('homework', data['homework']);
      await restoreCol('moods', data['moods']);
      await restoreCol('events', data['events']);
      await restoreCol('geofences', data['geofences']);
      await restoreCol('geofence_events', data['geofence_events']);
      await restoreCol('sos_alerts', data['sos_alerts']);
      await restoreCol('user_content_settings', data['user_content_settings']);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account restored!')));
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Failed'),
          content: Text('Error: ${e.toString()}'),
        ),
      );
    }
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _FeatureTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
