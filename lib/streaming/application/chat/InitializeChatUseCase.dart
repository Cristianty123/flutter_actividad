import 'package:uuid/uuid.dart';

import '../../domain/model/Message.dart';
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

    await _user.saveIpAddress(
      info.isGroupOwner ? '192.168.49.1' : info.groupOwnerAddress!,
    );

    if (info.isGroupOwner) {
      await _chat.startServer();
    } else {
      await _chat.connectToServer(info.groupOwnerAddress!);
    }

    // NUEVO: anunciarse al grupo con tu nombre
    final name = await _user.getUsername() ?? 'Anónimo';
    final ip = await _user.getIpAddress();

    await _chat.sendMessage(Message(
      id: const Uuid().v4(),
      senderId: ip,
      senderName: name,
      content: 'JOIN',
      timestamp: DateTime.now(),
      type: MessageType.system,
    ));
  }
}