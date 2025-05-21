import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';
import 'api_service.dart';

class FoodDatabaseService {
  static final FoodDatabaseService _instance = FoodDatabaseService._internal();
  factory FoodDatabaseService() => _instance;
  FoodDatabaseService._internal();

  final ApiService _apiService = ApiService();
  final String _baseUrl = '${ApiService.baseUrl}/foods';

  // 음식 검색
  Future<List<Food>> searchFoods(String query) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Food.fromJson(item)).toList();
      } else {
        throw Exception('음식 검색 실패: ${response.body}');
      }
    } catch (e) {
      print('음식 검색 중 오류 발생: $e');
      rethrow;
    }
  }

  // 카테고리별 음식 목록 조회
  Future<List<Food>> getFoodsByCategory(String category) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/category/$category'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Food.fromJson(item)).toList();
      } else {
        throw Exception('카테고리별 음식 조회 실패: ${response.body}');
      }
    } catch (e) {
      print('카테고리별 음식 조회 중 오류 발생: $e');
      rethrow;
    }
  }

  // 음식 상세 정보 조회
  Future<Food> getFoodDetails(String foodId) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$foodId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Food.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('음식 상세 정보 조회 실패: ${response.body}');
      }
    } catch (e) {
      print('음식 상세 정보 조회 중 오류 발생: $e');
      rethrow;
    }
  }

  // 음식 이미지 분석 결과 매칭
  Future<List<Food>> matchFoodImage(String imageUrl, {bool isMultiFood = false}) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/match'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'imageUrl': imageUrl,
          'isMultiFood': isMultiFood,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Food.fromJson(item)).toList();
      } else {
        throw Exception('음식 이미지 매칭 실패: ${response.body}');
      }
    } catch (e) {
      print('음식 이미지 매칭 중 오류 발생: $e');
      rethrow;
    }
  }

  // 자주 찾는 음식 목록 조회
  Future<List<Food>> getFrequentlySearchedFoods() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/frequent'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Food.fromJson(item)).toList();
      } else {
        throw Exception('자주 찾는 음식 목록 조회 실패: ${response.body}');
      }
    } catch (e) {
      print('자주 찾는 음식 목록 조회 중 오류 발생: $e');
      rethrow;
    }
  }

  // 음식 데이터베이스 업데이트 (관리자용)
  Future<void> updateFoodDatabase(List<Food> foods) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(foods.map((food) => food.toJson()).toList()),
      );

      if (response.statusCode != 200) {
        throw Exception('음식 데이터베이스 업데이트 실패: ${response.body}');
      }
    } catch (e) {
      print('음식 데이터베이스 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }
} 