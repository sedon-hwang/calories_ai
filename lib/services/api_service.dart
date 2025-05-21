import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/goal_model.dart';
import '../utils/crypto_utils.dart';

class ApiService {
  static const String _baseUrl = 'https://api.calories-ai.com'; // 실제 API 엔드포인트로 변경 필요
  static const Duration _timeout = Duration(seconds: 10);

  // HTTP 헤더 생성
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 회원가입
  Future<Map<String, dynamic>> signUp(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/signup'),
        headers: _getHeaders(),
        body: jsonEncode(user.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('회원가입 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('회원가입 중 오류 발생: $e');
    }
  }

  // 로그인
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('로그인 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('로그인 중 오류 발생: $e');
    }
  }

  // 비밀번호 재설정 이메일 전송
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      ).timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('비밀번호 재설정 이메일 전송 중 오류 발생: $e');
    }
  }

  // 비밀번호 재설정
  Future<bool> resetPassword(String email, String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password/confirm'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
        }),
      ).timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('비밀번호 재설정 중 오류 발생: $e');
    }
  }

  // 사용자 정보 업데이트
  Future<User> updateUserProfile(String token, User user) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile'),
        headers: _getHeaders(token: token),
        body: jsonEncode(user.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('프로필 업데이트 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('프로필 업데이트 중 오류 발생: $e');
    }
  }

  // 사용자 정보 조회
  Future<User> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/profile'),
        headers: _getHeaders(token: token),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('프로필 조회 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('프로필 조회 중 오류 발생: $e');
    }
  }

  // 로그아웃
  Future<bool> signOut(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _getHeaders(token: token),
      ).timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('로그아웃 중 오류 발생: $e');
    }
  }

  // 목표 설정
  Future<Goal> setGoal(String token, Goal goal) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/goals'),
        headers: _getHeaders(token: token),
        body: jsonEncode(goal.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 201) {
        return Goal.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('목표 설정 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('목표 설정 중 오류 발생: $e');
    }
  }

  // 목표 조회
  Future<Goal> getGoal(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/goals'),
        headers: _getHeaders(token: token),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return Goal.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('목표 조회 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('목표 조회 중 오류 발생: $e');
    }
  }

  // 목표 업데이트
  Future<Goal> updateGoal(String token, Goal goal) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/goals'),
        headers: _getHeaders(token: token),
        body: jsonEncode(goal.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return Goal.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('목표 업데이트 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('목표 업데이트 중 오류 발생: $e');
    }
  }

  // 목표 삭제
  Future<bool> deleteGoal(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/goals'),
        headers: _getHeaders(token: token),
      ).timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('목표 삭제 중 오류 발생: $e');
    }
  }

  // 목표 추적 데이터 저장
  Future<bool> saveGoalTracking(String token, GoalTracking tracking) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/goals/tracking'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(tracking.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('목표 추적 데이터 저장 실패: ${response.body}');
      }
    } catch (e) {
      print('목표 추적 데이터 저장 중 오류 발생: $e');
      rethrow;
    }
  }

  // 목표 추적 데이터 조회
  Future<GoalTracking> getGoalTracking(String token, DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/goals/tracking/${date.toIso8601String()}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return GoalTracking.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('목표 추적 데이터 조회 실패: ${response.body}');
      }
    } catch (e) {
      print('목표 추적 데이터 조회 중 오류 발생: $e');
      rethrow;
    }
  }

  // 목표 진행 상황 조회
  Future<GoalProgress> getGoalProgress(String token, Goal goal) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/goals/${goal.userId}/progress'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return GoalProgress.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('목표 진행 상황 조회 실패: ${response.body}');
      }
    } catch (e) {
      print('목표 진행 상황 조회 중 오류 발생: $e');
      rethrow;
    }
  }

  // 목표 공유
  Future<bool> shareGoal(String token, Goal goal, String platform) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/goals/${goal.userId}/share'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'platform': platform,
          'goal': goal.toJson(),
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('목표 공유 실패: ${response.body}');
      }
    } catch (e) {
      print('목표 공유 중 오류 발생: $e');
      rethrow;
    }
  }

  // 목표 인증
  Future<bool> verifyGoal(String token, Goal goal, List<String> images) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/goals/${goal.userId}/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'goal': goal.toJson(),
          'images': images,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('목표 인증 실패: ${response.body}');
      }
    } catch (e) {
      print('목표 인증 중 오류 발생: $e');
      rethrow;
    }
  }

  // 목표 추천
  Future<Goal> getRecommendedGoal(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/goals/recommended'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return Goal.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('목표 추천 실패: ${response.body}');
      }
    } catch (e) {
      print('목표 추천 중 오류 발생: $e');
      rethrow;
    }
  }

  // 이미지 업로드
  Future<List<String>> uploadImages(String token, List<File> images) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload/images'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      for (var image in images) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            image.path,
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final List<dynamic> urls = jsonDecode(responseBody)['urls'];
        return urls.map((url) => url.toString()).toList();
      } else {
        throw Exception('이미지 업로드 실패: $responseBody');
      }
    } catch (e) {
      print('이미지 업로드 중 오류 발생: $e');
      rethrow;
    }
  }
} 