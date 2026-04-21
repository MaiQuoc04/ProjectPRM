import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://tiffncacprawnjcwdejg.supabase.co/rest/v1/messages?limit=1');
  final headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpZmZuY2FjcHJhd25qY3dkZWpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2OTQ4NzIsImV4cCI6MjA5MjI3MDg3Mn0.luKd2bqpnuaEZfQYTRCOLY4JnIzOX6ilMU7bmTswYOs',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpZmZuY2FjcHJhd25qY3dkZWpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2OTQ4NzIsImV4cCI6MjA5MjI3MDg3Mn0.luKd2bqpnuaEZfQYTRCOLY4JnIzOX6ilMU7bmTswYOs',
  };

  final request = await HttpClient().getUrl(url);
  headers.forEach((key, value) => request.headers.add(key, value));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  
  if (response.statusCode == 200) {
    final List data = json.decode(responseBody);
    if (data.isNotEmpty) {
      print('Columns in messages table: ' + data.first.keys.toList().toString());
    } else {
      print('Messages table is empty, trying to insert dummy with is_read...');
      final insertUrl = Uri.parse('https://tiffncacprawnjcwdejg.supabase.co/rest/v1/messages');
      final insertReq = await HttpClient().postUrl(insertUrl);
      headers.forEach((key, value) => insertReq.headers.add(key, value));
      insertReq.headers.contentType = ContentType.json;
      insertReq.headers.add('Prefer', 'return=representation');
      
      final body = json.encode({
        'match_id': '00000000-0000-0000-0000-000000000000',
        'sender_id': '00000000-0000-0000-0000-000000000000',
        'content': 'test',
        'is_read': false
      });
      insertReq.write(body);
      final insertRes = await insertReq.close();
      final insertResBody = await insertRes.transform(utf8.decoder).join();
      print('Insert status: ' + insertRes.statusCode.toString());
      print('Insert response: ' + insertResBody);
    }
  } else {
    print('Failed to get messages: ' + response.statusCode.toString());
    print(responseBody);
  }
}
