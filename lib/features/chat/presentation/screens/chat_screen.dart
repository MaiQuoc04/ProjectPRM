import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/chat_service.dart';
import '../../../../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String? otherUserName;
  final String? otherAvatarUrl;
  final String? otherBio;
  final List<String>? otherTags;

  const ChatScreen({
    super.key,
    required this.matchId,
    this.otherUserName,
    this.otherAvatarUrl,
    this.otherBio,
    this.otherTags,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AiService _aiService = AiService();
  bool _isAiLoading = false;

  // Optimistic messages: tin nhắn gửi nhưng chưa có phản hồi từ server
  final List<Map<String, dynamic>> _optimisticMessages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Optimistic update: hiển thị tin nhắn ngay
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = {
      'id': tempId,
      'match_id': widget.matchId,
      'sender_id': _chatService.currentUserId,
      'content': text,
      'message_type': 'text',
      'created_at': DateTime.now().toIso8601String(),
      '_isOptimistic': true,
    };
    setState(() => _optimisticMessages.add(optimistic));
    _scrollToBottom();

    try {
      await _chatService.sendMessage(widget.matchId, text);
      // Xóa tin nhắn optimistic sau khi server xác nhận (stream sẽ tự cập nhật)
      setState(() => _optimisticMessages.removeWhere((m) => m['id'] == tempId));
    } catch (e) {
      // Đánh dấu lỗi
      setState(() {
        final idx = _optimisticMessages.indexWhere((m) => m['id'] == tempId);
        if (idx != -1) _optimisticMessages[idx]['_error'] = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi gửi tin: $e')));
      }
    }
  }

  Future<void> _showSmartOpener() async {
    setState(() => _isAiLoading = true);

    final bio = widget.otherBio ?? '';
    final tags = widget.otherTags ?? [];

    final openers = await _aiService.generateSmartOpeners(bio, tags);
    setState(() => _isAiLoading = false);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.primaryGradient.createShader(b),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                const Text('AI Gợi ý câu hỏi',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Dựa trên sở thích: ${tags.join(", ")}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            ...openers.map((o) => _buildOpenerOption(o, ctx)),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenerOption(String text, BuildContext sheetCtx) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(text, style: const TextStyle(fontSize: 14)),
        trailing:
            const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
        onTap: () {
          Navigator.pop(sheetCtx);
          _messageController.text = text;
          _sendMessage();
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, String? currentUserId) {
    final isMe = msg['sender_id'] == currentUserId;
    final isOptimistic = msg['_isOptimistic'] == true;
    final isError = msg['_error'] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? (isError
                        ? Colors.redAccent
                        : isOptimistic
                            ? AppColors.primary.withValues(alpha: 0.75)
                            : AppColors.primary)
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Text(
                msg['content'],
                style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15),
              ),
            ),
            if (isOptimistic && !isError)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 2),
                    Text('Đang gửi...',
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;
    final name = widget.otherUserName ?? 'Người dùng';
    final avatarUrl = widget.otherAvatarUrl;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Đang hoạt động',
                    style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.gamepad_outlined, color: AppColors.primary),
            onPressed: () => context.push('/minigame'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.streamMessages(widget.matchId),
              builder: (context, snapshot) {
                final serverMessages = snapshot.data ?? [];

                // Gộp server messages + optimistic messages, tránh duplicate
                final serverIds = serverMessages.map((m) => m['id']).toSet();
                final pendingOptimistic = _optimisticMessages
                    .where((m) => !serverIds.contains(m['id']))
                    .toList();
                final allMessages = [...serverMessages, ...pendingOptimistic];

                if (snapshot.connectionState == ConnectionState.waiting &&
                    allMessages.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }

                if (allMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('Hãy là người đầu tiên gửi tin!',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Gợi ý từ AI'),
                          onPressed: _showSmartOpener,
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(allMessages[index], currentUserId),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              spreadRadius: 1,
              blurRadius: 8)
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: _isAiLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, color: AppColors.primary),
              onPressed: _isAiLoading ? null : _showSmartOpener,
              tooltip: 'AI gợi ý câu hỏi',
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                maxLines: null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
