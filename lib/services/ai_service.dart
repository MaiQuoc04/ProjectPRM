import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  // TODO: Bạn cần thay thế API_KEY thật của Google Gemini
  static const String apiKey = 'AIzaSyApmgFjGtRaCgdTMem6gDN0OasZ-dnLKQA';

  final GenerativeModel _model;

  AiService() : _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

  Future<List<String>> generateSuggestions({
    required String otherBio,
    required List<String> otherTags,
    required String chatHistory,
    required String style,
  }) async {
    if (apiKey == 'YOUR_GEMINI_API_KEY') {
      return [
        'Vui lòng cập nhật Gemini API Key trong ai_service.dart',
        'Mock: (Phong cách $style) Chào bạn, rất vui được làm quen',
        'Mock: Sở thích của bạn là gì?'
      ];
    }

    final hasHistory = chatHistory.trim().isNotEmpty;
    final contextPrompt = hasHistory
        ? 'Hai người đang trò chuyện. Dưới đây là lịch sử các tin nhắn gần nhất:\n$chatHistory\n\nHãy gợi ý câu tiếp theo để trả lời hoặc tiếp nối câu chuyện.'
        : 'Đây là lần đầu tiên hai người nhắn tin. Hãy gợi ý câu mở lời (pickup line hoặc lời chào) tinh tế để bắt đầu cuộc trò chuyện.';

    final prompt = '''
Bạn là một AI hỗ trợ ứng dụng hẹn hò. Người dùng đang muốn nhắn tin với một người có thông tin sau:
- Tiểu sử (Bio): $otherBio
- Sở thích: ${otherTags.join(", ")}

$contextPrompt

Yêu cầu:
- Phong cách nhắn tin: $style
- Hãy tạo ra đúng 3 câu gợi ý bằng tiếng Việt.
- Tự nhiên, không quá dài dòng (mỗi câu tối đa 2-3 dòng).
- Mỗi câu trên một dòng riêng biệt, không đánh số thứ tự đầu dòng, không dùng ngoặc kép bọc câu.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final text = response.text ?? '';
      final lines = text.split('\n')
          .map((l) => l.trim().replaceAll(RegExp(r'^[-*]\s*'), '').replaceAll(RegExp(r'^\d+\.\s*'), ''))
          .where((l) => l.isNotEmpty)
          .toList();
      
      return lines.take(3).toList();
    } catch (e) {
      return ['Lỗi khi gọi AI: $e', 'Chào bạn!', 'Rất vui được làm quen'];
    }
  }
}
