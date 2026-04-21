import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://tiffncacprawnjcwdejg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpZmZuY2FjcHJhd25qY3dkZWpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2OTQ4NzIsImV4cCI6MjA5MjI3MDg3Mn0.luKd2bqpnuaEZfQYTRCOLY4JnIzOX6ilMU7bmTswYOs',
  );

  final supabase = Supabase.instance.client;
  try {
    final res = await supabase.from('messages').select().limit(1);
    if (res.isNotEmpty) {
      print('Message keys: \${res.first.keys.toList()}');
    } else {
      print('Messages table is empty');
      // Let's try inserting a dummy message to see if is_read fails
      print('Trying to insert a message with is_read...');
      try {
        await supabase.from('messages').insert({
          'match_id': '00000000-0000-0000-0000-000000000000',
          'sender_id': '00000000-0000-0000-0000-000000000000',
          'content': 'test',
          'is_read': false
        });
        print('Insert with is_read succeeded!');
      } catch (e) {
        print('Insert failed: \$e');
      }
    }
  } catch (e) {
    print('Error: \$e');
  }
}
