import '../../domain/model/Message.dart';
import '../../domain/repository/IAudioRepository.dart';
import '../../domain/repository/IChatRepository.dart';
import '../../domain/repository/IWifiDirectRepository.dart';

class StartVoiceStreamUseCase {
  final IAudioRepository _audio;
  final IWifiDirectRepository _wifi;
  final IChatRepository _chat;

  StartVoiceStreamUseCase(this._audio, this._wifi, this._chat);

  Future<void> execute() async {
    final info = await _wifi.getConnectionInfo();
    String targetIp = info.groupOwnerAddress ?? '192.168.49.1';

    // mismo fix que en ChatRepositoryImpl
    if (targetIp.startsWith('/')) targetIp = targetIp.substring(1);

    await _chat.sendMessage(Message(
      id: DateTime.now().toString(),
      senderId: targetIp,
      senderName: 'Sistema',
      content: 'CALL_START',
      timestamp: DateTime.now(),
      type: MessageType.audio,
    ));

    await _audio.startListening(9001);
    await _audio.startStreaming(targetIp, 9001);
  }
}