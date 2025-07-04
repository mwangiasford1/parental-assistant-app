// features/rewards/rewards_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Reward {
  final String name;
  final int cost;
  const Reward(this.name, this.cost);
}

const List<Reward> availableRewards = [
  Reward('Extra Screen Time', 20),
  Reward('Ice Cream', 15),
  Reward('Stay Up Late', 25),
];

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  // Replace global doc with per-user points
  final String userId = 'demoUser'; // TODO: Replace with actual auth user
  late final DocumentReference userDoc;
  CollectionReference get activityCol => FirebaseFirestore.instance.collection('activities');
  bool isParent = true; // TODO: Replace with actual user role check
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  String _activityType = 'chore';

  @override
  void initState() {
    super.initState();
    userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
  }

  @override
  void dispose() {
    _descController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _addPoints(int amount) async {
    await userDoc.set({'points': FieldValue.increment(amount)}, SetOptions(merge: true));
    await activityCol.add({
      'userId': userId,
      'type': 'custom',
      'description': 'Points added',
      'points': amount,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _redeemReward(Reward reward, int currentPoints) async {
    if (currentPoints >= reward.cost) {
      await userDoc.update({
        'points': currentPoints - reward.cost,
        'redeemedRewards': FieldValue.arrayUnion([reward.name]),
      });
      await activityCol.add({
        'userId': userId,
        'type': 'redeem',
        'description': 'Redeemed: ${reward.name}',
        'points': -reward.cost,
        'timestamp': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redeemed: ${reward.name}!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough points to redeem.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: userDoc.snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final points = data?['points'] ?? 0;
                // Find the next available reward
                final nextReward = availableRewards.where((r) => r.cost > points).fold<Reward?>(null, (prev, r) {
                  if (prev == null) return r;
                  return r.cost < prev.cost ? r : prev;
                });
                final progress = nextReward != null ? (points / nextReward.cost).clamp(0.0, 1.0) : 1.0;
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Text('Points: $points', style: const TextStyle(fontSize: 24)),
                    if (nextReward != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(value: progress, minHeight: 10),
                            const SizedBox(height: 4),
                            Text('Progress to next reward: ${nextReward.name} ($points/${nextReward.cost})'),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: availableRewards.length,
                        itemBuilder: (context, index) {
                          final reward = availableRewards[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
                            child: ListTile(
                              title: Text(reward.name),
                              subtitle: Text('Cost: ${reward.cost} points'),
                              trailing: ElevatedButton(
                                onPressed: points >= reward.cost
                                    ? () => _redeemReward(reward, points)
                                    : null,
                                child: const Text('Redeem'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 120,
            child: StreamBuilder<QuerySnapshot>(
              stream: activityCol
                  .where('userId', isEqualTo: userId)
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No activity yet.'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final desc = data['description'] ?? '';
                    final pts = data['points'] ?? 0;
                    final ts = (data['timestamp'] as Timestamp).toDate();
                    return ListTile(
                      leading: Icon(pts > 0 ? Icons.add : Icons.redeem, color: pts > 0 ? Colors.green : Colors.orange),
                      title: Text(desc),
                      subtitle: Text('${ts.month}/${ts.day} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}'),
                      trailing: Text(pts > 0 ? '+$pts' : '$pts', style: TextStyle(color: pts > 0 ? Colors.green : Colors.orange)),
                    );
                  },
                );
              },
            ),
          ),
          if (isParent) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assign Points', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _activityType,
                        items: const [
                          DropdownMenuItem(value: 'chore', child: Text('Chore')),
                          DropdownMenuItem(value: 'good_behavior', child: Text('Good Behavior')),
                          DropdownMenuItem(value: 'custom', child: Text('Custom')),
                        ],
                        onChanged: (v) => setState(() => _activityType = v ?? 'chore'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _descController,
                          decoration: const InputDecoration(hintText: 'Description'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Pts'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final desc = _descController.text.trim();
                          final pts = int.tryParse(_pointsController.text.trim()) ?? 0;
                          if (desc.isEmpty || pts == 0) return;
                          await userDoc.set({'points': FieldValue.increment(pts)}, SetOptions(merge: true));
                          await activityCol.add({
                            'userId': userId,
                            'type': _activityType,
                            'description': desc,
                            'points': pts,
                            'timestamp': Timestamp.now(),
                          });
                          _descController.clear();
                          _pointsController.clear();
                        },
                        child: const Text('Assign'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _addPoints(5),
            child: const Text('Add 5 Points (Demo)'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 