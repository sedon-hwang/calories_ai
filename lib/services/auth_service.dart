import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/crypto_utils.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _authTokenKey = 'auth_token';
  
  final ApiService _apiService = ApiService();

  Future<bool> signUp(User user) async {
    try {
      // 서버에 회원가입 요청
      final response = await _apiService.signUp(user);
      
      // 로컬에 사용자 정보 저장
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      
      return true;
    } catch (e) {
      print('회원가입 중 오류 발생: $e');
      return false;
    }
  }

  Future<bool> isEmailAvailable(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson == null) return true;

      final user = User.fromJson(jsonDecode(userJson));
      return user.email != email;
    } catch (e) {
      print('이메일 확인 중 오류 발생: $e');
      return false;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      // 서버에 로그인 요청
      final response = await _apiService.signIn(email, password);
      
      // 토큰 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, response['token']);
      
      // 사용자 정보 저장
      final user = User.fromJson(response['user']);
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      
      return user;
    } catch (e) {
      print('로그인 중 오류 발생: $e');
      return null;
    }
  }
}
