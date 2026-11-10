import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/counselor_thread.dart';

/// Student ↔ Guidance Office chat, used by both sides. Each student has
/// exactly one thread; any counselor can read and reply in it.
abstract class CounselorChatRepository {
  String? get currentUserId;

  /// Returns the student's thread, creating it on first use.
  Future<String> threadIdForStudent(String studentId);

  /// Live list of messages in a thread, oldest first.
  Stream<List<ThreadMessage>> messages(String threadId);

  Future<void> send({required String threadId, required String body});
}

class SupabaseCounselorChatRepository implements CounselorChatRepository {
  SupabaseCounselorChatRepository(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<String> threadIdForStudent(String studentId) async {
    final existing = await _findThread(studentId);
    if (existing != null) return existing;
    try {
      final row = await _client
          .from('counselor_threads')
          .insert({'student_id': studentId})
          .select('id')
          .single();
      return row['id'] as String;
    } on PostgrestException catch (e) {
      // Someone else opened it at the same moment (unique violation).
      if (e.code == '23505') {
        final again = await _findThread(studentId);
        if (again != null) return again;
      }
      rethrow;
    }
  }

  Future<String?> _findThread(String studentId) async {
    final row = await _client
        .from('counselor_threads')
        .select('id')
        .eq('student_id', studentId)
        .maybeSingle();
    return row?['id'] as String?;
  }

  @override
  Stream<List<ThreadMessage>> messages(String threadId) {
    return _client
        .from('counselor_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(ThreadMessage.fromRow).toList());
  }

  @override
  Future<void> send({required String threadId, required String body}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Please log in again.');
    await _client.from('counselor_messages').insert({
      'thread_id': threadId,
      'sender_id': userId,
      'body': body,
    });
  }
}
