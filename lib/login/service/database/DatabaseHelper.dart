import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../model/Users.dart';

class DatabaseHelper {
  // Patrón Singleton para no abrir mil conexiones a la vez
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Definimos la ruta de la base de datos en el dispositivo
    String path = join(await getDatabasesPath(), 'p5_local_lab.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // Creamos la tabla local usando los campos de tu clase Users
        return db.execute(
          "CREATE TABLE users_local("
              "id INTEGER PRIMARY KEY, "
              "username TEXT, "
              "password TEXT"
              ")",
        );
      },
    );
  }

  /// Guarda o actualiza un usuario en SQLite tras un login exitoso en el Back.
  Future<void> saveUserLocal(Users user) async {
    final db = await database;
    await db.insert(
      'users_local',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Verifica si las credenciales existen localmente para el modo OFFLINE.
  /// Retorna un objeto Users si los datos coinciden, o null si no existe.
  Future<Users?> checkOfflineLogin(String username, String password) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users_local',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      // Usamos tu factory fromMap para convertir el resultado de la DB en objeto
      return Users.fromMap(maps.first);
    }
    return null;
  }

  /// Borra todos los datos (útil para un Logout o "Limpiar datos").
  Future<void> clearLocalData() async {
    final db = await database;
    await db.delete('users_local');
  }
}