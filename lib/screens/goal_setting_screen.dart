import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/waist_logo_widget.dart';
import 'weekly_loss_screen.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calorieController = TextEditingController();
  final _weightController = TextEditingController();
  String? _goalType;
  bool _isLoading = false;
  double _targetWeight = 60; // 기본값

  final List<String> _goalTypes = [
    '다이어트',
    '현재 유지',
    '벌크업',
  ];

  @override
  void dispose() {
    _calorieController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleGoalSetting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_goalType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 유형을 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('goal_type', _goalType!);
      await prefs.setInt('target_calories', int.parse(_calorieController.text));
      await prefs.setDouble('target_weight', _targetWeight);
      await prefs.setBool('has_completed_goal_setting', true);
      
      print('DEBUG: [목표설정 완료] SharedPreferences 전체 값:');
      for (var key in prefs.getKeys()) {
        print('  $key = ${prefs.get(key)}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('목표가 설정되었습니다')),
        );
        
        // 홈 화면으로 이동 (이전 화면 스택 제거)
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      print('DEBUG: 목표설정 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('목표 설정'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('목표 유형', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _goalTypes.map((String type) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _goalType = type;
                              });
                              if (type == '현재 유지') {
                                final prefs = await SharedPreferences.getInstance();
                                final double? signupWeight = prefs.getDouble('signup_weight');
                                if (signupWeight != null) {
                                  setState(() {
                                    _targetWeight = signupWeight;
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _goalType == type ? Colors.blue : Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  type == '다이어트'
                                    ? 'assets/icons/diet.png'
                                    : type == '현재 유지'
                                      ? 'assets/icons/maintain.png'
                                      : 'assets/icons/bulkup.png',
                                  width: 50,
                                  height: 50,
                                ),
                                const SizedBox(height: 8),
                                Text(type, style: TextStyle(color: _goalType == type ? Colors.white : Colors.black)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('목표 체중 (kg)', style: TextStyle(fontSize: 16)),
                  Slider(
                    value: _targetWeight,
                    min: 1,
                    max: 120,
                    divisions: 119,
                    label: _targetWeight.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _targetWeight = value;
                      });
                    },
                  ),
                  Center(
                    child: Text('${_targetWeight.round()} kg', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_goalType == '다이어트') {
                              final weeklyLoss = await Navigator.push<double>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WeeklyLossScreen(targetWeight: _targetWeight),
                                ),
                              );
                              // TODO: weeklyLoss 값 저장 및 이후 로직 처리
                              if (weeklyLoss == null) return;
                            }
                            _handleGoalSetting();
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('목표 설정'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
