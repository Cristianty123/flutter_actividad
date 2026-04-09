import '../../domain/model/Message.dart';
import '../../domain/repository/IChatRepository.dart';

class WatchMessagesUseCase {
  final IChatRepository _chat;

  WatchMessagesUseCase(this._chat);

  Stream<Message> execute() => _chat.messageStream;
}