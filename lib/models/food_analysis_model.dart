class FoodAnalysis {
  final String foodName;        // 음식 이름
  final double calories;        // 칼로리 (kcal)
  final double carbohydrates;   // 탄수화물 (g)
  final double protein;         // 단백질 (g)
  final double fat;            // 지방 (g)
  final double servingSize;     // 1회 제공량 (g)
  final String imageUrl;        // 분석된 이미지 URL
  final DateTime analyzedAt;    // 분석 시간
  final double confidence;      // 인식 신뢰도 (0.0 ~ 1.0)

  FoodAnalysis({
    required this.foodName,
    required this.calories,
    required this.carbohydrates,
    required this.protein,
    required this.fat,
    required this.servingSize,
    required this.imageUrl,
    required this.analyzedAt,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'calories': calories,
      'carbohydrates': carbohydrates,
      'protein': protein,
      'fat': fat,
      'servingSize': servingSize,
      'imageUrl': imageUrl,
      'analyzedAt': analyzedAt.toIso8601String(),
      'confidence': confidence,
    };
  }

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      foodName: json['foodName'],
      calories: json['calories'].toDouble(),
      carbohydrates: json['carbohydrates'].toDouble(),
      protein: json['protein'].toDouble(),
      fat: json['fat'].toDouble(),
      servingSize: json['servingSize'].toDouble(),
      imageUrl: json['imageUrl'],
      analyzedAt: DateTime.parse(json['analyzedAt']),
      confidence: json['confidence'].toDouble(),
    );
  }

  // 영양소 정보를 문자열로 반환
  String get nutritionInfo {
    return '''
음식: $foodName
칼로리: ${calories.toStringAsFixed(1)}kcal
탄수화물: ${carbohydrates.toStringAsFixed(1)}g
단백질: ${protein.toStringAsFixed(1)}g
지방: ${fat.toStringAsFixed(1)}g
1회 제공량: ${servingSize.toStringAsFixed(1)}g
''';
  }
} 