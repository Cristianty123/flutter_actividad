import '../../domain/repository/IChatRepository.dart';
import '../../domain/repository/IUserRepository.dart';
import '../../domain/repository/IWifiDirectRepository.dart';

class InitializeChatUseCase {
  final IChatRepository _chat;
  final IWifiDirectRepository _wifi;
  final IUserRepository _user;

  InitializeChatUseCase(this._chat, this._wifi, this._user);

  Future<void> execute() async {
    final info = await _wifi.getConnectionInfo();

    // Guardamos la IP propia para usarla como senderId en los mensajes
    await _user.saveIpAddress(
      info.isGroupOwner ? '192.168.49.1' : info.groupOwnerAddress!,
    );

    if (info.isGroupOwner) {
      await _chat.startServer();
    } else {
      await _chat.connectToServer(info.groupOwnerAddress!);
    }
  }
}