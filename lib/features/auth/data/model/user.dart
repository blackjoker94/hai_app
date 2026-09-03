class User {
  final String userId;
  final bool isAdmin;
  final String name;
  final String nationalId;
  final String address;
  final String email;
  final int points;

  User({
    required this.userId,
    required this.isAdmin,
    required this.name,
    required this.nationalId,
    required this.address,
    this.email = '',
    this.points = 0,
  });

  factory User.fromFirestore(Map<String, dynamic> json, String docId) {
    return User(
      userId: docId,
      isAdmin: json['isAdmin'] as bool? ?? false,
      name: json['name'] as String? ?? '',
      nationalId: json['nationalId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: (json['userId'] ?? json['uid'] ?? json['_id']) as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
      name: json['name'] as String? ?? '',
      nationalId: json['nationalId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isAdmin': isAdmin,
      'name': name,
      'nationalId': nationalId,
      'address': address,
      'email': email,
      'points': points,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isAdmin': isAdmin,
      'name': name,
      'nationalId': nationalId,
      'address': address,
      'email': email,
      'points': points,
    };
  }
}