import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/message_model.dart';
import '../../services/message_service.dart';

class UserChatScreen extends StatefulWidget {
  final UserModel currentUser;
  final UserModel otherUser;
  const UserChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    MessageService.sendMessage(
      senderId: widget.currentUser.uid,
      recipientId: widget.otherUser.uid,
      text: text,
    );
    _controller.clear();
  }

  @override
  void initState() {
    super.initState();
    // Mark messages as read when chat is opened
    MessageService.markMessagesAsRead(
      senderId: widget.otherUser.uid,
      recipientId: widget.currentUser.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  widget.otherUser.profileImageUrl != null &&
                      widget.otherUser.profileImageUrl!.isNotEmpty
                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                  : null,
              child:
                  widget.otherUser.profileImageUrl == null ||
                      widget.otherUser.profileImageUrl!.isEmpty
                  ? Icon(_getRoleIcon(widget.otherUser.role))
                  : null,
            ),
            const SizedBox(width: 12),
            Text(widget.otherUser.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: MessageService.getMessages(
                userId1: widget.currentUser.uid,
                userId2: widget.otherUser.uid,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == widget.currentUser.uid;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg.text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
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
