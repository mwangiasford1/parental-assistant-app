import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import 'conversation_selector.dart';
import 'user_chat_screen.dart';

class UserChatEntryScreen extends StatelessWidget {
  final UserModel currentUser;
  const UserChatEntryScreen({super.key, required this.currentUser});

  Future<List<UserModel>> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data(),))
        .where((u) => u.uid != currentUser.uid)
        .toList();
  }

  void _startMessage(BuildContext context, List<UserModel> users) async {
    // Show a dialog with the ConversationSelector
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 400,
        child: ConversationSelector(
          users: users,
          currentUser: currentUser,
          onUserSelected: (selectedUser) {
            Navigator.pop(ctx); // Close the selector
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserChatScreen(
                  currentUser: currentUser,
                  otherUser: selectedUser,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _fetchUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final users = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Select Conversation')),
          body: ConversationSelector(
            users: users,
            currentUser: currentUser,
            onUserSelected: (selectedUser) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserChatScreen(
                    currentUser: currentUser,
                    otherUser: selectedUser,
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add_comment),
            label: const Text('Start Message'),
            onPressed: () => _startMessage(context, users),
          ),
        );
      },
    );
  }
}
