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

    // Buffer para acumular datos fragmentados
    final StringBuffer _buffer = StringBuffer();

    _socket!.listen(
          (data) {
        _buffer.write(utf8.decode(data));

        // Procesar todos los mensajes completos que hayan llegado
        // Usamos newline como delimitador
        final raw = _buffer.toString();
        final parts = raw.split('\n');

        // El último elemento puede estar incompleto, lo guardamos
        _buffer.clear();
        _buffer.write(parts.last);

        // Procesar todos menos el último (que puede estar incompleto)
        for (int i = 0; i < parts.length - 1; i++) {
          final part = parts[i].trim();
          if (part.isEmpty) continue;
          try {
            final json = jsonDecode(part);
            final message = Message.fromMap(json);
            _messageController.add(message);
          } catch (e) {
            // ignorar chunks malformados
          }
        }
      },
      onError: (e) => throw ConnectionLostException(e.toString()),
      onDone: () => _messageController.close(),
    );
  }

  Future<void> send(Message message) async {
    if (_socket == null) throw MessageSendException('Socket no conectado');
    final data = utf8.encode('${jsonEncode(message.toMap())}\n');
    _socket!.add(data);
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  void dispose() => _messageController.close();
}