class Food {
  final String id;
  final String name;           // 음식 이름
  final String category;       // 음식 카테고리 (한식, 중식, 일식, 양식 등)
  final String subCategory;    // 세부 카테고리 (밥류, 면류, 고기류 등)
  final double calories;       // 칼로리 (kcal/100g)
  final double carbohydrates;  // 탄수화물 (g/100g)
  final double protein;        // 단백질 (g/100g)
  final double fat;           // 지방 (g/100g)
  final double servingSize;    // 1회 제공량 (g)
  final String imageUrl;       // 음식 이미지 URL
  final List<String> tags;     // 검색 태그
  final double confidence;     // 인식 신뢰도 (0.0 ~ 1.0)

  Food({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.calories,
    required this.carbohydrates,
    required this.protein,
    required this.fat,
    required this.servingSize,
    required this.imageUrl,
    required this.tags,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subCategory': subCategory,
      'calories': calories,
      'carbohydrates': carbohydrates,
      'protein': protein,
      'fat': fat,
      'servingSize': servingSize,
      'imageUrl': imageUrl,
      'tags': tags,
      'confidence': confidence,
    };
  }

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      subCategory: json['subCategory'],
      calories: json['calories'].toDouble(),
      carbohydrates: json['carbohydrates'].toDouble(),
      protein: json['protein'].toDouble(),
      fat: json['fat'].toDouble(),
      servingSize: json['servingSize'].toDouble(),
      imageUrl: json['imageUrl'],
      tags: List<String>.from(json['tags']),
      confidence: json['confidence']?.toDouble() ?? 1.0,
    );
  }

  // 영양소 정보를 문자열로 반환
  String get nutritionInfo {
    return '''
칼로리: ${calories.toStringAsFixed(1)}kcal/100g
탄수화물: ${carbohydrates.toStringAsFixed(1)}g/100g
단백질: ${protein.toStringAsFixed(1)}g/100g
지방: ${fat.toStringAsFixed(1)}g/100g
1회 제공량: ${servingSize.toStringAsFixed(1)}g
''';
  }

  // 1회 제공량 기준 영양소 정보 계산
  Map<String, double> get servingNutrition {
    final ratio = servingSize / 100.0;
    return {
      'calories': calories * ratio,
      'carbohydrates': carbohydrates * ratio,
      'protein': protein * ratio,
      'fat': fat * ratio,
    };
  }
} 