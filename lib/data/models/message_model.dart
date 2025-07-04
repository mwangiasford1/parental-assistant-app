import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final Timestamp timestamp;
  final String? type; // e.g., 'text', 'image', etc.
  final bool read;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.timestamp,
    this.type,
    this.read = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String id) {
    return MessageModel(
      id: id,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      text: json['text'] as String,
      timestamp: json['timestamp'] as Timestamp,
      type: json['type'] as String?,
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
      'timestamp': timestamp,
      'type': type,
      'read': read,
    };
  }
}
