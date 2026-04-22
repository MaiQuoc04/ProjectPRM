import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> getMatches() async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Chưa đăng nhập');

    final response = await _supabase
        .from('matches')
        .select('id, user1_id, user2_id')
        .or('user1_id.eq.$myId,user2_id.eq.$myId');

    final matches = List<Map<String, dynamic>>.from(response);

    for (final match in matches) {
      final otherUserId = match['user1_id'] == myId
          ? match['user2_id']
          : match['user1_id'];

      final profile = await _supabase
          .from('profiles')
          .select('full_name, avatar_urls, bio, tags')
          .eq('id', otherUserId)
          .maybeSingle();

      match['other_profile'] = profile;

      final messages = await _supabase
          .from('messages')
          .select('content, sender_id, is_read, created_at')
          .eq('match_id', match['id'])
          .order('created_at', ascending: false);

      if (messages.isNotEmpty) {
        match['last_message'] = messages.first;
        match['unread_count'] = messages
            .where((message) => message['sender_id'] != myId)
            .where((message) => message['is_read'] != true)
            .length;
      } else {
        match['last_message'] = null;
        match['unread_count'] = 0;
      }
    }

    return matches;
  }

  Stream<List<Map<String, dynamic>>> streamMatchList() {
    late final StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? messageChangesSub;
    var isRefreshing = false;
    var hasPendingRefresh = false;

    Future<void> emitMatches() async {
      if (isRefreshing) {
        hasPendingRefresh = true;
        return;
      }

      isRefreshing = true;
      try {
        final matches = await getMatches();
        if (!controller.isClosed) {
          controller.add(matches);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        isRefreshing = false;
        if (hasPendingRefresh && !controller.isClosed) {
          hasPendingRefresh = false;
          Future.microtask(emitMatches);
        }
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        emitMatches();
        messageChangesSub = _supabase
            .from('messages')
            .stream(primaryKey: ['id'])
            .skip(1)
            .listen(
              (_) => emitMatches(),
              onError: (Object error, StackTrace stackTrace) {
                if (!controller.isClosed) {
                  controller.addError(error, stackTrace);
                }
              },
            );
      },
      onCancel: () async {
        await messageChangesSub?.cancel();
      },
    );

    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> streamMessages(String matchId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at', ascending: true);
  }

  Future<void> sendMessage(
    String matchId,
    String content, {
    String type = 'text',
  }) async {
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
    } catch (error) {
      debugPrint('Error marking messages as read: $error');
    }
  }

  Stream<int> streamTotalMatchesCount() {
    final myId = currentUserId;
    if (myId == null) return Stream.value(0);

    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .map((matches) {
          // Lọc những match có mình tham gia, đề phòng RLS chưa chặt hoặc bị cache
          final myMatches = matches.where(
              (m) => m['user1_id'] == myId || m['user2_id'] == myId);
          return myMatches.length;
        });
  }

  Stream<int> streamUnreadConversationsCount() {
    final myId = currentUserId;
    if (myId == null) return Stream.value(0);

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('is_read', false)
        .map((messages) {
          final unreadMatches = messages
              .where((message) => message['sender_id'] != myId)
              .map((message) => message['match_id'].toString())
              .toSet();
          return unreadMatches.length;
        });
  }
}
