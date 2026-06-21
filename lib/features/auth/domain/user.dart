class User {
  final int id;
  final String username;
  final String email;
  final bool isLandowner;
  final bool isDriver;
  final bool isSuperuser;
  final String? phoneNumber;
  final String? address;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.isLandowner,
    required this.isDriver,
    required this.isSuperuser,
    this.phoneNumber,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      isLandowner: json['is_landowner'] ?? false,
      isDriver: json['is_driver'] ?? false,
      isSuperuser: json['is_superuser'] ?? false,
      phoneNumber: json['phone_number'],
      address: json['address'],
    );
  }
}
