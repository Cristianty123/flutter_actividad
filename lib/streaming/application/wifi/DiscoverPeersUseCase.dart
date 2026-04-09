import '../../domain/repository/IWifiDirectRepository.dart';

class DiscoverPeersUseCase {
  final IWifiDirectRepository _wifi;

  DiscoverPeersUseCase(this._wifi);

  Future<void> execute() => _wifi.discoverPeers();
}