import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/message_model.dart';

class MessageService {
  static final _firestore = FirebaseFirestore.instance;
  static final _messagesRef = _firestore.collection('messages');

  // Send a message
  static Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String text,
    String type = 'text',
  }) async {
    final message = MessageModel(
      id: '', // Firestore will generate the ID
      senderId: senderId,
      recipientId: recipientId,
      text: text,
      timestamp: Timestamp.now(),
      type: type,
      read: false,
    );
    await _messagesRef.add(message.toJson());
  }

  // Mark all messages from sender to recipient as read
  static Future<void> markMessagesAsRead({
    required String senderId,
    required String recipientId,
  }) async {
    final query = await _messagesRef
        .where('senderId', isEqualTo: senderId)
        .where('recipientId', isEqualTo: recipientId)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in query.docs) {
      await doc.reference.update({'read': true});
    }
  }

  // Stream messages between two users, ordered by timestamp
  static Stream<List<MessageModel>> getMessages({
    required String userId1,
    required String userId2,
  }) {
    return _messagesRef
        .where('senderId', whereIn: [userId1, userId2])
        .where('recipientId', whereIn: [userId1, userId2])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
              .where(
                (msg) =>
                    (msg.senderId == userId1 && msg.recipientId == userId2) ||
                    (msg.senderId == userId2 && msg.recipientId == userId1),
              )
              .toList(),
        );
  }
}
