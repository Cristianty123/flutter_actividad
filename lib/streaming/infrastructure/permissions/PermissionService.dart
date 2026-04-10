import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {

  /// Solicita todos los permisos necesarios según la versión de Android.
  /// Retorna true si todos los críticos fueron concedidos.
  Future<bool> requestAll() async {
    if (!Platform.isAndroid) return true;

    final permissions = _buildPermissionList();
    final results = await permissions.request();

    // Críticos: sin estos la app no puede funcionar
    final critical = [
      Permission.location,
      Permission.microphone,
    ];

    return critical.every(
          (p) => results[p] == PermissionStatus.granted,
    );
  }

  List<Permission> _buildPermissionList() {
    final list = <Permission>[
      Permission.location,
      Permission.microphone,
    ];

    // Android 13+ requiere NEARBY_WIFI_DEVICES
    // Android < 13 no lo tiene, así que lo pedimos condicionalmente
    if (Platform.isAndroid) {
      list.add(Permission.nearbyWifiDevices);
    }

    // Fotos para el avatar
    list.add(Permission.photos); // iOS
    // Android maneja esto con READ_MEDIA_IMAGES en el manifest

    return list;
  }

  Future<bool> hasLocation() =>
      Permission.location.isGranted;

  Future<bool> hasMicrophone() =>
      Permission.microphone.isGranted;
}