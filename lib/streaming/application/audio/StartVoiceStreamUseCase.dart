import '../../domain/model/Message.dart';
import '../../domain/repository/IAudioRepository.dart';
import '../../domain/repository/IChatRepository.dart';
import '../../domain/repository/IWifiDirectRepository.dart';

class StartVoiceStreamUseCase {
  final IAudioRepository _audio;
  final IWifiDirectRepository _wifi;
  final IChatRepository _chat;

  StartVoiceStreamUseCase(this._audio, this._wifi, this._chat);

  /// Llamado por quien INICIA la llamada.
  /// Envía CALL_START por la red Y arranca el audio.
  Future<void> execute() async {
    final info = await _wifi.getConnectionInfo();
    String targetIp = info.groupOwnerAddress ?? '192.168.49.1';
    if (targetIp.startsWith('/')) targetIp = targetIp.substring(1);

    // Notificar a todos que la llamada comenzó
    await _chat.sendMessage(Message(
      id: DateTime.now().toString(),
      senderId: targetIp,
      senderName: 'Sistema',
      content: 'CALL_START',
      timestamp: DateTime.now(),
      type: MessageType.audio,
    ));

    // Arrancar audio
    await _audio.startListening(9001);
    await _audio.startStreaming(targetIp, 9001);
  }

  /// Llamado por quien RECIBE la llamada al presionar "Aceptar".
  /// Solo arranca el audio — NO envía CALL_START porque el llamante
  /// ya lo envió. Evita el bucle de llamadas infinitas.
  Future<void> executeAudioOnly() async {
    final info = await _wifi.getConnectionInfo();
    String targetIp = info.groupOwnerAddress ?? '192.168.49.1';
    if (targetIp.startsWith('/')) targetIp = targetIp.substring(1);

    await _audio.startListening(9001);
    await _audio.startStreaming(targetIp, 9001);
  }
}