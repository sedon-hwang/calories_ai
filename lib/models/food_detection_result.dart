import 'package:flutter/foundation.dart';

class FoodItem {
  final String name;
  final double confidence;
  final Map<String, double> boundingBox; // {x, y, width, height}
  
  FoodItem({
    required this.name,
    required this.confidence,
    required this.boundingBox,
  });
}

class FoodDetectionResult {
  final List<FoodItem> detectedItems;
  final String imageUrl;
  final DateTime timestamp;
  
  const FoodDetectionResult({
    required this.detectedItems,
    required this.imageUrl,
    required this.timestamp,
  });
} 