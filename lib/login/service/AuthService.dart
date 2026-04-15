import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../model/Users.dart';
import 'database/DatabaseHelper.dart';

class AuthService {
  final String baseUrl = "http://10.153.72.75:8080/authenticate";

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Map<String, dynamic>> login(String username, String password) async {
    // 1. Verificar conexión
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        // 2. Intento de Login Online
        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"username": username, "password": password}),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // 3. ¡ÉXITO ONLINE! Guardamos en SQLite para la próxima vez que esté offline
          await _dbHelper.saveUserLocal(Users(username: username, password: password));

          return {"success": true, "message": "Login Online Exitoso", "token": data['token']};
        } else {
          return {"success": false, "message": "Credenciales inválidas en el servidor"};
        }
      } catch (e) {
        // Si el servidor está caído pero hay internet, intentamos offline por si acaso
        return await _attemptOfflineLogin(username, password);
      }
    } else {
      // 4. MODO OFFLINE
      return await _attemptOfflineLogin(username, password);
    }
  }

  Future<Map<String, dynamic>> _attemptOfflineLogin(String username, String password) async {
    Users? localUser = await _dbHelper.checkOfflineLogin(username, password);
    if (localUser != null) {
      return {"success": true, "message": "Login Offline Exitoso", "offline": true};
    } else {
      return {"success": false, "message": "No hay datos locales. Conéctate a internet primero."};
    }
  }

  // El registro SIEMPRE debe ser online para evitar duplicados en el Back
  Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "Registrado en la nube exitosamente"};
      } else {
        return {"success": false, "message": "Error al registrar: Usuario quizás ya existe"};
      }
    } catch (e) {
      return {"success": false, "message": "Error de red: No se pudo registrar"};
    }
  }
}