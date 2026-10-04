// English Comment: Syncs AI chat history to the Supabase `ai_chats` table so chats follow the user across devices.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_session.dart';

class ChatCloudSync {
  static const String _table = 'ai_chats';

  static SupabaseClient get _db => Supabase.instance.client;

  // Null when logged out, or when Supabase could not start (offline startup).
  static String? get userId {
    try {
      return _db.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAll() async {
    final uid = userId;
    if (uid == null) return [];
    final rows = await _db
        .from(_table)
        .select('id,title,messages,updated_at,deleted')
        .eq('user_id', uid)
        .order('updated_at', ascending: false)
        .limit(300);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> upsert(List<ChatSession> sessions) async {
    final uid = userId;
    if (uid == null || sessions.isEmpty) return;
    await _db
        .from(_table)
        .upsert(sessions.map((s) => s.toCloudRow(uid)).toList(), onConflict: 'user_id,id');
  }

  // Deleted chats stay as small "deleted" rows so other devices know to remove them too.
  static Future<void> markDeleted(List<String> ids) async {
    final uid = userId;
    if (uid == null || ids.isEmpty) return;
    await _db
        .from(_table)
        .update({
          'deleted': true,
          'messages': <dynamic>[],
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        })
        .eq('user_id', uid)
        .inFilter('id', ids);
  }

  static Future<void> markAllDeleted() async {
    final uid = userId;
    if (uid == null) return;
    await _db
        .from(_table)
        .update({
          'deleted': true,
          'messages': <dynamic>[],
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        })
        .eq('user_id', uid)
        .eq('deleted', false);
  }
}
