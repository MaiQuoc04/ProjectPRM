import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/discovery'),
        ),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?ixlib=rb-1.2.1&auto=format&fit=crop&w=150&q=80'),
            ),
            title: Text('Người dùng ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Bạn có một tin nhắn mới!', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('10:00 AM', style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 5),
                CircleAvatar(radius: 10, backgroundColor: AppColors.primary, child: Text('1', style: TextStyle(color: Colors.white, fontSize: 10))),
              ],
            ),
            onTap: () {
              context.push('/chat/$index');
            },
          );
        },
      ),
    );
  }
}
