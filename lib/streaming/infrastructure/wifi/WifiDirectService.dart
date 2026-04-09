import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import '../../domain/model/ConnectionStatus.dart';
import '../../domain/model/ConnectionInfo.dart';
import '../../domain/model/PeerDevice.dart';
import 'dart:async';

class WifiDirectService {
  final _plugin = FlutterP2pConnection();

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _peersController = StreamController<List<PeerDevice>>.broadcast();

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<List<PeerDevice>> get peersStream => _peersController.stream;

  WifiP2PInfo? _lastInfo;

  Future<void> initialize() async {
    await _plugin.initialize();
    await _plugin.register();

    // Escucha cambios de estado de la conexión
    _plugin.streamWifiP2PInfo().listen((info) {
      _lastInfo = info; // cacheamos
      if (info.isConnected) {
        _statusController.add(ConnectionStatus.connected);
      } else {
        _statusController.add(ConnectionStatus.disconnected);
      }
    });

    // Escucha peers descubiertos
    _plugin.streamPeers().listen((peers) {
      final mapped = peers.map((p) => PeerDevice(
        deviceName: p.deviceName,
        macAddress: p.deviceAddress,
      )).toList();
      _peersController.add(mapped);
    });
  }

  Future<void> discoverPeers() async {
    _statusController.add(ConnectionStatus.discovering);
    await _plugin.discover();
  }

  Future<void> connectToPeer(PeerDevice peer) async {
    _statusController.add(ConnectionStatus.connecting);
    await _plugin.connect(peer.macAddress);
  }

  Future<ConnectionInfo> getConnectionInfo() async {
    final info = _lastInfo ?? await _plugin.streamWifiP2PInfo().first;
    return ConnectionInfo(
      isGroupOwner: info.isGroupOwner,
      groupOwnerAddress: info.groupOwnerAddress,
    );
  }

  Future<void> disconnect() async {
    await _plugin.disconnect();
    await _plugin.unregister();
    _statusController.add(ConnectionStatus.disconnected);
  }

  void dispose() {
    _statusController.close();
    _peersController.close();
  }
}