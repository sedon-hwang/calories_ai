import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/goal_tracking_service.dart';
import '../services/goal_service.dart';

class GoalRecommendationScreen extends StatefulWidget {
  @override
  _GoalRecommendationScreenState createState() => _GoalRecommendationScreenState();
}

class _GoalRecommendationScreenState extends State<GoalRecommendationScreen> {
  final _trackingService = GoalTrackingService();
  final _goalService = GoalService();
  bool _isLoading = true;
  Goal? _recommendedGoal;

  @override
  void initState() {
    super.initState();
    _loadRecommendedGoal();
  }

  Future<void> _loadRecommendedGoal() async {
    try {
      final goal = await _trackingService.getRecommendedGoal();
      setState(() {
        _recommendedGoal = goal;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목표 추천을 불러오는 중 오류가 발생했습니다: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyRecommendedGoal() async {
    if (_recommendedGoal == null) return;

    setState(() => _isLoading = true);
    try {
      await _goalService.setGoal(_recommendedGoal!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추천 목표가 적용되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목표 적용 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('목표 추천'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _recommendedGoal == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('추천할 수 있는 목표가 없습니다.'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('돌아가기'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '추천 목표',
                                style: Theme.of(context).textTheme.headline6,
                              ),
                              SizedBox(height: 16),
                              _buildGoalItem('목표 유형', _recommendedGoal!.goalType),
                              _buildGoalItem('시작일', _recommendedGoal!.startDate.toString().split(' ')[0]),
                              _buildGoalItem('목표일', _recommendedGoal!.targetDate.toString().split(' ')[0]),
                              _buildGoalItem('목표 체중', '${_recommendedGoal!.targetWeight}kg'),
                              _buildGoalItem('목표 칼로리', '${_recommendedGoal!.targetCalories}kcal'),
                              _buildGoalItem('목표 걸음 수', '${_recommendedGoal!.targetSteps}걸음'),
                              _buildGoalItem('목표 물 섭취량', '${_recommendedGoal!.targetWater}ml'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        '추천 이유',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            '이 목표는 귀하의 현재 상태와 건강 데이터를 기반으로 추천되었습니다. '
                            '체중, 활동량, 식습관 등을 고려하여 현실적이고 달성 가능한 목표를 설정했습니다.',
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('다른 목표 설정하기'),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _applyRecommendedGoal,
                              child: Text('이 목표로 설정하기'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGoalItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
} 