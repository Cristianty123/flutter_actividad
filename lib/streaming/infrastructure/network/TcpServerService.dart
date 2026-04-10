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
      final buffer = StringBuffer(); // buffer POR cliente

      client.listen(
            (data) {
          buffer.write(utf8.decode(data));
          final raw = buffer.toString();
          final parts = raw.split('\n');
          buffer.clear();
          buffer.write(parts.last);

          for (int i = 0; i < parts.length - 1; i++) {
            final part = parts[i].trim();
            if (part.isEmpty) continue;
            try {
              final json = jsonDecode(part);
              final message = Message.fromMap(json);
              _messageController.add(message);
              // Retransmitir el string con \n
              final encoded = utf8.encode('$part\n');
              _broadcastToOthers(encoded, client);
            } catch (e) {
              // ignorar
            }
          }
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
    final data = utf8.encode('${jsonEncode(message.toMap())}\n');
    _messageController.add(message);
    for (final client in _clients) {
      client.add(data);
    }
  }

  void dispose() => _messageController.close();
}