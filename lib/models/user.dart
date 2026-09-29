class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isPremium;
  final String? avatar;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isPremium,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      avatar: json['avatar'],
      isPremium: json['subscription_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatar,
      'subscription_active': isPremium ? 1 : 0,
    };
  }
  String get fullName {
    return '$firstName $lastName';
  }
}
}
