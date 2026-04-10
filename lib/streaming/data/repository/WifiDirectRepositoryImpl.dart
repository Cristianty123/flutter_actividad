import '../../domain/model/ConnectionInfo.dart';
import '../../domain/model/ConnectionStatus.dart';
import '../../domain/model/PeerDevice.dart';
import '../../domain/repository/IWifiDirectRepository.dart';
import '../../infrastructure/wifi/WifiDirectService.dart';

class WifiDirectRepositoryImpl implements IWifiDirectRepository {
  final WifiDirectService _service;

  WifiDirectRepositoryImpl(this._service);

  @override
  Stream<ConnectionStatus> get statusStream => _service.statusStream;

  @override
  Stream<List<PeerDevice>> get peersStream => _service.peersStream;

  @override
  Future<void> discoverPeers() => _service.discoverPeers();

  @override
  Future<void> connectToPeer(PeerDevice peer) => _service.connectToPeer(peer);

  @override
  Future<ConnectionInfo> getConnectionInfo() => _service.getConnectionInfo();

  @override
  Future<void> disconnect() => _service.disconnect();
}