// English Comment: Model class for managing chat sessions, history serialization, and local storage.
import 'package:image_picker/image_picker.dart';

class ChatSession {
  final String id;
  String title;
  final List<Map<String, dynamic>> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) {
          return {
            'sender': m['sender'],
            'text': m['text'],
            'imagePath': m['image'] != null ? (m['image'] as XFile).path : null,
            'isError': m['isError'] ?? false,
          };
        }).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> loadedMessages = [];
    if (json['messages'] != null) {
      for (var msg in json['messages']) {
        loadedMessages.add({
          'sender': msg['sender'],
          'text': msg['text'],
          'image': msg['imagePath'] != null ? XFile(msg['imagePath']) : null,
          'isError': msg['isError'] ?? false,
        });
      }
    }
    return ChatSession(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'New Chat',
      messages: loadedMessages,
    );
  }
}