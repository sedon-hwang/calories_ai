import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../services/food_detection_service.dart';
import '../models/food_detection_result.dart';
import '../services/nutrition_db_service.dart';

class FoodDetectionScreen extends StatefulWidget {
  const FoodDetectionScreen({super.key});

  @override
  State<FoodDetectionScreen> createState() => _FoodDetectionScreenState();
}

class _FoodDetectionScreenState extends State<FoodDetectionScreen> {
  final FoodDetectionService _detectionService = FoodDetectionService();
  FoodDetectionResult? _detectionResult;
  bool _isProcessing = false;

  Future<File> _ensureJpeg(File file) async {
    final ext = path.extension(file.path).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg') return file;

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return file;

    final tempDir = await getTemporaryDirectory();
    final jpegPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    final jpegBytes = img.encodeJpg(decoded);
    final jpegFile = await File(jpegPath).writeAsBytes(jpegBytes);
    return jpegFile;
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      File file = File(image.path);
      file = await _ensureJpeg(file);
      final result = await _detectionService.processFoodImage(file);
      setState(() => _detectionResult = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _editFoodItem(int index) async {
    if (_detectionResult == null) return;

    final item = _detectionResult!.detectedItems[index];
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('음식 수정'),
        content: TextField(
          decoration: InputDecoration(
            labelText: '음식 이름',
            hintText: item.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, '수정된 음식 이름'),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result != null) {
      final updatedItems = List<FoodItem>.from(_detectionResult!.detectedItems);
      updatedItems[index] = FoodItem(
        name: result,
        confidence: item.confidence,
        boundingBox: item.boundingBox,
      );

      setState(() {
        _detectionResult = FoodDetectionResult(
          detectedItems: updatedItems,
          imageUrl: _detectionResult!.imageUrl,
          timestamp: _detectionResult!.timestamp,
        );
      });
    }
  }

  String _getFoodSummary() {
    if (_detectionResult == null) return '';
    final items = _detectionResult!.detectedItems;
    if (items.isEmpty) return '';
    // 예시: 김치찌개 + 밥 + 반찬 3개
    final Map<String, int> counts = {};
    for (final item in items) {
      counts[item.name] = (counts[item.name] ?? 0) + 1;
    }
    // 반찬류는 "반찬"으로 그룹화 (예시)
    final List<String> mainFoods = [];
    int sideDishCount = 0;
    for (final entry in counts.entries) {
      if (entry.key.contains('반찬')) {
        sideDishCount += entry.value;
      } else {
        mainFoods.add(entry.key);
      }
    }
    final summary = [
      ...mainFoods,
      if (sideDishCount > 0) '반찬 ${sideDishCount}개',
    ].join(' + ');
    return summary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 권장 섭취량'),
      ),
      body: Column(
        children: [
          if (_detectionResult != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _getFoodSummary(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Image.file(
                        File(_detectionResult!.imageUrl),
                        fit: BoxFit.contain,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                      ..._detectionResult!.detectedItems.map((item) {
                        final box = item.boundingBox;
                        // 이미지 위젯의 크기와 실제 이미지 크기가 다를 수 있으므로, 상대 좌표로 변환 필요
                        // 여기서는 0~1로 정규화된 값이 아니라고 가정하고, 실제 이미지 크기를 알아야 정확함
                        // 임시로 비율로 처리 (실제 배포시에는 이미지 크기 정보를 서버에서 함께 받아야 정확)
                        return Positioned(
                          left: box['x'] ?? 0,
                          top: box['y'] ?? 0,
                          width: box['width'] ?? 0,
                          height: box['height'] ?? 0,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  backgroundColor: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<NutritionInfo>>(
                future: NutritionDbService.loadNutritionDb(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final nutritionDb = snapshot.data!;
                  return ListView.builder(
                    itemCount: _detectionResult!.detectedItems.length,
                    itemBuilder: (context, index) {
                      final item = _detectionResult!.detectedItems[index];
                      final nutrition = nutritionDb.firstWhere(
                        (n) => n.name == item.name,
                        orElse: () => NutritionInfo(
                          name: item.name,
                          calories: 0,
                          carbs: 0,
                          protein: 0,
                          fat: 0,
                          imageUrl: '',
                        ),
                      );
                      return ListTile(
                        leading: nutrition.imageUrl.isNotEmpty
                            ? Image.network(nutrition.imageUrl, width: 40, height: 40, fit: BoxFit.cover)
                            : null,
                        title: Text(item.name),
                        subtitle: Text(
                          '칼로리: ${nutrition.calories}kcal, 탄수화물: ${nutrition.carbs}g, 단백질: ${nutrition.protein}g, 지방: ${nutrition.fat}g\n정확도: ${(item.confidence * 100).toStringAsFixed(1)}%'
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editFoodItem(index),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ] else if (_isProcessing) ...[
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text('사진을 촬영하거나 갤러리에서 선택해보세요'),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _isProcessing ? null : () => _pickAndProcessImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('사진촬영'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            onPressed: _isProcessing ? null : () => _pickAndProcessImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('갤러리'),
          ),
        ],
      ),
    );
  }
} 