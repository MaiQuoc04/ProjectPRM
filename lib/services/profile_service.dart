import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Lấy hồ sơ của bản thân
  Future<Map<String, dynamic>?> getMyProfile() async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Chưa đăng nhập');

    final response = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', myId)
        .maybeSingle();

    return response;
  }

  // Cập nhật thông tin hồ sơ
  Future<void> updateProfile({
    required String fullName,
    required int age,
    required String gender,
    required String bio,
    required List<String> tags,
  }) async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Chưa đăng nhập');

    await _supabase.from('profiles').upsert({
      'id': myId,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'bio': bio,
      'tags': tags,
    });
  }

  // Upload ảnh đại diện (dùng XFile để tương thích cả web lẫn mobile)
  Future<String> uploadAvatar(XFile imageFile) async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Chưa đăng nhập');

    final fileExtension = imageFile.name.split('.').last.toLowerCase();
    final fileName =
        '$myId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    // Đọc bytes (hoạt động trên cả web lẫn mobile)
    final bytes = await imageFile.readAsBytes();

    await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$fileExtension',
          ),
        );

    // Lấy public URL
    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
    return publicUrl;
  }

  // Upload ảnh trang cá nhân (không phải avatar chính)
  Future<String> uploadProfilePhoto(XFile imageFile) async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Chưa đăng nhập');

    final fileExtension = imageFile.name.split('.').last.toLowerCase();
    final fileName =
        '$myId/photos/photo_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    final bytes = await imageFile.readAsBytes();

    await _supabase.storage.from('avatars').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: 'image/$fileExtension',
          ),
        );

    return _supabase.storage.from('avatars').getPublicUrl(fileName);
  }

  // Cập nhật danh sách avatar_urls trong profile
  Future<void> updateAvatarUrls(List<String> urls) async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Chưa đăng nhập');

    await _supabase.from('profiles').upsert({
      'id': myId,
      'avatar_urls': urls,
    });
  }
}
