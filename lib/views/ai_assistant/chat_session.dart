// English Comment: Model class for managing chat sessions, history serialization, local storage and cloud sync.
import 'package:image_picker/image_picker.dart';

class ChatSession {
  final String id;
  String title;
  final List<Map<String, dynamic>> messages;
  // Milliseconds since epoch of the last change. Used to decide which copy is newer when syncing.
  int updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? (int.tryParse(id) ?? DateTime.now().millisecondsSinceEpoch);

  // Replaces this chat's content with another copy of the same chat.
  void replaceWith(ChatSession other) {
    title = other.title;
    messages
      ..clear()
      ..addAll(other.messages);
    updatedAt = other.updatedAt;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt,
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
    final String id = json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    return ChatSession(
      id: id,
      title: json['title'] ?? 'New Chat',
      messages: loadedMessages,
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
    );
  }

  // Row for the Supabase `ai_chats` table. Images are not uploaded, only text.
  Map<String, dynamic> toCloudRow(String userId) => {
        'user_id': userId,
        'id': id,
        'title': title,
        'messages': messages
            .map((m) => {
                  'sender': m['sender'],
                  'text': m['text'],
                  'isError': m['isError'] ?? false,
                })
            .toList(),
        'updated_at': updatedAt,
        'deleted': false,
      };

  factory ChatSession.fromCloudRow(Map<String, dynamic> row) {
    final List<Map<String, dynamic>> loaded = [];
    final raw = row['messages'];
    if (raw is List) {
      for (final msg in raw) {
        loaded.add({
          'sender': msg['sender'],
          'text': msg['text'],
          'image': null,
          'isError': msg['isError'] ?? false,
        });
      }
    }
    return ChatSession(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? 'New Chat',
      messages: loaded,
      updatedAt: (row['updated_at'] as num?)?.toInt(),
    );
  }
}
