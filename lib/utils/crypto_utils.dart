import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  // 비밀번호 해시화
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // 비밀번호 검증
  static bool verifyPassword(String password, String hashedPassword) {
    final hashedInput = hashPassword(password);
    return hashedInput == hashedPassword;
  }

  // JWT 토큰 생성
  static String generateToken(String userId, {Duration? expiration}) {
    final now = DateTime.now();
    final exp = expiration != null ? now.add(expiration) : now.add(const Duration(minutes: 30));
    
    final header = {
      'alg': 'HS256',
      'typ': 'JWT'
    };
    
    final payload = {
      'sub': userId,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': exp.millisecondsSinceEpoch ~/ 1000,
    };

    final encodedHeader = base64Url.encode(utf8.encode(json.encode(header)));
    final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
    
    // 실제 구현에서는 서버의 비밀 키를 사용해야 합니다
    final signature = Hmac(sha256, utf8.encode('your-secret-key'))
        .convert(utf8.encode('$encodedHeader.$encodedPayload'))
        .bytes;
    
    final encodedSignature = base64Url.encode(signature);
    
    return '$encodedHeader.$encodedPayload.$encodedSignature';
  }

  // 토큰 검증
  static bool verifyToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = json.decode(
        utf8.decode(base64Url.decode(parts[1]))
      );

      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return exp > now;
    } catch (e) {
      return false;
    }
  }
} 