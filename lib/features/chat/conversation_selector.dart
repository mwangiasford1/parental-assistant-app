// features/chat/conversation_selector.dart
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationSelector extends StatelessWidget {
  final List<UserModel> users;
  final UserModel currentUser;
  final void Function(UserModel) onUserSelected;

  const ConversationSelector({
    super.key,
    required this.users,
    required this.currentUser,
    required this.onUserSelected,
  });

  Stream<int> _unreadCountStream(String otherUserId) {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: otherUserId)
        .where('recipientId', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  @override
  Widget build(BuildContext context) {
    final otherUsers = users.where((u) => u.uid != currentUser.uid).toList();
    return ListView.builder(
      itemCount: otherUsers.length,
      itemBuilder: (context, index) {
        final user = otherUsers[index];
        return StreamBuilder<int>(
          stream: _unreadCountStream(user.uid),
          builder: (context, snapshot) {
            final unread = snapshot.data ?? 0;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    user.profileImageUrl != null &&
                        user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child:
                    user.profileImageUrl == null ||
                        user.profileImageUrl!.isEmpty
                    ? Icon(_getRoleIcon(user.role))
                    : null,
              ),
              title: Text(user.name),
              subtitle: Text(user.role),
              trailing: unread > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () => onUserSelected(user),
            );
          },
        );
      },
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'child':
        return Icons.child_care;
      case 'nanny':
        return Icons.volunteer_activism;
      case 'parent':
      default:
        return Icons.family_restroom;
    }
  }
}
