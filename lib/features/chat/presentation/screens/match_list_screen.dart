import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/chat_service.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  final ChatService _chatService = ChatService();

  late Stream<List<Map<String, dynamic>>> _matchesStream;
  List<Map<String, dynamic>> _cachedMatches = [];

  @override
  void initState() {
    super.initState();
    _matchesStream = _chatService.streamMatchList();
  }

  void _refreshMatches() {
    setState(() {
      _matchesStream = _chatService.streamMatchList();
    });
  }

  Future<void> _openChat(Map<String, dynamic> match) async {
    final profile = match['other_profile'] as Map<String, dynamic>?;
    final matchId = match['id'] as String;
    final name = profile?['full_name'] as String?;
    final avatarUrls = profile?['avatar_urls'];
    final avatar = (avatarUrls != null && (avatarUrls as List).isNotEmpty)
        ? avatarUrls[0] as String
        : null;
    final bio = profile?['bio'] as String?;
    final tags = profile?['tags'] != null
        ? List<String>.from(profile!['tags'])
        : <String>[];

    await context.push(
      '/chat/$matchId',
      extra: {
        'otherUserName': name,
        'otherAvatarUrl': avatar,
        'otherBio': bio,
        'otherTags': tags,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/discovery'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _refreshMatches,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _matchesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _cachedMatches = snapshot.data!;
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              _cachedMatches.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError && _cachedMatches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: ${snapshot.error}'),
              ),
            );
          }

          if (_cachedMatches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 72,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa tương hợp với ai cả.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy tiếp tục khám phá!',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/discovery'),
                    child: const Text('Khám phá ngay'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _cachedMatches.length,
            separatorBuilder: (context, separatorIndex) =>
                const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final match = _cachedMatches[index];
              final profile = match['other_profile'] as Map<String, dynamic>?;
              final name = profile?['full_name'] as String? ?? 'Người ẩn danh';
              final avatarUrls = profile?['avatar_urls'];
              final avatar =
                  (avatarUrls != null && (avatarUrls as List).isNotEmpty)
                  ? avatarUrls[0] as String
                  : null;

              final unreadCount = match['unread_count'] as int? ?? 0;
              final lastMessage =
                  match['last_message'] as Map<String, dynamic>?;

              var subtitleText = 'Bấm để trò chuyện';
              final isUnread = unreadCount > 0;

              if (unreadCount >= 2) {
                subtitleText = '$unreadCount tin nhắn mới';
              } else if (lastMessage != null) {
                final content = lastMessage['content'] as String? ?? '';
                final isMe =
                    lastMessage['sender_id'] == _chatService.currentUserId;
                final prefix = isMe ? 'Bạn: ' : '';
                subtitleText = '$prefix$content';
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnread ? Colors.black87 : Colors.grey,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                trailing: isUnread
                    ? Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () async {
                  await _openChat(match);
                  _refreshMatches();
                },
              );
            },
          );
        },
      ),
    );
  }
}
