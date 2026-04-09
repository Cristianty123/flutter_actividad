import '../../domain/repository/IChatRepository.dart';
import '../../domain/repository/IWifiDirectRepository.dart';

class DisconnectUseCase {
  final IWifiDirectRepository _wifi;
  final IChatRepository _chat;

  DisconnectUseCase(this._wifi, this._chat);

  // Cierra ambas capas limpiamente
  Future<void> execute() async {
    await _chat.disconnect();
    await _wifi.disconnect();
  }
}