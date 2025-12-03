class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final String? address;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.address,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatarUrl,
    String? address,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      address: json['address'] as String?,
    );
  }
}
