import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'food_analysis_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? calories;
  double? carbs;
  double? protein;
  double? fat;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  Future<void> _loadNutritionData() async {
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences 전체 값 출력 (디버깅용)
    print('DEBUG: [홈 화면 진입] SharedPreferences 전체 값:');
    for (var key in prefs.getKeys()) {
      print('  $key = ${prefs.get(key)}');
    }
    // 예시: target_calories, target_weight 등에서 계산
    final int? targetCalories = prefs.getInt('target_calories');
    if (targetCalories != null) {
      calories = targetCalories.toDouble();
      // 기본 비율: 탄수화물 50%, 단백질 25%, 지방 25% (칼로리 기준)
      carbs = (calories! * 0.5) / 4; // 1g = 4kcal
      protein = (calories! * 0.25) / 4;
      fat = (calories! * 0.25) / 9; // 1g = 9kcal
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 권장 섭취량'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : calories == null
              ? const Center(child: Text('목표 칼로리 정보가 없습니다.'))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('감량을 위해 오늘 섭취해야 할 영양소',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 32),
                      _buildNutritionRow('칼로리', '${calories!.toStringAsFixed(0)} kcal'),
                      _buildNutritionRow('탄수화물', '${carbs!.toStringAsFixed(0)} g'),
                      _buildNutritionRow('단백질', '${protein!.toStringAsFixed(0)} g'),
                      _buildNutritionRow('지방', '${fat!.toStringAsFixed(0)} g'),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('사진촬영'),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FoodAnalysisScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('사진업로드'),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => FoodAnalysisScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        label: const Text('사진촬영'),
        icon: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 20)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} 