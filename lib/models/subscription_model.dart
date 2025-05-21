enum SubscriptionType {
  basic,    // 하루 3회 업로드
  premium,  // 무제한 업로드
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionType type;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final int remainingUploads;  // basic 구독의 경우 남은 업로드 횟수

  Subscription({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.price,
    this.remainingUploads = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'price': price,
      'remainingUploads': remainingUploads,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      userId: json['userId'],
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      price: json['price'].toDouble(),
      remainingUploads: json['remainingUploads'] ?? 0,
    );
  }

  bool get isActive => DateTime.now().isBefore(endDate);
  bool get canUpload => type == SubscriptionType.premium || remainingUploads > 0;
} 