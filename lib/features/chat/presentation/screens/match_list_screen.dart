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
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _chatService.getMatches();
      setState(() => _matches = matches);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChat(Map<String, dynamic> match) {
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

    context.push(
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
        title: const Text('Tin nhắn',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/discovery'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadMatches,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _matches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 72, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Bạn chưa tương hợp với ai cả.',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Hãy tiếp tục khám phá!',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.go('/discovery'),
                        child: const Text('Khám phá ngay'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _matches.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 80),
                  itemBuilder: (context, index) {
                    final match = _matches[index];
                    final profile =
                        match['other_profile'] as Map<String, dynamic>?;
                    final name =
                        profile?['full_name'] as String? ?? 'Người ẩn danh';
                    final avatarUrls = profile?['avatar_urls'];
                    final avatar = (avatarUrls != null &&
                            (avatarUrls as List).isNotEmpty)
                        ? avatarUrls[0] as String
                        : null;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage:
                            avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 18),
                              )
                            : null,
                      ),
                      title: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: const Text('Bấm để trò chuyện',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline,
                            color: Colors.white, size: 18),
                      ),
                      onTap: () => _openChat(match),
                    );
                  },
                ),
    );
  }
}
