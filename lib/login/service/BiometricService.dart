import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Verifica si el dispositivo tiene biometría disponible
  static Future<bool> isAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Devuelve qué tipos de biometría tiene el dispositivo
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Lanza el prompt biométrico. Devuelve true si el usuario se autenticó.
  static Future<Map<String, dynamic>> authenticate({
    required String reason,
  }) async {
    try {
      final bool result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,       // Solo cara/huella, sin PIN de respaldo
          stickyAuth: true,           // Mantiene el diálogo si la app pasa a background
          useErrorDialogs: true,
        ),
      );
      return {"success": result, "message": result ? "Autenticación exitosa" : "Autenticación cancelada"};
    } on PlatformException catch (e) {
      String msg;
      switch (e.code) {
        case auth_error.notAvailable:
          msg = "Biometría no disponible en este dispositivo";
          break;
        case auth_error.notEnrolled:
          msg = "No hay cara/huella registrada en el sistema";
          break;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          msg = "Biometría bloqueada por demasiados intentos";
          break;
        default:
          msg = "Error biométrico: ${e.message}";
      }
      return {"success": false, "message": msg};
    }
  }
}