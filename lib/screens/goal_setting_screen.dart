import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/goal_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalService = GoalService();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String _selectedGoalType = 'weight_loss';
  final _targetWeightController = TextEditingController();
  final _targetCaloriesController = TextEditingController();
  final _targetStepsController = TextEditingController();
  final _targetWaterController = TextEditingController();
  final _weeklyGoalController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _targetWeightController.dispose();
    _targetCaloriesController.dispose();
    _targetStepsController.dispose();
    _targetWaterController.dispose();
    _weeklyGoalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _targetDate = picked;
        }
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final goal = Goal(
        userId: user.id,
        targetWeight: double.parse(_targetWeightController.text),
        targetCalories: double.parse(_targetCaloriesController.text),
        targetSteps: int.parse(_targetStepsController.text),
        targetWater: int.parse(_targetWaterController.text),
        startDate: _startDate,
        targetDate: _targetDate,
        goalType: _selectedGoalType,
        weeklyGoal: double.parse(_weeklyGoalController.text),
      );

      final savedGoal = await GoalService.setGoal(goal);

      // 목표 알림 설정
      await NotificationService().scheduleGoalReminder(
        id: 1,
        title: '목표 달성을 위한 알림',
        body: '오늘의 목표를 확인하고 기록해보세요!',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표가 설정되었습니다.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('목표 설정'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 목표 유형 선택
                    DropdownButtonFormField<String>(
                      value: _selectedGoalType,
                      decoration: const InputDecoration(
                        labelText: '목표 유형',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'weight_loss',
                          child: Text('체중 감량'),
                        ),
                        DropdownMenuItem(
                          value: 'weight_gain',
                          child: Text('체중 증가'),
                        ),
                        DropdownMenuItem(
                          value: 'maintenance',
                          child: Text('체중 유지'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGoalType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 목표 체중
                    TextFormField(
                      controller: _targetWeightController,
                      decoration: const InputDecoration(
                        labelText: '목표 체중 (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '목표 체중을 입력해주세요';
                        }
                        if (double.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 목표 칼로리
                    TextFormField(
                      controller: _targetCaloriesController,
                      decoration: const InputDecoration(
                        labelText: '목표 칼로리 (kcal)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '목표 칼로리를 입력해주세요';
                        }
                        if (double.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 목표 걸음 수
                    TextFormField(
                      controller: _targetStepsController,
                      decoration: const InputDecoration(
                        labelText: '목표 걸음 수',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '목표 걸음 수를 입력해주세요';
                        }
                        if (int.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 목표 물 섭취량
                    TextFormField(
                      controller: _targetWaterController,
                      decoration: const InputDecoration(
                        labelText: '목표 물 섭취량 (ml)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '목표 물 섭취량을 입력해주세요';
                        }
                        if (int.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 주간 목표
                    TextFormField(
                      controller: _weeklyGoalController,
                      decoration: const InputDecoration(
                        labelText: '주간 목표 (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '주간 목표를 입력해주세요';
                        }
                        if (double.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 시작일 선택
                    ListTile(
                      title: const Text('시작일'),
                      subtitle: Text(_startDate.toString().split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                    const SizedBox(height: 8),

                    // 목표일 선택
                    ListTile(
                      title: const Text('목표일'),
                      subtitle: Text(_targetDate.toString().split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 24),

                    // 저장 버튼
                    ElevatedButton(
                      onPressed: _saveGoal,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('목표 설정하기'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 