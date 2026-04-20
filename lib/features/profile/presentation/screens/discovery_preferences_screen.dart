import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DiscoveryPreferencesScreen extends StatefulWidget {
  const DiscoveryPreferencesScreen({super.key});

  @override
  State<DiscoveryPreferencesScreen> createState() => _DiscoveryPreferencesScreenState();
}

class _DiscoveryPreferencesScreenState extends State<DiscoveryPreferencesScreen> {
  double _distance = 10;
  RangeValues _ageRange = const RangeValues(18, 30);
  String _showMe = 'Mọi người';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt Tìm kiếm')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSectionTitle('Hiển thị cho tôi'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Nam', label: Text('Nam')),
              ButtonSegment(value: 'Nữ', label: Text('Nữ')),
              ButtonSegment(value: 'Mọi người', label: Text('Mọi người')),
            ],
            selected: {_showMe},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _showMe = newSelection.first);
            },
          ),
          const SizedBox(height: 30),
          
          _buildSectionTitle('Khoảng cách tối đa: ${_distance.toInt()} km'),
          Slider(
            value: _distance,
            min: 1,
            max: 100,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _distance = value);
            },
          ),
          const SizedBox(height: 30),
          
          _buildSectionTitle('Độ tuổi: ${_ageRange.start.toInt()} - ${_ageRange.end.toInt()}'),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 60,
            activeColor: AppColors.primary,
            onChanged: (values) {
              setState(() => _ageRange = values);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
