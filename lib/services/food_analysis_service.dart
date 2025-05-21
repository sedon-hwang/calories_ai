import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/food_analysis_model.dart';
import 'api_service.dart';

class FoodAnalysisService {
  static final FoodAnalysisService _instance = FoodAnalysisService._internal();
  factory FoodAnalysisService() => _instance;
  FoodAnalysisService._internal();

  final ApiService _apiService = ApiService();

  // 음식 이미지 분석
  Future<FoodAnalysis> analyzeFoodImage(File imageFile) async {
    try {
      // 이미지 업로드
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      // 이미지 분석 API 호출
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/food/analyze'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return FoodAnalysis.fromJson(jsonDecode(responseBody));
      } else {
        throw Exception('음식 분석 실패: $responseBody');
      }
    } catch (e) {
      print('음식 분석 중 오류 발생: $e');
      rethrow;
    }
  }

  // 음식 검색
  Future<List<FoodAnalysis>> searchFood(String query) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/food/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => FoodAnalysis.fromJson(item)).toList();
      } else {
        throw Exception('음식 검색 실패: ${response.body}');
      }
    } catch (e) {
      print('음식 검색 중 오류 발생: $e');
      rethrow;
    }
  }

  // 최근 분석 기록 조회
  Future<List<FoodAnalysis>> getRecentAnalyses() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/food/recent'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => FoodAnalysis.fromJson(item)).toList();
      } else {
        throw Exception('최근 분석 기록 조회 실패: ${response.body}');
      }
    } catch (e) {
      print('최근 분석 기록 조회 중 오류 발생: $e');
      rethrow;
    }
  }

  // 일일 영양소 섭취량 조회
  Future<Map<String, double>> getDailyNutrition(DateTime date) async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/food/daily-nutrition/${date.toIso8601String()}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'calories': data['calories'].toDouble(),
          'carbohydrates': data['carbohydrates'].toDouble(),
          'protein': data['protein'].toDouble(),
          'fat': data['fat'].toDouble(),
        };
      } else {
        throw Exception('일일 영양소 섭취량 조회 실패: ${response.body}');
      }
    } catch (e) {
      print('일일 영양소 섭취량 조회 중 오류 발생: $e');
      rethrow;
    }
  }
} 