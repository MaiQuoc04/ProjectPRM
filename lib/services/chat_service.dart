import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Lấy danh sách Matches
  Future<List<Map<String, dynamic>>> getMatches() async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Chưa đăng nhập');

    // Lấy danh sách các matches của mình
    final response = await _supabase
        .from('matches')
        .select('id, user1_id, user2_id')
        .or('user1_id.eq.$myId,user2_id.eq.$myId');

    final matches = List<Map<String, dynamic>>.from(response);

    // Lấy thông tin profile của đối phương (bao gồm bio và tags cho AI)
    for (var match in matches) {
      final otherUserId = match['user1_id'] == myId ? match['user2_id'] : match['user1_id'];
      final profile = await _supabase
          .from('profiles')
          .select('full_name, avatar_urls, bio, tags')
          .eq('id', otherUserId)
          .maybeSingle();

      match['other_profile'] = profile;

      // Lấy tin nhắn mới nhất và đếm số lượng tin nhắn chưa đọc
      final messages = await _supabase
          .from('messages')
          .select('content, sender_id, is_read, created_at')
          .eq('match_id', match['id'])
          .order('created_at', ascending: false);

      if (messages.isNotEmpty) {
        match['last_message'] = messages.first;
        match['unread_count'] = messages.where((m) => m['sender_id'] != myId && m['is_read'] != true).length;
      } else {
        match['last_message'] = null;
        match['unread_count'] = 0;
      }
    }

    return matches;
  }

  // Lắng nghe tin nhắn realtime
  Stream<List<Map<String, dynamic>>> streamMessages(String matchId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at', ascending: true);
  }

  // Gửi tin nhắn
  Future<void> sendMessage(String matchId, String content, {String type = 'text'}) async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Chưa đăng nhập');

    await _supabase.from('messages').insert({
      'match_id': matchId,
      'sender_id': myId,
      'content': content,
      'message_type': type,
      'is_read': false,
    });
  }

  // Đánh dấu đã đọc tin nhắn của đối phương
  Future<void> markMessagesAsRead(String matchId) async {
    final myId = currentUserId;
    if (myId == null) return;

    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('match_id', matchId)
          .neq('sender_id', myId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Lắng nghe số cuộc hội thoại chưa đọc realtime
  Stream<int> streamUnreadConversationsCount() {
    final myId = currentUserId;
    if (myId == null) return Stream.value(0);

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('is_read', false)
        .map((messages) {
      final unreadMatches = messages
          .where((m) => m['sender_id'] != myId)
          .map((m) => m['match_id'].toString())
          .toSet();
      return unreadMatches.length;
    });
  }
}
