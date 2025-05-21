import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/goal_model.dart';
import '../models/goal_tracking_model.dart';
import '../services/goal_service.dart';
import '../services/goal_tracking_service.dart';

class GoalDashboardScreen extends StatefulWidget {
  @override
  _GoalDashboardScreenState createState() => _GoalDashboardScreenState();
}

class _GoalDashboardScreenState extends State<GoalDashboardScreen> {
  final GoalService _goalService = GoalService();
  final GoalTrackingService _trackingService = GoalTrackingService();
  bool _isLoading = true;
  Goal? _currentGoal;
  GoalProgress? _progress;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentGoal = await _goalService.getGoal();
      if (_currentGoal != null) {
        _progress = await _trackingService.getGoalProgress(_currentGoal!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로딩 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_currentGoal == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('설정된 목표가 없습니다.'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/goal-setting');
              },
              child: Text('목표 설정하기'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('목표 대시보드'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareGoal(),
          ),
          IconButton(
            icon: Icon(Icons.verified),
            onPressed: () => _verifyGoal(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalSummary(),
              SizedBox(height: 24),
              _buildProgressChart(),
              SizedBox(height: 24),
              _buildDailyTracking(),
              SizedBox(height: 24),
              _buildRecommendation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 목표',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            _buildGoalItem('목표 유형', _currentGoal!.goalType),
            _buildGoalItem('시작일', _currentGoal!.startDate.toString().split(' ')[0]),
            _buildGoalItem('목표일', _currentGoal!.targetDate.toString().split(' ')[0]),
            _buildGoalItem('목표 체중', '${_currentGoal!.targetWeight}kg'),
            _buildGoalItem('목표 칼로리', '${_currentGoal!.targetCalories}kcal'),
            _buildGoalItem('목표 걸음 수', '${_currentGoal!.targetSteps}걸음'),
            _buildGoalItem('목표 물 섭취량', '${_currentGoal!.targetWater}ml'),
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

  Widget _buildProgressChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '진행 상황',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _progress?.dailyTracking
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.progress))
                          .toList() ??
                          [],
                      isCurved: true,
                      colors: [Theme.of(context).primaryColor],
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressIndicator('일간', _progress?.dailyProgress ?? 0),
                _buildProgressIndicator('주간', _progress?.weeklyProgress ?? 0),
                _buildProgressIndicator('월간', _progress?.monthlyProgress ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double progress) {
    return Column(
      children: [
        Text(label),
        SizedBox(height: 8),
        CircularProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey[200],
        ),
        SizedBox(height: 8),
        Text('${progress.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildDailyTracking() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘의 기록',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            _buildTrackingItem('현재 체중', '${_progress?.dailyTracking.last.currentWeight ?? 0}kg'),
            _buildTrackingItem('칼로리 섭취', '${_progress?.dailyTracking.last.caloriesConsumed ?? 0}kcal'),
            _buildTrackingItem('걸음 수', '${_progress?.dailyTracking.last.stepsTaken ?? 0}걸음'),
            _buildTrackingItem('물 섭취량', '${_progress?.dailyTracking.last.waterConsumed ?? 0}ml'),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => _updateDailyTracking(),
                child: Text('오늘의 기록 업데이트'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingItem(String label, String value) {
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

  Widget _buildRecommendation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '목표 추천',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => _getRecommendedGoal(),
                child: Text('새로운 목표 추천받기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareGoal() async {
    if (_currentGoal == null) return;

    try {
      final success = await _trackingService.shareGoal(_currentGoal!, 'general');
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('목표가 성공적으로 공유되었습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목표 공유 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _verifyGoal() async {
    if (_currentGoal == null) return;

    // TODO: 이미지 선택 기능 구현
    final images = <String>[];
    try {
      final success = await _trackingService.verifyGoal(_currentGoal!, images);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('목표가 성공적으로 인증되었습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목표 인증 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _updateDailyTracking() async {
    // TODO: 일일 기록 업데이트 화면으로 이동
  }

  Future<void> _getRecommendedGoal() async {
    try {
      final recommendedGoal = await _trackingService.getRecommendedGoal();
      if (recommendedGoal != null) {
        // TODO: 추천 목표 표시 화면으로 이동
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목표 추천 중 오류가 발생했습니다: $e')),
      );
    }
  }
} 