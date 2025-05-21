import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class GoalResultScreen extends StatefulWidget {
  final double currentWeight;
  final double targetWeight;
  final double weeklyLoss;

  const GoalResultScreen({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.weeklyLoss,
  });

  @override
  State<GoalResultScreen> createState() => _GoalResultScreenState();
}

class _GoalResultScreenState extends State<GoalResultScreen> {
  @override
  void initState() {
    super.initState();
    _calculateAndSaveTargetCalories();
  }

  Future<void> _calculateAndSaveTargetCalories() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson == null) return;
    final user = User.fromJson(jsonDecode(userJson));

    // 1. BMR 계산
    final now = DateTime.now();
    int age = now.year - user.birthDate.year;
    if (now.month < user.birthDate.month || (now.month == user.birthDate.month && now.day < user.birthDate.day)) {
      age--;
    }
    double bmr;
    if (user.gender == 'male') {
      bmr = 10 * user.weight + 6.25 * user.height - 5 * age + 5;
    } else {
      bmr = 10 * user.weight + 6.25 * user.height - 5 * age - 161;
    }

    // 2. 활동지수
    double activityFactor = 1.2;
    switch (user.activityLevel) {
      case '운동안함': activityFactor = 1.2; break;
      case '낮음 (주 2회 이하)': activityFactor = 1.375; break;
      case '보통 (주 3-4회)': activityFactor = 1.55; break;
      case '높음 (주 5회 이상)': activityFactor = 1.725; break;
      case '매우 높음 (매일)': activityFactor = 1.9; break;
    }
    final maintenance = bmr * activityFactor;

    // 3. 감량 칼로리 차감
    final dailyDeficit = widget.weeklyLoss * 7700 / 7;
    final targetCalories = (maintenance - dailyDeficit).round();

    await prefs.setInt('target_calories', targetCalories);
    print('DEBUG: [목표 칼로리 계산/저장] $targetCalories kcal');
  }

  @override
  Widget build(BuildContext context) {
    final double totalLoss = (widget.currentWeight - widget.targetWeight).abs();
    final bool isLoss = widget.currentWeight > widget.targetWeight;
    final int weeks = (widget.weeklyLoss > 0) ? (totalLoss / widget.weeklyLoss).ceil() : 0;
    final int days = weeks * 7;

    // 그래프 데이터 생성
    List<double> weights = [];
    for (int i = 0; i <= weeks; i++) {
      double w = isLoss
          ? max(widget.targetWeight, widget.currentWeight - widget.weeklyLoss * i)
          : min(widget.targetWeight, widget.currentWeight + widget.weeklyLoss * i);
      weights.add(w);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('목표 달성 예측'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '목표 체중(${widget.targetWeight.toStringAsFixed(1)}kg)에 도달하려면\n약 $days일(약 $weeks주)이 소요됩니다.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _WeightGraphPainter(weights: weights),
                child: Container(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('오늘', style: TextStyle(color: Colors.grey[700])),
                Text('$weeks주 후', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: const Text('홈으로'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightGraphPainter extends CustomPainter {
  final List<double> weights;
  _WeightGraphPainter({required this.weights});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final minWeight = weights.reduce(min);
    final maxWeight = weights.reduce(max);
    final yRange = maxWeight - minWeight == 0 ? 1 : maxWeight - minWeight;

    final points = <Offset>[];
    for (int i = 0; i < weights.length; i++) {
      final x = size.width * i / (weights.length - 1);
      final y = ((weights[i] - minWeight) / yRange) * size.height;
      points.add(Offset(x, y));
    }
    if (points.length > 1) {
      canvas.drawPoints(PointMode.polygon, points, paint);
    }
    // 점 찍기
    final dotPaint = Paint()..color = Colors.red;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 