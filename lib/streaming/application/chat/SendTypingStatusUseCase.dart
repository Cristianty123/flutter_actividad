import 'package:uuid/uuid.dart';

import '../../domain/model/Message.dart';
import '../../domain/repository/IChatRepository.dart';
import '../../domain/repository/IUserRepository.dart';

class SendTypingStatusUseCase {
  final IChatRepository _chat;
  final IUserRepository _user;

  SendTypingStatusUseCase(this._chat, this._user);

  Future<void> execute(bool isTyping) async {
    final name = await _user.getUsername() ?? 'Anónimo';
    final ip = await _user.getIpAddress();

    await _chat.sendMessage(Message(
      id: const Uuid().v4(),
      senderId: ip,
      senderName: name,
      content: isTyping ? 'TYPING_START' : 'TYPING_STOP',
      timestamp: DateTime.now(),
      type: MessageType.system,
    ));
  }
}