import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/goal_model.dart';

class SocialShareService {
  static final SocialShareService _instance = SocialShareService._internal();
  factory SocialShareService() => _instance;
  SocialShareService._internal();

  // 목표 공유
  Future<void> shareGoal(Goal goal, {String? platform}) async {
    final message = _createShareMessage(goal);
    
    if (platform != null) {
      await _shareToSpecificPlatform(platform, message);
    } else {
      await Share.share(message);
    }
  }

  // 목표 달성 공유
  Future<void> shareGoalAchievement(Goal goal, double progress) async {
    final message = _createAchievementMessage(goal, progress);
    await Share.share(message);
  }

  // 공유 메시지 생성
  String _createShareMessage(Goal goal) {
    final buffer = StringBuffer();
    buffer.writeln('🎯 새로운 건강 목표를 시작합니다!');
    buffer.writeln();
    buffer.writeln('목표 유형: ${goal.goalType}');
    
    if (goal.targetWeight != null) {
      buffer.writeln('목표 체중: ${goal.targetWeight}kg');
    }
    if (goal.targetCalories != null) {
      buffer.writeln('목표 칼로리: ${goal.targetCalories}kcal');
    }
    if (goal.targetSteps != null) {
      buffer.writeln('목표 걸음 수: ${goal.targetSteps}걸음');
    }
    if (goal.targetWater != null) {
      buffer.writeln('목표 물 섭취량: ${goal.targetWater}ml');
    }
    
    buffer.writeln();
    buffer.writeln('시작일: ${goal.startDate}');
    buffer.writeln('목표일: ${goal.targetDate}');
    buffer.writeln();
    buffer.writeln('#건강목표 #칼로리AI');

    return buffer.toString();
  }

  // 달성 메시지 생성
  String _createAchievementMessage(Goal goal, double progress) {
    final buffer = StringBuffer();
    buffer.writeln('🎉 목표 달성!');
    buffer.writeln();
    buffer.writeln('목표 유형: ${goal.goalType}');
    buffer.writeln('달성률: ${progress.toStringAsFixed(1)}%');
    buffer.writeln();
    buffer.writeln('시작일: ${goal.startDate}');
    buffer.writeln('달성일: ${DateTime.now()}');
    buffer.writeln();
    buffer.writeln('#목표달성 #칼로리AI');

    return buffer.toString();
  }

  // 특정 플랫폼에 공유
  Future<void> _shareToSpecificPlatform(String platform, String message) async {
    String url;
    switch (platform.toLowerCase()) {
      case 'twitter':
        url = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(message)}';
        break;
      case 'facebook':
        url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(message)}';
        break;
      case 'instagram':
        // Instagram은 URL 공유를 지원하지 않으므로 일반 공유로 대체
        await Share.share(message);
        return;
      default:
        await Share.share(message);
        return;
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      await Share.share(message);
    }
  }
} 