import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'goal_result_screen.dart';
import '../models/user_model.dart';
import 'dart:convert';

class WeeklyLossScreen extends StatefulWidget {
  final double targetWeight;
  const WeeklyLossScreen({super.key, required this.targetWeight});

  @override
  State<WeeklyLossScreen> createState() => _WeeklyLossScreenState();
}

class _WeeklyLossScreenState extends State<WeeklyLossScreen> {
  double _weeklyLoss = 0.0;

  Future<void> _goToResult() async {
    final prefs = await SharedPreferences.getInstance();
    print('DEBUG: [주당 감량] SharedPreferences 전체 값:');
    for (var key in prefs.getKeys()) {
      print('  $key = ${prefs.get(key)}');
    }
    
    double? currentWeight = prefs.getDouble('signup_weight');
    double? targetWeight = prefs.getDouble('target_weight');
    
    // 값이 null이면 user_data에서 복구
    if (currentWeight == null) {
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        try {
          final user = User.fromJson(jsonDecode(userJson));
          currentWeight = user.weight;
          await prefs.setDouble('signup_weight', currentWeight);
          print('DEBUG: signup_weight를 user_data에서 복구: $currentWeight');
        } catch (e) {
          print('DEBUG: user_data 복구 실패: $e');
        }
      }
    }
    
    if (targetWeight == null) {
      targetWeight = widget.targetWeight;
      await prefs.setDouble('target_weight', targetWeight);
      print('DEBUG: target_weight를 widget에서 복구: $targetWeight');
    }

    if (currentWeight == null || targetWeight == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('체중 정보가 올바르지 않습니다.')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GoalResultScreen(
            currentWeight: currentWeight!,
            targetWeight: targetWeight!,
            weeklyLoss: _weeklyLoss,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주간 감량 목표'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '주당 몇 kg 감량을 원하십니까?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Slider(
              value: _weeklyLoss,
              min: 0.0,
              max: 3.0,
              divisions: 6, // 0, 0.5, 1, 1.5, 2, 2.5, 3
              label: _weeklyLoss.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _weeklyLoss = value;
                });
              },
            ),
            Center(
              child: Text(
                '${_weeklyLoss.toStringAsFixed(1)} kg',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _goToResult,
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
} 