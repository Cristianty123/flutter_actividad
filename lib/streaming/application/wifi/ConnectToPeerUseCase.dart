import '../../domain/model/PeerDevice.dart';
import '../../domain/repository/IWifiDirectRepository.dart';

class ConnectToPeerUseCase {
  final IWifiDirectRepository _wifi;

  ConnectToPeerUseCase(this._wifi);

  Future<void> execute(PeerDevice peer) => _wifi.connectToPeer(peer);
}