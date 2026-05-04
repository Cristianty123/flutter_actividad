import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../model/Users.dart';

class DatabaseHelper {
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
    String path = join(await getDatabasesPath(), 'p5_local_lab.db');
    return await openDatabase(
      path,
      version: 2,                        // ← subimos versión para migrar
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE users_local("
              "id INTEGER PRIMARY KEY, "
              "username TEXT UNIQUE, "
              "password TEXT, "
              "biometric_enabled INTEGER DEFAULT 0"   // ← nuevo campo
              ")",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migración segura: añade la columna si ya existía la DB
          await db.execute(
            "ALTER TABLE users_local ADD COLUMN biometric_enabled INTEGER DEFAULT 0",
          );
        }
      },
    );
  }

  Future<void> saveUserLocal(Users user) async {
    final db = await database;
    await db.insert(
      'users_local',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Users?> checkOfflineLogin(String username, String password) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users_local',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return maps.isNotEmpty ? Users.fromMap(maps.first) : null;
  }

  /// Activa la biometría para un usuario ya guardado
  Future<void> enableBiometric(String username) async {
    final db = await database;
    await db.update(
      'users_local',
      {'biometric_enabled': 1},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  /// Obtiene el usuario que tiene biometría activa (para login sin contraseña)
  Future<Users?> getUserWithBiometric() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users_local',
      where: 'biometric_enabled = ?',
      whereArgs: [1],
      limit: 1,
    );
    return maps.isNotEmpty ? Users.fromMap(maps.first) : null;
  }

  Future<void> clearLocalData() async {
    final db = await database;
    await db.delete('users_local');
  }
}