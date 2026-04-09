import '../../domain/model/Message.dart';
import '../../domain/repository/IChatRepository.dart';
import '../../infrastructure/network/TcpClientService.dart';
import '../../infrastructure/network/TcpServerService.dart';

class ChatRepositoryImpl implements IChatRepository {
  final TcpServerService _server;
  final TcpClientService _client;
  bool _isGroupOwner = false;

  ChatRepositoryImpl(this._server, this._client);

  @override
  Stream<Message> get messageStream => _isGroupOwner
      ? _server.messageStream
      : _client.messageStream;

  @override
  Future<void> startServer() async {
    _isGroupOwner = true;
    await _server.start(8888); // puerto TCP para chat
  }

  @override
  Future<void> connectToServer(String ipAddress) async {
    _isGroupOwner = false;
    await _client.connect(ipAddress, 8888);
  }

  @override
  Future<void> sendMessage(Message message) async {
    if (_isGroupOwner) {
      // El GO inyecta el mensaje en su propio stream y lo retransmite
      await _server.broadcast(message);
    } else {
      await _client.send(message);
    }
  }

  @override
  Future<void> disconnect() async {
    if (_isGroupOwner) {
      await _server.stop();
    } else {
      await _client.disconnect();
    }
  }
}