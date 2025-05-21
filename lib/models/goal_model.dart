class Goal {
  final String userId;
  final double targetWeight;
  final double targetCalories;
  final int targetSteps;
  final int targetWater;
  final DateTime startDate;
  final DateTime targetDate;
  final String goalType; // 'weight_loss', 'weight_gain', 'maintenance'
  final double weeklyGoal; // 주간 목표 (kg)

  Goal({
    required this.userId,
    required this.targetWeight,
    required this.targetCalories,
    required this.targetSteps,
    required this.targetWater,
    required this.startDate,
    required this.targetDate,
    required this.goalType,
    required this.weeklyGoal,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'targetWeight': targetWeight,
      'targetCalories': targetCalories,
      'targetSteps': targetSteps,
      'targetWater': targetWater,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'goalType': goalType,
      'weeklyGoal': weeklyGoal,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      userId: json['userId'],
      targetWeight: json['targetWeight'].toDouble(),
      targetCalories: json['targetCalories'].toDouble(),
      targetSteps: json['targetSteps'],
      targetWater: json['targetWater'],
      startDate: DateTime.parse(json['startDate']),
      targetDate: DateTime.parse(json['targetDate']),
      goalType: json['goalType'],
      weeklyGoal: json['weeklyGoal'].toDouble(),
    );
  }

  // 목표 기간 계산 (일)
  int get durationInDays {
    return targetDate.difference(startDate).inDays;
  }

  // 목표 체중 변화량 계산 (kg)
  double get weightChange {
    return targetWeight - targetWeight;
  }

  // 일일 목표 체중 변화량 계산 (kg)
  double get dailyWeightChange {
    return weightChange / durationInDays;
  }

  // 목표 달성률 계산 (0.0 ~ 1.0)
  double calculateProgress(GoalTracking tracking) {
    double progress = 0.0;
    int completedMetrics = 0;

    // 체중 목표 진행률
    if (targetWeight != null) {
      final weightProgress = (tracking.currentWeight - targetWeight) / (tracking.currentWeight - targetWeight);
      if (weightProgress >= 0) {
        progress += weightProgress;
        completedMetrics++;
      }
    }

    // 칼로리 목표 진행률
    if (targetCalories != null) {
      final caloriesProgress = tracking.caloriesConsumed / targetCalories;
      if (caloriesProgress <= 1) {
        progress += caloriesProgress;
        completedMetrics++;
      }
    }

    // 걸음 수 목표 진행률
    if (targetSteps != null) {
      final stepsProgress = tracking.stepsTaken / targetSteps;
      if (stepsProgress <= 1) {
        progress += stepsProgress;
        completedMetrics++;
      }
    }

    // 물 섭취 목표 진행률
    if (targetWater != null) {
      final waterProgress = tracking.waterConsumed / targetWater;
      if (waterProgress <= 1) {
        progress += waterProgress;
        completedMetrics++;
      }
    }

    // 전체 진행률 계산 (평균)
    return completedMetrics > 0 ? (progress / completedMetrics) * 100 : 0.0;
  }
} 