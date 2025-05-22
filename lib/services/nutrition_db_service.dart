import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class NutritionInfo {
  final String name;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  final String imageUrl;

  NutritionInfo({
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.imageUrl,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      name: json['name'],
      calories: json['calories'],
      carbs: json['carbs'],
      protein: json['protein'],
      fat: json['fat'],
      imageUrl: json['image_url'],
    );
  }
}

class NutritionDbService {
  static List<NutritionInfo>? _cache;

  static Future<List<NutritionInfo>> loadNutritionDb() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/nutrition_db.json');
    final List<dynamic> jsonList = json.decode(jsonStr);
    _cache = jsonList.map((e) => NutritionInfo.fromJson(e)).toList();
    return _cache!;
  }

  static Future<NutritionInfo?> getByName(String name) async {
    final db = await loadNutritionDb();
    return db.firstWhere(
      (item) => item.name == name,
      orElse: () => NutritionInfo(
        name: name,
        calories: 0,
        carbs: 0,
        protein: 0,
        fat: 0,
        imageUrl: '',
      ),
    );
  }
} 