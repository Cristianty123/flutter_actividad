class Users {
  final int? id;
  final String username;
  final String? password;
  final bool biometricEnabled;       // ← nuevo campo

  Users({
    this.id,
    required this.username,
    this.password,
    this.biometricEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'biometric_enabled': biometricEnabled ? 1 : 0,
    };
  }

  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      biometricEnabled: (map['biometric_enabled'] ?? 0) == 1,
    );
  }
}