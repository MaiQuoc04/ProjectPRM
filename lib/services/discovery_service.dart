import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoveryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Lấy danh sách profiles chưa quẹt, lọc theo giới tính
  Future<List<Map<String, dynamic>>> getDiscoveryProfiles({String? genderFilter}) async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Chưa đăng nhập');

    // Lấy những người mình đã quẹt
    final mySwipes = await _supabase
        .from('swipes')
        .select('swiped_id')
        .eq('swiper_id', myId);

    final swipedIds = (mySwipes as List).map((s) => s['swiped_id']).toList();
    swipedIds.add(myId); // Tránh hiện chính mình

    // Lấy profiles không nằm trong danh sách đã quẹt
    var query = _supabase
        .from('profiles')
        .select('*')
        .not('id', 'in', swipedIds);

    // Áp dụng bộ lọc giới tính nếu có
    if (genderFilter != null && genderFilter.isNotEmpty) {
      query = query.eq('gender', genderFilter);
    }

    final response = await query.limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  // Ghi nhận Swipe và kiểm tra Match
  // Trả về matchId nếu có match, null nếu không
  Future<String?> recordSwipe(String swipedId, bool isLike) async {
    final myId = currentUserId;
    if (myId == null) return null;

    final action = isLike ? 'like' : 'nope';

    // 1. Lưu swipe
    await _supabase.from('swipes').insert({
      'swiper_id': myId,
      'swiped_id': swipedId,
      'action': action,
    });

    if (!isLike) return null;

    // 2. Nếu Like, kiểm tra xem đối phương có Like mình không
    final theirSwipeList = await _supabase
        .from('swipes')
        .select()
        .eq('swiper_id', swipedId)
        .eq('swiped_id', myId)
        .eq('action', 'like')
        .limit(1);

    if (theirSwipeList.isNotEmpty) {
      // It's a match! Tạo hoặc tìm match hiện có
      String? matchId;
      try {
        final matchRow = await _supabase
            .from('matches')
            .insert({
              'user1_id': myId,
              'user2_id': swipedId,
            })
            .select('id')
            .single();
        matchId = matchRow['id'] as String;
      } catch (e) {
        // Match đã tồn tại → tìm matchId theo cả 2 chiều
        // Chiều 1: myId là user1
        final r1 = await _supabase
            .from('matches')
            .select('id')
            .eq('user1_id', myId)
            .eq('user2_id', swipedId)
            .limit(1);
        if (r1.isNotEmpty) {
          matchId = r1[0]['id'] as String;
        } else {
          // Chiều 2: swipedId là user1
          final r2 = await _supabase
              .from('matches')
              .select('id')
              .eq('user1_id', swipedId)
              .eq('user2_id', myId)
              .limit(1);
          if (r2.isNotEmpty) {
            matchId = r2[0]['id'] as String;
          }
        }
      }
      return matchId;
    }
    return null;
  }
}
