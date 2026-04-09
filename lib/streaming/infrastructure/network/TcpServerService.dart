import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../../domain/model/Message.dart';

class TcpServerService {
  ServerSocket? _server;
  final List<Socket> _clients = [];
  final _messageController = StreamController<Message>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;

  Future<void> start(int port) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);

    // Cada vez que un cliente se conecta
    _server!.listen((Socket client) {
      _clients.add(client);

      client.listen(
            (data) {
          final json = jsonDecode(utf8.decode(data));
          final message = Message.fromMap(json);

          // Agrega al stream local
          _messageController.add(message);

          // Retransmite a todos los demás clientes (lógica del GO)
          _broadcastToOthers(data, client);
        },
        onDone: () => _clients.remove(client),
        onError: (_) => _clients.remove(client),
      );
    });
  }

  void _broadcastToOthers(List<int> data, Socket sender) {
    for (final client in _clients) {
      if (client != sender) {
        client.add(data);
      }
    }
  }

  Future<void> stop() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close();
  }

  Future<void> broadcast(Message message) async {
    final data = utf8.encode(jsonEncode(message.toMap()));

    // Lo agrega al stream local para que la UI del GO también lo vea
    _messageController.add(message);

    // Lo envía a todos los clientes conectados
    for (final client in _clients) {
      client.add(data);
    }
  }

  void dispose() => _messageController.close();
}