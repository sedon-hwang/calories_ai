import 'dart:convert';
import 'package:shared_preferences.dart';
import '../models/goal_model.dart';
import 'api_service.dart';

class GoalService {
  static const String _goalKey = 'user_goal';
  final ApiService _apiService = ApiService();

  // 목표 설정
  Future<bool> setGoal(Goal goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      // 서버에 목표 저장
      final response = await _apiService.setGoal(token, goal);
      
      // 로컬에 목표 저장
      final goalJson = jsonEncode(goal.toJson());
      return await prefs.setString(_goalKey, goalJson);
    } catch (e) {
      print('목표 설정 중 오류 발생: $e');
      return false;
    }
  }

  // 목표 조회
  Future<Goal?> getGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return null;

      // 서버에서 목표 조회
      final goal = await _apiService.getGoal(token);
      
      // 로컬에 목표 저장
      final goalJson = jsonEncode(goal.toJson());
      await prefs.setString(_goalKey, goalJson);
      
      return goal;
    } catch (e) {
      // 서버 조회 실패 시 로컬 데이터 사용
      final prefs = await SharedPreferences.getInstance();
      final goalJson = prefs.getString(_goalKey);
      if (goalJson == null) return null;
      
      return Goal.fromJson(jsonDecode(goalJson));
    }
  }

  // 목표 업데이트
  Future<bool> updateGoal(Goal goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      // 서버에 목표 업데이트
      final response = await _apiService.updateGoal(token, goal);
      
      // 로컬에 목표 업데이트
      final goalJson = jsonEncode(goal.toJson());
      return await prefs.setString(_goalKey, goalJson);
    } catch (e) {
      print('목표 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  // 목표 삭제
  Future<bool> deleteGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      // 서버에서 목표 삭제
      final success = await _apiService.deleteGoal(token);
      if (!success) return false;
      
      // 로컬에서 목표 삭제
      return await prefs.remove(_goalKey);
    } catch (e) {
      print('목표 삭제 중 오류 발생: $e');
      return false;
    }
  }

  // 목표 달성률 계산
  Future<double> calculateProgress(double currentWeight) async {
    try {
      final goal = await getGoal();
      if (goal == null) return 0.0;
      
      return goal.calculateProgress(currentWeight);
    } catch (e) {
      print('목표 달성률 계산 중 오류 발생: $e');
      return 0.0;
    }
  }
} 