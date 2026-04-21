import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Lấy User hiện tại
  User? get currentUser => _supabase.auth.currentUser;

  // Đăng nhập bằng Email
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Đăng ký bằng Email
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Cập nhật Profile ban đầu
  Future<void> updateProfile({
    required String fullName,
    required int age,
    required String gender,
    required String bio,
    required List<String> tags,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    await _supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'bio': bio,
      'tags': tags,
    });
  }
}
