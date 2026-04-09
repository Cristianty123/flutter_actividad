class Users {
  final int? id;
  final String username;
  final String? password; // Solo para validación local

  Users({this.id, required this.username, this.password});

  // Para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {'id': id, 'username': username, 'password': password};
  }

  // Para leer de SQLite o API
  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      id: map['id'],
      username: map['username'],
      password: map['password'],
    );
  }
}