import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  // TODO: Ban can thay the API key that cua Google Gemini.
  static const String apiKey = 'AIzaSyBk3m-xeCSf8ej_ikpb8uNSZLvGxxvuaeM';
  static const String _modelName = 'gemini-2.5-flash-lite';
  static const List<Duration> _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  final GenerativeModel _model;

  AiService() : _model = GenerativeModel(model: _modelName, apiKey: apiKey);

  Future<List<String>> generateSuggestions({
    required String otherBio,
    required List<String> otherTags,
    required String chatHistory,
    required String style,
  }) async {
    if (apiKey == 'YOUR_GEMINI_API_KEY') {
      return [
        'Vui long cap nhat Gemini API key trong ai_service.dart.',
        'Mock: (Phong cach $style) Chao ban, rat vui duoc lam quen.',
        'Mock: So thich cua ban la gi?',
      ];
    }

    final hasHistory = chatHistory.trim().isNotEmpty;
    final contextPrompt = hasHistory
        ? 'Hai nguoi dang tro chuyen. Duoi day la lich su cac tin nhan gan nhat:\n'
              '$chatHistory\n\nHay goi y cau tiep theo de tra loi hoac tiep noi cau chuyen.'
        : 'Day la lan dau tien hai nguoi nhan tin. Hay goi y cau mo loi tinh te '
              'de bat dau cuoc tro chuyen.';

    final prompt =
        '''
Ban la mot AI ho tro ung dung hen ho. Nguoi dung dang muon nhan tin voi mot nguoi co thong tin sau:
- Tieu su (Bio): $otherBio
- So thich: ${otherTags.join(", ")}

$contextPrompt

Yeu cau:
- Phong cach nhan tin: $style
- Hay tao ra dung 3 cau goi y bang tieng Viet.
- Tu nhien, khong qua dai dong.
- Moi cau tren mot dong rieng biet, khong danh so thu tu va khong dung ngoac kep.
''';

    final content = [Content.text(prompt)];

    for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
      try {
        final response = await _model.generateContent(content);
        final suggestions = _parseSuggestions(response.text ?? '');

        if (suggestions.isNotEmpty) {
          return suggestions.take(3).toList();
        }

        throw StateError('Gemini tra ve noi dung rong.');
      } catch (error) {
        final canRetry = attempt < _retryDelays.length && _shouldRetry(error);
        if (!canRetry) {
          break;
        }
        await Future.delayed(_retryDelays[attempt]);
      }
    }

    return _buildFallbackSuggestions(
      style: style,
      chatHistory: chatHistory,
      otherTags: otherTags,
    );
  }

  List<String> _parseSuggestions(String text) {
    return text
        .split('\n')
        .map(
          (line) => line
              .trim()
              .replaceAll(RegExp(r'^[-*]\s*'), '')
              .replaceAll(RegExp(r'^\d+\.\s*'), ''),
        )
        .where((line) => line.isNotEmpty)
        .toList();
  }

  bool _shouldRetry(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('503') ||
        message.contains('unavailable') ||
        message.contains('high demand') ||
        message.contains('overloaded') ||
        message.contains('timeout') ||
        message.contains('deadline exceeded');
  }

  List<String> _buildFallbackSuggestions({
    required String style,
    required String chatHistory,
    required List<String> otherTags,
  }) {
    final hasHistory = chatHistory.trim().isNotEmpty;
    final firstTag = otherTags.isNotEmpty
        ? otherTags.first
        : 'nhung dieu ban thich';

    if (hasHistory) {
      switch (style) {
        case 'Hài hước':
          return [
            'Nghe cuon qua, ke them cho minh mot doan nua di?',
            'Cau chuyen nay dang hay day, phan tiep theo la gi vay?',
            'Minh dang bi cuon vao day roi, ban ke tiep nhe?',
          ];
        case 'Thả thính':
          return [
            'Noi chuyen voi ban xong tu nhien minh thay hom nay de thuong hon do.',
            'Ban cu rep kieu nay la minh muon noi chuyen mai thoi.',
            'Cang noi chuyen minh cang thay ban co suc hut do.',
          ];
        case 'Lịch sự':
          return [
            'Minh thay cau chuyen nay kha thu vi, ban chia se them duoc khong?',
            'Cach ban noi chuyen lam minh rat thoai mai, minh muon nghe them.',
            'Ban dang nhac den mot dieu kha hay, ban ke tiep nhe?',
          ];
        case 'Quan tâm':
          return [
            'Nghe vay minh thay dieu do chac han co y nghia voi ban, cam xuc cua ban luc do the nao?',
            'Chi tiet do lam minh to mo, dieu gi khien ban an tuong nhat vay?',
            'Minh muon hieu ban hon mot chut, ban ke tiep cho minh nghe nhe?',
          ];
        default:
          return [
            'Nghe hay that, ban ke them cho minh nghe duoc khong?',
            'Minh thay cau chuyen nay kha thu vi do, roi sao nua nhi?',
            'Ban noi chuyen cuon that, minh muon nghe tiep.',
          ];
      }
    }

    switch (style) {
      case 'Hài hước':
        return [
          'Chao ban, neu noi ve $firstTag thi ban thuoc team chuyen gia hay team cam tinh vay?',
          'Minh thay vibe cua ban kha thu vi, mo dau bang chuyen $firstTag co bi lo de khong?',
          'Hello ban, cho minh hoi nhe: voi $firstTag thi ban co phai nguoi rat kho tinh khong?',
        ];
      case 'Thả thính':
        return [
          'Chao ban, minh ghe qua va thay ban de lai an tuong kha manh do.',
          'Minh nghi bat dau cuoc tro chuyen voi ban la quyet dinh dung dan day.',
          'Hi ban, mot loi chao de thuong chac hop voi ban hon la mo bai qua nghiem tuc.',
        ];
      case 'Lịch sự':
        return [
          'Chao ban, minh rat vui duoc lam quen. Ban thuong quan tam nhat den $firstTag phai khong?',
          'Xin chao, minh thay ho so cua ban kha thu vi, dac biet la phan $firstTag.',
          'Rat vui duoc ket noi voi ban. Dieu gi o $firstTag khien ban thich nhat vay?',
        ];
      case 'Quan tâm':
        return [
          'Chao ban, minh to mo dieu gi trong $firstTag khien ban thay vui nhat?',
          'Hi ban, neu duoc chon mot dieu de ke ve ban than, ban se bat dau tu $firstTag chu?',
          'Minh thay $firstTag kha hop de mo dau cau chuyen, ban nghi sao?',
        ];
      default:
        return [
          'Chao ban, rat vui duoc lam quen.',
          'Minh thay ho so cua ban kha thu vi, dac biet la phan $firstTag.',
          'Neu bat dau bang mot chu de nhe nhang, minh muon nghe ban ke ve $firstTag.',
        ];
    }
  }
}
