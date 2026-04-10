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

    _server!.listen((Socket client) {
      _clients.add(client);
      final buffer = StringBuffer();

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
              // Emitir al stream → ChatRepository lo escucha y lo pasa a la UI
              _messageController.add(message);
              // Retransmitir a los demás clientes (excepto quien lo envió)
              final encoded = utf8.encode('$part\n');
              _broadcastToOthers(encoded, client);
            } catch (e) {
              print("❌ [TcpServerService] Error al decodificar: $e");
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

  // broadcast() solo envía por red — NO agrega al stream local.
  // ChatRepository se encarga de la inyección local del mensaje propio.
  Future<void> broadcast(Message message) async {
    final data = utf8.encode('${jsonEncode(message.toMap())}\n');
    for (final client in _clients) {
      client.add(data);
    }
  }

  void dispose() => _messageController.close();
}