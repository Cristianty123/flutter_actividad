import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../../domain/exceptions/NetworkException.dart';
import '../../domain/model/Message.dart';

class TcpClientService {
  Socket? _socket;
  final _messageController = StreamController<Message>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;

  Future<void> connect(String ipAddress, int port) async {
    _socket = await Socket.connect(ipAddress, port);

    _socket!.listen(
          (data) {
        final json = jsonDecode(utf8.decode(data));
        final message = Message.fromMap(json);
        _messageController.add(message);
      },
      onError: (e) => throw ConnectionLostException(e.toString()),
      onDone: () => _messageController.close(),
    );
  }

  Future<void> send(Message message) async {
    if (_socket == null) throw MessageSendException('Socket no conectado');
    final data = utf8.encode(jsonEncode(message.toMap()));
    _socket!.add(data);
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  void dispose() => _messageController.close();
}