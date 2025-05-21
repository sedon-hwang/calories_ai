class GoalTracking {
  final String goalId;
  final DateTime date;
  final double currentWeight;
  final double caloriesConsumed;
  final int stepsTaken;
  final int waterConsumed;
  final double progress; // 0.0 ~ 1.0
  final String? note;
  final List<String>? images; // 인증 사진

  GoalTracking({
    required this.goalId,
    required this.date,
    required this.currentWeight,
    required this.caloriesConsumed,
    required this.stepsTaken,
    required this.waterConsumed,
    required this.progress,
    this.note,
    this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'goalId': goalId,
      'date': date.toIso8601String(),
      'currentWeight': currentWeight,
      'caloriesConsumed': caloriesConsumed,
      'stepsTaken': stepsTaken,
      'waterConsumed': waterConsumed,
      'progress': progress,
      'note': note,
      'images': images,
    };
  }

  factory GoalTracking.fromJson(Map<String, dynamic> json) {
    return GoalTracking(
      goalId: json['goalId'],
      date: DateTime.parse(json['date']),
      currentWeight: json['currentWeight'].toDouble(),
      caloriesConsumed: json['caloriesConsumed'].toDouble(),
      stepsTaken: json['stepsTaken'],
      waterConsumed: json['waterConsumed'],
      progress: json['progress'].toDouble(),
      note: json['note'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : null,
    );
  }
}

class GoalProgress {
  final double dailyProgress;
  final double weeklyProgress;
  final double monthlyProgress;
  final List<GoalTracking> dailyTracking;
  final List<GoalTracking> weeklyTracking;
  final List<GoalTracking> monthlyTracking;

  GoalProgress({
    required this.dailyProgress,
    required this.weeklyProgress,
    required this.monthlyProgress,
    required this.dailyTracking,
    required this.weeklyTracking,
    required this.monthlyTracking,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailyProgress': dailyProgress,
      'weeklyProgress': weeklyProgress,
      'monthlyProgress': monthlyProgress,
      'dailyTracking': dailyTracking.map((t) => t.toJson()).toList(),
      'weeklyTracking': weeklyTracking.map((t) => t.toJson()).toList(),
      'monthlyTracking': monthlyTracking.map((t) => t.toJson()).toList(),
    };
  }

  factory GoalProgress.fromJson(Map<String, dynamic> json) {
    return GoalProgress(
      dailyProgress: json['dailyProgress'].toDouble(),
      weeklyProgress: json['weeklyProgress'].toDouble(),
      monthlyProgress: json['monthlyProgress'].toDouble(),
      dailyTracking: (json['dailyTracking'] as List)
          .map((t) => GoalTracking.fromJson(t))
          .toList(),
      weeklyTracking: (json['weeklyTracking'] as List)
          .map((t) => GoalTracking.fromJson(t))
          .toList(),
      monthlyTracking: (json['monthlyTracking'] as List)
          .map((t) => GoalTracking.fromJson(t))
          .toList(),
    );
  }
} 