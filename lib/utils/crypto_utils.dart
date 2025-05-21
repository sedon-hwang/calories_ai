import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  static String generateToken(String data, {Duration? expiration}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final expirationTime = expiration != null
        ? timestamp + expiration.inMilliseconds
        : timestamp + const Duration(days: 1).inMilliseconds;
    
    final tokenData = '$data:$expirationTime';
    final bytes = utf8.encode(tokenData);
    final hash = sha256.convert(bytes);
    
    return base64Url.encode(hash.bytes);
  }

  static bool verifyToken(String token) {
    try {
      final bytes = base64Url.decode(token);
      return bytes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
