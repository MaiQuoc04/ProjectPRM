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
    });
  }
}
