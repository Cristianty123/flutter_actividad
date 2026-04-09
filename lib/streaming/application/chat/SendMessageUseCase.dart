import '../../domain/model/Message.dart';
import '../../domain/repository/IChatRepository.dart';
import '../../domain/repository/IUserRepository.dart';
import 'package:uuid/uuid.dart';

class SendMessageUseCase {
  final IChatRepository _chat;
  final IUserRepository _user;

  SendMessageUseCase(this._chat, this._user);

  Future<void> execute(String content) async {
    final name = await _user.getUsername() ?? 'Anónimo';
    final ip = await _user.getIpAddress();

    final message = Message(
      id: const Uuid().v4(),
      senderId: ip,
      senderName: name,
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    await _chat.sendMessage(message);
  }
}