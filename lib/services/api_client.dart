import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';

class ApiClient {
  static const String baseUrl = 'http://10.58.62.75:8000/v1'; // 맥북의 로컬 IP로 변경
  
  // 이미지 업로드 및 음식 감지
  Future<Map<String, dynamic>> detectFood(File imageFile) async {
    try {
      // 멀티파트 요청 생성
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/detect'));
      
      // 이미지 파일 추가
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: basename(imageFile.path),
      );
      request.files.add(multipartFile);

      // 요청 전송
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to detect food: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 음식 분류 수정
  Future<Map<String, dynamic>> updateFoodClassification({
    required String imageId,
    required String foodName,
    required int itemIndex,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-classification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image_id': imageId,
          'food_name': foodName,
          'item_index': itemIndex,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update classification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
} 