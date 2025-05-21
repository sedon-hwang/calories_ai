import 'dart:convert';
import 'package:shared_preferences.dart';
import '../models/goal_model.dart';
import '../models/goal_tracking_model.dart';
import 'api_service.dart';
import 'notification_service.dart';

class GoalTrackingService {
  static const String _trackingKey = 'goal_tracking';
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  // 일일 목표 추적 데이터 저장
  Future<bool> saveDailyTracking(GoalTracking tracking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      // 서버에 추적 데이터 저장
      final response = await _apiService.saveGoalTracking(token, tracking);
      
      // 로컬에 추적 데이터 저장
      final trackingJson = jsonEncode(tracking.toJson());
      await prefs.setString('${_trackingKey}_${tracking.date.toIso8601String()}', trackingJson);

      // 목표 진행률 확인 및 알림
      final goal = await _apiService.getGoal(token);
      final progress = goal.calculateProgress(tracking);
      
      if (progress >= 100) {
        await _notificationService.showGoalAchievementNotification(
          title: '🎉 목표 달성!',
          body: '축하합니다! 목표를 달성하셨습니다.',
        );
      }

      return true;
    } catch (e) {
      print('목표 추적 데이터 저장 중 오류 발생: $e');
      return false;
    }
  }

  // 일일 목표 추적 데이터 조회
  Future<GoalTracking?> getDailyTracking(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return null;

      // 서버에서 추적 데이터 조회
      final tracking = await _apiService.getGoalTracking(token, date);
      
      // 로컬에 추적 데이터 저장
      final trackingJson = jsonEncode(tracking.toJson());
      await prefs.setString('${_trackingKey}_${date.toIso8601String()}', trackingJson);
      
      return tracking;
    } catch (e) {
      // 서버 조회 실패 시 로컬 데이터 사용
      final prefs = await SharedPreferences.getInstance();
      final trackingJson = prefs.getString('${_trackingKey}_${date.toIso8601String()}');
      if (trackingJson == null) return null;
      
      return GoalTracking.fromJson(jsonDecode(trackingJson));
    }
  }

  // 목표 진행 상황 조회
  Future<GoalProgress> getGoalProgress(Goal goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('인증 토큰이 없습니다.');

      // 서버에서 진행 상황 조회
      final progress = await _apiService.getGoalProgress(token, goal);
      
      // 로컬에 진행 상황 저장
      final progressJson = jsonEncode(progress.toJson());
      await prefs.setString('${_trackingKey}_progress', progressJson);
      
      return progress;
    } catch (e) {
      // 서버 조회 실패 시 로컬 데이터 사용
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('${_trackingKey}_progress');
      if (progressJson == null) {
        // 로컬 데이터도 없는 경우 빈 진행 상황 반환
        return GoalProgress(
          dailyProgress: 0.0,
          weeklyProgress: 0.0,
          monthlyProgress: 0.0,
          dailyTracking: [],
          weeklyTracking: [],
          monthlyTracking: [],
        );
      }
      
      return GoalProgress.fromJson(jsonDecode(progressJson));
    }
  }

  // 목표 공유
  Future<bool> shareGoal(Goal goal, String platform) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      return await _apiService.shareGoal(token, goal, platform);
    } catch (e) {
      print('목표 공유 중 오류 발생: $e');
      return false;
    }
  }

  // 목표 인증
  Future<bool> verifyGoal(Goal goal, List<String> images) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      return await _apiService.verifyGoal(token, goal, images);
    } catch (e) {
      print('목표 인증 중 오류 발생: $e');
      return false;
    }
  }

  // 목표 추천
  Future<Goal> getRecommendedGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('인증 토큰이 없습니다.');

      return await _apiService.getRecommendedGoal(token);
    } catch (e) {
      print('목표 추천 중 오류 발생: $e');
      rethrow;
    }
  }
} 