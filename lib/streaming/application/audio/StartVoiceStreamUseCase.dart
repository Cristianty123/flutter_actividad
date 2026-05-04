import '../../domain/model/Message.dart';
import '../../domain/repository/IAudioRepository.dart';
import '../../domain/repository/IChatRepository.dart';
import '../../domain/repository/IUserRepository.dart';
import '../../domain/repository/IWifiDirectRepository.dart';

class StartVoiceStreamUseCase {
  final IAudioRepository _audio;
  final IWifiDirectRepository _wifi;
  final IChatRepository _chat;
  final IUserRepository _user; // ← agregar

  StartVoiceStreamUseCase(this._audio, this._wifi, this._chat, this._user);

  Future<void> execute() async {
    final info = await _wifi.getConnectionInfo();
    final myIp = await _user.getIpAddress();
    final myName = await _user.getUsername() ?? 'Anónimo';

    String targetIp;
    if (info.isGroupOwner) {
      targetIp = '192.168.49.255'; // broadcast de la subred Wi-Fi Direct
    } else {
      // El cliente siempre envía al GO
      targetIp = info.groupOwnerAddress ?? '192.168.49.1';
      if (targetIp.startsWith('/')) targetIp = targetIp.substring(1);
    }

    await _chat.sendMessage(Message(
      id: DateTime.now().toString(),
      senderId: myIp,
      senderName: myName,
      content: 'CALL_START',
      timestamp: DateTime.now(),
      type: MessageType.audio,
    ));

    await _audio.startListening(9001);
    await _audio.startStreaming(targetIp, 9001);
  }

  Future<void> executeAudioOnly() async {
    final info = await _wifi.getConnectionInfo();

    String targetIp;
    if (info.isGroupOwner) {
      targetIp = '192.168.49.255'; // broadcast
    } else {
      targetIp = info.groupOwnerAddress ?? '192.168.49.1';
      if (targetIp.startsWith('/')) targetIp = targetIp.substring(1);
    }

    await _audio.startListening(9001);
    await _audio.startStreaming(targetIp, 9001);
  }
}