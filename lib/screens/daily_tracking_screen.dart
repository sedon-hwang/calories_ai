import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/goal_tracking_model.dart';
import '../services/goal_tracking_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DailyTrackingScreen extends StatefulWidget {
  @override
  _DailyTrackingScreenState createState() => _DailyTrackingScreenState();
}

class _DailyTrackingScreenState extends State<DailyTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _trackingService = GoalTrackingService();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;

  final _currentWeightController = TextEditingController();
  final _caloriesConsumedController = TextEditingController();
  final _stepsTakenController = TextEditingController();
  final _waterConsumedController = TextEditingController();
  final _noteController = TextEditingController();
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];

  @override
  void dispose() {
    _currentWeightController.dispose();
    _caloriesConsumedController.dispose();
    _stepsTakenController.dispose();
    _waterConsumedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final urls = await ApiService.uploadImages(token, _selectedImages);
      setState(() {
        _uploadedImageUrls.addAll(urls);
        _selectedImages.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지가 업로드되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 업로드 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTracking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 이미지 업로드
      await _uploadImages();

      final tracking = GoalTracking(
        goalId: '', // TODO: 현재 목표 ID 가져오기
        date: DateTime.now(),
        currentWeight: double.parse(_currentWeightController.text),
        caloriesConsumed: int.parse(_caloriesConsumedController.text),
        stepsTaken: int.parse(_stepsTakenController.text),
        waterConsumed: int.parse(_waterConsumedController.text),
        progress: 0.0, // TODO: 진행률 계산
        note: _noteController.text,
        images: _uploadedImageUrls,
      );

      final success = await _trackingService.saveDailyTracking(tracking);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일일 기록이 저장되었습니다.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일일 기록 저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('오늘의 기록'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _currentWeightController,
                      decoration: InputDecoration(
                        labelText: '현재 체중 (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '현재 체중을 입력해주세요';
                        }
                        if (double.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _caloriesConsumedController,
                      decoration: InputDecoration(
                        labelText: '칼로리 섭취 (kcal)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '칼로리 섭취량을 입력해주세요';
                        }
                        if (int.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _stepsTakenController,
                      decoration: InputDecoration(
                        labelText: '걸음 수',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '걸음 수를 입력해주세요';
                        }
                        if (int.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _waterConsumedController,
                      decoration: InputDecoration(
                        labelText: '물 섭취량 (ml)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '물 섭취량을 입력해주세요';
                        }
                        if (int.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: '메모',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: Icon(Icons.photo_camera),
                            label: Text('사진 추가'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedImages.isEmpty ? null : _uploadImages,
                            icon: Icon(Icons.upload),
                            label: Text('업로드'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (_selectedImages.isNotEmpty)
                      Container(
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
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveTracking,
                        child: Text('저장'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 