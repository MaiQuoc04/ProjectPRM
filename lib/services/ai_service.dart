import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  // TODO: Bạn cần thay thế API_KEY thật của Google Gemini
  static const String apiKey = 'YOUR_GEMINI_API_KEY';

  final GenerativeModel _model;

  AiService() : _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  Future<List<String>> generateSmartOpeners(String otherBio, List<String> otherTags) async {
    if (apiKey == 'YOUR_GEMINI_API_KEY') {
      return [
        'Vui lòng cập nhật Gemini API Key trong ai_service.dart',
        'Mock: Chào bạn, rất vui được làm quen',
        'Mock: Sở thích của bạn là gì?'
      ];
    }

    final prompt = '''
Bạn là một AI hỗ trợ ứng dụng hẹn hò. Người dùng đang muốn bắt chuyện với một người có thông tin sau:
- Tiểu sử (Bio): $otherBio
- Sở thích: ${otherTags.join(", ")}

Hãy tạo ra đúng 3 câu mở lời tinh tế, thân thiện và tự nhiên bằng tiếng Việt để bắt đầu câu chuyện dựa trên các thông tin trên. 
Không dài dòng, mỗi câu một dòng, không đánh số.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final text = response.text ?? '';
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      return lines.take(3).toList();
    } catch (e) {
      return ['Lỗi khi gọi AI: $e', 'Chào bạn!', 'Rất vui được làm quen'];
    }
  }
}
