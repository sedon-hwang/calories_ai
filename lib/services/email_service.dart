import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // 실제 구현시에는 환경 변수나 설정 파일에서 가져와야 합니다
  static const String _smtpServer = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _username = 'your-email@gmail.com';
  static const String _password = 'your-app-password';

  Future<bool> sendPasswordResetEmail(String to, String resetToken) async {
    try {
      final smtpServer = SmtpServer(
        _smtpServer,
        port: _smtpPort,
        username: _username,
        password: _password,
        ssl: false,
        allowInsecure: true,
      );

      final message = Message()
        ..from = Address(_username, 'Calories AI')
        ..recipients.add(to)
        ..subject = '비밀번호 재설정'
        ..html = '''
          <h1>Calories AI 비밀번호 재설정</h1>
          <p>비밀번호 재설정을 요청하셨습니다.</p>
          <p>아래의 인증 코드를 입력해주세요:</p>
          <h2 style="color: #2196F3;">$resetToken</h2>
          <p>이 인증 코드는 30분 동안만 유효합니다.</p>
          <p>비밀번호 재설정을 요청하지 않으셨다면, 이 이메일을 무시하셔도 됩니다.</p>
        ''';

      final sendReport = await send(message, smtpServer);
      return sendReport.toString().contains('OK');
    } catch (e) {
      print('이메일 전송 중 오류 발생: $e');
      return false;
    }
  }
} 