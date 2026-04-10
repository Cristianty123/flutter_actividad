import 'package:flutter_actividad/streaming/domain/model/ConnectionStatus.dart';
import 'package:flutter_actividad/streaming/domain/model/ConnectionInfo.dart';
import 'package:flutter_actividad/streaming/domain/model/PeerDevice.dart';

abstract class IWifiDirectRepository {

  //1. Saber que esta pasando con la conexión wifi direct
  Stream<ConnectionStatus> get statusStream;

  //2. Saber que peers aparecen/desaparecen
  Stream<List<PeerDevice>> get peersStream;

  //3. buscar dispositivos cercanos
  Future<void> discoverPeers();

  //4. conectarse a uno de los peers encontrados
  Future<void> connectToPeer(PeerDevice peer);

  //5. Después de conectar saber si eres GO o cliente y obtener la IP del GO
  Future<ConnectionInfo> getConnectionInfo();

  //6. Salir del grupo
  Future<void> disconnect();
}