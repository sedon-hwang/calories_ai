class User {
  final String name;
  final String email;
  final String password;
  final DateTime birthDate;
  final String gender;
  final double height;
  final double weight;
  final String activityLevel;

  User({
    required this.name,
    required this.email,
    required this.password,
    required this.birthDate,
    required this.gender,
    required this.height,
    required this.weight,
    required this.activityLevel,
  });

  // JSON 직렬화를 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password, // 실제 구현시에는 비밀번호를 해시화해야 합니다
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
    };
  }

  // JSON 역직렬화를 위한 팩토리 생성자
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      password: json['password'],
      birthDate: DateTime.parse(json['birthDate']),
      gender: json['gender'],
      height: json['height'].toDouble(),
      weight: json['weight'].toDouble(),
      activityLevel: json['activityLevel'],
    );
  }
} 