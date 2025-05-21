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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      password: json['password'] ?? '',
      birthDate: DateTime.parse(json['birthDate']),
      gender: json['gender'],
      height: json['height'].toDouble(),
      weight: json['weight'].toDouble(),
      activityLevel: json['activityLevel'],
    );
  }
}
