import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/food_detection_result.dart';
import 'api_client.dart';

class FoodDetectionService {
  final ApiClient _apiClient = ApiClient();
  
  // 이미지 임시 저장
  Future<String> saveImageTemporarily(File imageFile) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${directory.path}/food_$timestamp.jpg';
    await imageFile.copy(path);
    return path;
  }

  // 전체 음식 인식 프로세스
  Future<FoodDetectionResult> processFoodImage(File imageFile) async {
    // 1. 이미지 임시 저장
    final savedImagePath = await saveImageTemporarily(imageFile);
    
    // 2. API를 통한 음식 감지
    final detectionResult = await _apiClient.detectFood(imageFile);
    
    // 3. 결과 매핑
    final items = (detectionResult['items'] as List).map((item) {
      return FoodItem(
        name: item['name'] as String,
        confidence: item['confidence'] as double,
        boundingBox: {
          'x': item['bbox']['x'] as double,
          'y': item['bbox']['y'] as double,
          'width': item['bbox']['width'] as double,
          'height': item['bbox']['height'] as double,
        },
      );
    }).toList();

    return FoodDetectionResult(
      detectedItems: items,
      imageUrl: savedImagePath,
      timestamp: DateTime.now(),
    );
  }

  // 음식 분류 수정
  Future<void> updateFoodClassification({
    required String imageId,
    required String foodName,
    required int itemIndex,
  }) async {
    await _apiClient.updateFoodClassification(
      imageId: imageId,
      foodName: foodName,
      itemIndex: itemIndex,
    );
  }
} 