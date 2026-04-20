import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PhotoVerificationScreen extends StatefulWidget {
  const PhotoVerificationScreen({super.key});

  @override
  State<PhotoVerificationScreen> createState() => _PhotoVerificationScreenState();
}

class _PhotoVerificationScreenState extends State<PhotoVerificationScreen> {
  final List<String> gestures = ['✌️ (Peace)', '👍 (Thumbs Up)', '✋ (Stop)'];
  late String currentGesture;
  bool isVerifying = false;

  @override
  void initState() {
    super.initState();
    currentGesture = gestures[DateTime.now().second % gestures.length];
  }

  void _simulateVerification() {
    setState(() => isVerifying = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực thành công! Bạn đã nhận được tích xanh.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực khuôn mặt')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hãy chụp một bức ảnh selfie với cử chỉ sau:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Text(
                currentGesture,
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Container(
                width: 250,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.camera_front, size: 80, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isVerifying ? null : _simulateVerification,
                  icon: isVerifying 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt),
                  label: Text(isVerifying ? 'Đang phân tích AI...' : 'Chụp ảnh'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
