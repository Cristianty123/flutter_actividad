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
    final targetIp = info.groupOwnerAddress ?? '192.168.49.1';

    // Notifica a todos via TCP que vas a hablar
    // Los demas abriran sus sockets UDP al recibir este mensaje
    await _chat.sendMessage(Message(
      id: DateTime.now().toString(),
      senderId: targetIp,
      senderName: 'Sistema',
      content: 'CALL_START',
      timestamp: DateTime.now(),
      type: MessageType.audio,
    ));

    await _audio.startListening(9001);           // puerto UDP para recibir
    await _audio.startStreaming(targetIp, 9001); // se empieza a enviar la voz
  }
}