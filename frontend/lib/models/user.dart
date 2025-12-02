class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}
