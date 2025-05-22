import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_model.dart';
import '../services/food_database_service.dart';
import '../services/subscription_service.dart';

class FoodAnalysisScreen extends StatefulWidget {
  const FoodAnalysisScreen({super.key});

  @override
  State<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  final FoodDatabaseService _foodService = FoodDatabaseService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ImagePicker _picker = ImagePicker();
  
  List<File> _selectedImages = [];
  List<Food>? _matchedFoods;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMultiFoodMode = true; // 다중 음식 분석 모드
  Map<String, Food?> _confirmedFoods = {};
  Map<String, FoodPortion> _foodPortions = {}; // 음식 인분 정보 저장
  List<DailyFoodRecord> _dailyRecords = []; // 일일 식사 기록

  @override
  void initState() {
    super.initState();
    _loadDailyRecords();
  }

  Future<void> _loadDailyRecords() async {
    // TODO: 실제로는 서버에서 오늘의 식사 기록을 가져와야 함
    // 임시 데이터로 대체
    setState(() {
      _dailyRecords = [
        DailyFoodRecord(
          id: '1',
          imagePath: 'assets/images/breakfast.jpg',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          totalCalories: 450,
          foods: ['김치찌개', '밥', '반찬 3종'],
        ),
        DailyFoodRecord(
          id: '2',
          imagePath: 'assets/images/lunch.jpg',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          totalCalories: 680,
          foods: ['비빔밥', '미역국'],
        ),
      ];
    });
  }

  Future<void> _addImage(ImageSource source) async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 5장까지 업로드할 수 있습니다.')),
      );
      return;
    }
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _addImagesFromGallery() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 5장까지 업로드할 수 있습니다.')),
      );
      return;
    }
    // 안내 다이얼로그
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('사진 업로드 안내'),
        content: Text('총 5장의 음식 사진을 업로드 할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
    final List<XFile>? images = await _picker.pickMultiImage(imageQuality: 80);
    if (images != null && images.isNotEmpty) {
      setState(() {
        final remain = 5 - _selectedImages.length;
        _selectedImages.addAll(
          images.take(remain).map((xfile) => File(xfile.path)),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _analyzeImage() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 구독 상태 확인
      final subscription = await _subscriptionService.getCurrentSubscription();
      if (subscription == null) {
        setState(() {
          _errorMessage = '이미지 분석을 위해서는 구독이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      // 이미지 업로드 및 분석
      final matchedFoods = await _foodService.matchFoodImage(
        _selectedImages.map((e) => e.path).join(','),
        isMultiFood: _isMultiFoodMode,
      );
      
      setState(() {
        _matchedFoods = matchedFoods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '이미지 분석 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  void _confirmFood(String foodId, Food? selectedFood) {
    setState(() {
      _confirmedFoods[foodId] = selectedFood;
      if (selectedFood != null) {
        _showPortionDialog(selectedFood);
      }
    });
  }

  Future<void> _showPortionDialog(Food food) async {
    int servings = 1;
    double consumptionRatio = 100.0;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('음식 인분 정보'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('이 음식은 몇 인분인가요?'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (servings > 1) {
                            setState(() {
                              servings--;
                            });
                          }
                        },
                      ),
                      Text(
                        '$servings인분',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            servings++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('회원님이 드실 양은 얼마나 되나요?'),
                  const SizedBox(height: 8),
                  Slider(
                    value: consumptionRatio,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${consumptionRatio.toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setState(() {
                        consumptionRatio = value;
                      });
                    },
                  ),
                  Text(
                    '${consumptionRatio.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _foodPortions[food.id] = FoodPortion(
                        servings: servings,
                        consumptionRatio: consumptionRatio / 100,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음식 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: 분석 기록 화면으로 이동
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 분석 모드 선택
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '분석 모드',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('단일 음식'),
                              value: false,
                              groupValue: _isMultiFoodMode,
                              onChanged: (value) {
                                setState(() {
                                  _isMultiFoodMode = false;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('다중 음식'),
                              subtitle: const Text('여러 반찬 포함'),
                              value: true,
                              groupValue: _isMultiFoodMode,
                              onChanged: (value) {
                                setState(() {
                                  _isMultiFoodMode = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 이미지 선택/촬영 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectedImages.length >= 5 ? null : () => _addImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('사진 촬영'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedImages.length >= 5 ? null : _addImagesFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리에서 선택'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 선택된 이미지 표시
              if (_selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 로딩 표시
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),

              // 에러 메시지 표시
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),

              // 분석 결과 표시
              if (_matchedFoods != null) ...[
                const Text(
                  '분석 결과',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isMultiFoodMode) ...[
                  _buildTotalNutrition(),
                  const SizedBox(height: 16),
                ],
                ..._matchedFoods!.map((food) => _buildFoodConfirmationCard(food)),
              ],

              // 일일 목표 대비 현황
              const SizedBox(height: 24),
              _buildDailyProgress(),

              // 오늘의 식사 기록
              const SizedBox(height: 24),
              _buildDailyRecords(),

              // 분석 시작 버튼
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedImages.isEmpty || _isLoading ? null : _analyzeImage,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('분석 시작'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodConfirmationCard(Food food) {
    final isConfirmed = _confirmedFoods.containsKey(food.id);
    final confirmedFood = _confirmedFoods[food.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isConfirmed) ...[
              const Text(
                '이 음식은 다음 중 하나로 보입니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildFoodOptions(food),
            ] else ...[
              _buildConfirmedFood(confirmedFood!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoodOptions(Food food) {
    // 상위 3개 음식 옵션 생성 (실제로는 서버에서 받아와야 함)
    final options = [
      food,
      Food(
        id: '${food.id}_2',
        name: '비슷한 음식 1',
        category: food.category,
        subCategory: food.subCategory,
        calories: food.calories * 0.9,
        carbohydrates: food.carbohydrates * 0.9,
        protein: food.protein * 0.9,
        fat: food.fat * 0.9,
        servingSize: food.servingSize,
        imageUrl: food.imageUrl,
        tags: food.tags,
        confidence: 0.21,
      ),
      Food(
        id: '${food.id}_3',
        name: '비슷한 음식 2',
        category: food.category,
        subCategory: food.subCategory,
        calories: food.calories * 1.1,
        carbohydrates: food.carbohydrates * 1.1,
        protein: food.protein * 1.1,
        fat: food.fat * 1.1,
        servingSize: food.servingSize,
        imageUrl: food.imageUrl,
        tags: food.tags,
        confidence: 0.16,
      ),
    ];

    return Column(
      children: [
        ...options.map((option) => _buildFoodOptionTile(option)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            // TODO: 추가 질문 흐름 구현
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('추가 질문 기능 준비 중입니다.')),
            );
          },
          child: const Text('여기에 없음'),
        ),
      ],
    );
  }

  Widget _buildFoodOptionTile(Food food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _confirmFood(food.id, food),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  food.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '신뢰도: ${(food.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmedFood(Food food) {
    final portion = _foodPortions[food.id];
    final serving = food.servingNutrition;
    final adjustedNutrition = {
      'calories': serving['calories']! * (portion?.consumptionRatio ?? 1.0),
      'carbohydrates': serving['carbohydrates']! * (portion?.consumptionRatio ?? 1.0),
      'protein': serving['protein']! * (portion?.consumptionRatio ?? 1.0),
      'fat': serving['fat']! * (portion?.consumptionRatio ?? 1.0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                food.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food.category} > ${food.subCategory}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (portion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${portion.servings}인분 중 ${(portion.consumptionRatio * 100).toStringAsFixed(0)}% 섭취',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _confirmedFoods.remove(food.id);
                  _foodPortions.remove(food.id);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          '''영양 정보 (섭취량 기준)
칼로리: ${adjustedNutrition['calories']!.toStringAsFixed(1)}kcal
탄수화물: ${adjustedNutrition['carbohydrates']!.toStringAsFixed(1)}g
단백질: ${adjustedNutrition['protein']!.toStringAsFixed(1)}g
지방: ${adjustedNutrition['fat']!.toStringAsFixed(1)}g''',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTotalNutrition() {
    if (_matchedFoods == null || _matchedFoods!.isEmpty) return const SizedBox.shrink();

    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;
    int totalFoodCount = 0;
    Map<String, int> categoryCount = {};

    for (var food in _confirmedFoods.values) {
      if (food != null) {
        final serving = food.servingNutrition;
        final portion = _foodPortions[food.id];
        final ratio = portion?.consumptionRatio ?? 1.0;
        
        totalCalories += serving['calories']! * ratio;
        totalCarbs += serving['carbohydrates']! * ratio;
        totalProtein += serving['protein']! * ratio;
        totalFat += serving['fat']! * ratio;
        totalFoodCount++;
        
        categoryCount[food.category] = (categoryCount[food.category] ?? 0) + 1;
      }
    }

    // 목표 대비 계산 (예시 값, 실제로는 사용자 설정값 사용)
    const dailyGoals = {
      'calories': 2000.0,
      'carbs': 250.0,
      'protein': 50.0,
      'fat': 40.0,
    };

    final goalProgress = {
      'calories': (totalCalories / dailyGoals['calories']! * 100).toStringAsFixed(1),
      'carbs': (totalCarbs / dailyGoals['carbs']! * 100).toStringAsFixed(1),
      'protein': (totalProtein / dailyGoals['protein']! * 100).toStringAsFixed(1),
      'fat': (totalFat / dailyGoals['fat']! * 100).toStringAsFixed(1),
    };

    final remainingCarbs = (dailyGoals['carbs']! - totalCarbs).toStringAsFixed(1);
    final remainingProtein = (dailyGoals['protein']! - totalProtein).toStringAsFixed(1);
    final excessFat = (totalFat - dailyGoals['fat']!).toStringAsFixed(1);

    // 음식 카테고리 요약
    final categorySummary = categoryCount.entries
        .map((e) => '${e.key} ${e.value}종')
        .join(', ');

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '분석 결과 요약',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '음식: $categorySummary',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '총 ${totalFoodCount}종의 음식, 섭취량 ${_calculateTotalServings()}인분 중 ${_calculateAverageConsumption()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '영양 정보 (섭취량 기준)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionItem('칼로리', '${totalCalories.toStringAsFixed(0)}kcal', '목표의 ${goalProgress['calories']}%'),
                _buildNutritionItem('탄수화물', '${totalCarbs.toStringAsFixed(1)}g', '${double.parse(remainingCarbs) > 0 ? '${remainingCarbs}g 추가 가능' : '${remainingCarbs}g 초과'}'),
                _buildNutritionItem('단백질', '${totalProtein.toStringAsFixed(1)}g', '목표의 ${goalProgress['protein']}%'),
                _buildNutritionItem('지방', '${totalFat.toStringAsFixed(1)}g', '${double.parse(excessFat) > 0 ? '${excessFat}g 초과' : '${excessFat}g 추가 가능'}'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '목표 대비 현황',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildProgressBar('단백질', double.parse(goalProgress['protein']!)),
            const SizedBox(height: 8),
            _buildProgressBar('탄수화물', double.parse(goalProgress['carbs']!)),
            const SizedBox(height: 8),
            _buildProgressBar('지방', double.parse(goalProgress['fat']!)),
          ],
        ),
      ),
    );
  }

  String _calculateTotalServings() {
    int totalServings = 0;
    for (var portion in _foodPortions.values) {
      totalServings += portion.servings;
    }
    return totalServings.toString();
  }

  String _calculateAverageConsumption() {
    if (_foodPortions.isEmpty) return '0';
    double totalRatio = 0;
    for (var portion in _foodPortions.values) {
      totalRatio += portion.consumptionRatio * 100;
    }
    return (totalRatio / _foodPortions.length).toStringAsFixed(0);
  }

  Widget _buildProgressBar(String label, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${percentage.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 100 ? Colors.red : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionItem(String label, String value, String subtext) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtext,
          style: TextStyle(
            fontSize: 12,
            color: subtext.contains('초과') ? Colors.red : Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDailyProgress() {
    // 일일 목표 (예시 값, 실제로는 사용자 설정값 사용)
    const dailyGoals = {
      'calories': 2000.0,
      'carbs': 250.0,
      'protein': 50.0,
      'fat': 40.0,
    };

    // 현재까지 섭취량 계산
    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    // 기존 기록의 영양소 합산
    for (var record in _dailyRecords) {
      totalCalories += record.totalCalories;
      // TODO: 실제로는 각 기록의 상세 영양소 정보를 합산해야 함
    }

    // 현재 분석 중인 음식의 영양소 합산
    for (var food in _confirmedFoods.values) {
      if (food != null) {
        final serving = food.servingNutrition;
        final portion = _foodPortions[food.id];
        final ratio = portion?.consumptionRatio ?? 1.0;
        
        totalCalories += serving['calories']! * ratio;
        totalCarbs += serving['carbohydrates']! * ratio;
        totalProtein += serving['protein']! * ratio;
        totalFat += serving['fat']! * ratio;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 목표 현황',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutritionProgressBar(
              '칼로리',
              totalCalories,
              dailyGoals['calories']!,
              'kcal',
            ),
            const SizedBox(height: 12),
            _buildNutritionProgressBar(
              '탄수화물',
              totalCarbs,
              dailyGoals['carbs']!,
              'g',
            ),
            const SizedBox(height: 12),
            _buildNutritionProgressBar(
              '단백질',
              totalProtein,
              dailyGoals['protein']!,
              'g',
            ),
            const SizedBox(height: 12),
            _buildNutritionProgressBar(
              '지방',
              totalFat,
              dailyGoals['fat']!,
              'g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionProgressBar(
    String label,
    double current,
    double goal,
    String unit,
  ) {
    final percentage = (current / goal * 100).clamp(0, 100);
    final remaining = goal - current;
    final isExceeded = current > goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${current.toStringAsFixed(1)}$unit / ${goal.toStringAsFixed(1)}$unit',
              style: TextStyle(
                color: isExceeded ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isExceeded ? Colors.red : Colors.blue,
                ),
                minHeight: 8,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isExceeded
              ? '${(current - goal).toStringAsFixed(1)}$unit 초과'
              : '${remaining.toStringAsFixed(1)}$unit 남음',
          style: TextStyle(
            fontSize: 12,
            color: isExceeded ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 식사 기록',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dailyRecords.length,
            itemBuilder: (context, index) {
              final record = _dailyRecords[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    // TODO: 해당 기록의 상세 정보 표시
                    _showRecordDetails(record);
                  },
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          record.imagePath,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.fastfood),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.totalCalories}kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRecordDetails(DailyFoodRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        record.imagePath,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood, size: 48),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '섭취 시간: ${_formatTime(record.timestamp)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '총 칼로리: ${record.totalCalories}kcal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '인식된 음식:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...record.foods.map((food) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $food'),
                    )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class FoodPortion {
  final int servings;
  final double consumptionRatio;

  FoodPortion({
    required this.servings,
    required this.consumptionRatio,
  });
}

class DailyFoodRecord {
  final String id;
  final String imagePath;
  final DateTime timestamp;
  final double totalCalories;
  final List<String> foods;

  DailyFoodRecord({
    required this.id,
    required this.imagePath,
    required this.timestamp,
    required this.totalCalories,
    required this.foods,
  });
} 