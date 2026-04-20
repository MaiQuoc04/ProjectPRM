import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final AppinioSwiperController controller = AppinioSwiperController();
  
  // Mock Data
  final List<Map<String, dynamic>> profiles = [
    {
      'name': 'Hương Nguyễn',
      'age': 22,
      'bio': 'Yêu chó mèo, thích đi dạo bờ hồ',
      'imageUrl': 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    },
    {
      'name': 'Lan Anh',
      'age': 24,
      'bio': 'Coffee & Books',
      'imageUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    },
    {
      'name': 'Thảo Lê',
      'age': 21,
      'bio': 'Thích du lịch, ẩm thực',
      'imageUrl': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dating App', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person, color: Colors.grey),
          onPressed: () {
            // Mở profile preferences
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble, color: Colors.grey),
            onPressed: () {
              // Mở màn hình chat
              context.go('/matches');
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AppinioSwiper(
                controller: controller,
                cardCount: profiles.length,
                onSwipeEnd: _onSwipeEnd,
                cardBuilder: (BuildContext context, int index) {
                  return _buildCard(profiles[index]);
                },
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  void _onSwipeEnd(int previousIndex, int targetIndex, SwiperActivity activity) {
    if (activity is Swipe) {
      if (activity.direction == AxisDirection.right) {
        print('Liked ${profiles[previousIndex]['name']}');
        _checkMatchSimulation();
      } else if (activity.direction == AxisDirection.left) {
        print('Noped ${profiles[previousIndex]['name']}');
      }
    }
  }

  void _checkMatchSimulation() {
    // Tỷ lệ Match 30% cho demo
    if (DateTime.now().second % 3 == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 It\'s a Match!', textAlign: TextAlign.center),
          content: const Text('Bạn và người ấy cùng thích nhau. Bắt đầu trò chuyện ngay!', textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/matches');
              },
              child: const Text('Nhắn tin'),
            )
          ],
        ),
      );
    }
  }

  Widget _buildCard(Map<String, dynamic> profile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                profile['imageUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error)),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile['name']}, ${profile['age']}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile['bio'],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(Icons.close, Colors.red, () => controller.swipeLeft()),
          _buildCircleButton(Icons.favorite, Colors.green, () => controller.swipeRight()),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        child: IconButton(
          icon: Icon(icon, color: color, size: 35),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
