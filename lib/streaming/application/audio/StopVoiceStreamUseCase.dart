import '../../domain/model/Message.dart';
import '../../domain/repository/IAudioRepository.dart';
import '../../domain/repository/IChatRepository.dart';

class StopVoiceStreamUseCase {
  final IAudioRepository _audio;
  final IChatRepository _chat;

  StopVoiceStreamUseCase(this._audio, this._chat);

  Future<void> execute() async {
    await _audio.stopStreaming();
    await _audio.stopListening();

    // Notifica a todos que terminó la llamada
    await _chat.sendMessage(Message(
      id: DateTime.now().toString(),
      senderId: 'sistema',
      senderName: 'Sistema',
      content: 'CALL_END',
      timestamp: DateTime.now(),
      type: MessageType.system,
    ));
  }
}