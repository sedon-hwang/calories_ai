import 'dart:convert';
import 'package:shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/crypto_utils.dart';
import 'email_service.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _resetTokenKey = 'reset_token';
  static const String _authTokenKey = 'auth_token';
  
  final EmailService _emailService = EmailService();
  final ApiService _apiService = ApiService();

  // 회원가입 처리
  Future<bool> signUp(User user) async {
    try {
      // 서버에 회원가입 요청
      final response = await _apiService.signUp(user);
      
      // 로컬에 사용자 정보 저장
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      return await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('회원가입 중 오류 발생: $e');
      return false;
    }
  }

  // 이메일 중복 확인
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

  // 로그인 처리
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

  // 비밀번호 재설정 이메일 전송
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      // 서버에 비밀번호 재설정 요청
      final success = await _apiService.sendPasswordResetEmail(email);
      if (!success) return false;

      // 로컬에 토큰 저장
      final prefs = await SharedPreferences.getInstance();
      final resetToken = CryptoUtils.generateToken(email, expiration: const Duration(minutes: 30));
      await prefs.setString(_resetTokenKey, resetToken);
      
      // 이메일 전송
      return await _emailService.sendPasswordResetEmail(email, resetToken);
    } catch (e) {
      print('비밀번호 재설정 이메일 전송 중 오류 발생: $e');
      return false;
    }
  }

  // 비밀번호 재설정 토큰 확인
  Future<bool> verifyResetToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_resetTokenKey);
      if (savedToken == null) return false;

      // 토큰 유효성 검사
      if (!CryptoUtils.verifyToken(token)) {
        await prefs.remove(_resetTokenKey);
        return false;
      }

      return savedToken == token;
    } catch (e) {
      print('토큰 확인 중 오류 발생: $e');
      return false;
    }
  }

  // 비밀번호 재설정
  Future<bool> resetPassword(String email, String token, String newPassword) async {
    try {
      // 서버에 비밀번호 재설정 요청
      final success = await _apiService.resetPassword(email, token, newPassword);
      if (!success) return false;

      // 로컬 사용자 정보 업데이트
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson == null) return false;

      final user = User.fromJson(jsonDecode(userJson));
      if (user.email != email) return false;

      // 새 비밀번호로 사용자 정보 업데이트
      final updatedUser = User(
        name: user.name,
        email: user.email,
        password: newPassword,
        birthDate: user.birthDate,
        gender: user.gender,
        height: user.height,
        weight: user.weight,
        activityLevel: user.activityLevel,
      );

      // 사용자 정보 저장
      final success = await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      if (success) {
        // 재설정 토큰 삭제
        await prefs.remove(_resetTokenKey);
      }
      return success;
    } catch (e) {
      print('비밀번호 재설정 중 오류 발생: $e');
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      
      if (token != null) {
        // 서버에 로그아웃 요청
        await _apiService.signOut(token);
      }
      
      // 로컬 토큰 삭제
      await prefs.remove(_authTokenKey);
    } catch (e) {
      print('로그아웃 중 오류 발생: $e');
    }
  }

  // 현재 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      if (token == null) return false;

      // 토큰 유효성 검사
      if (!CryptoUtils.verifyToken(token)) {
        await prefs.remove(_authTokenKey);
        return false;
      }

      return true;
    } catch (e) {
      print('로그인 상태 확인 중 오류 발생: $e');
      return false;
    }
  }

  // 사용자 프로필 업데이트
  Future<bool> updateProfile(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      if (token == null) return false;

      // 서버에 프로필 업데이트 요청
      final updatedUser = await _apiService.updateUserProfile(token, user);
      
      // 로컬 사용자 정보 업데이트
      final userJson = jsonEncode(updatedUser.toJson());
      return await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('프로필 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  // 사용자 프로필 조회
  Future<User?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      if (token == null) return null;

      // 서버에서 프로필 정보 조회
      final user = await _apiService.getUserProfile(token);
      
      // 로컬 사용자 정보 업데이트
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      
      return user;
    } catch (e) {
      print('프로필 조회 중 오류 발생: $e');
      return null;
    }
  }
} 