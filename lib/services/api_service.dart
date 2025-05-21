import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String _baseUrl = 'https://api.calories-ai.com';
  static const Duration _timeout = Duration(seconds: 10);

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

  Future<Map<String, dynamic>> signUp(User user) async {
    try {
      // 로컬 테스트를 위해 성공 응답 반환
      return {
        'success': true,
        'message': '회원가입이 완료되었습니다.',
        'user': user.toJson(),
      };
    } catch (e) {
      throw Exception('회원가입 중 오류 발생: $e');
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      // 로컬 테스트를 위해 성공 응답 반환
      return {
        'token': 'test_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'name': 'Test User',
          'email': email,
          'birthDate': DateTime.now().toIso8601String(),
          'gender': 'male',
          'height': 170.0,
          'weight': 70.0,
          'activityLevel': '보통 (주 3-4회)',
        },
      };
    } catch (e) {
      throw Exception('로그인 중 오류 발생: $e');
    }
  }
}
