import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../../domain/exceptions/NetworkException.dart';
import '../../domain/model/Message.dart';

class TcpClientService {
  Socket? _socket;
  // Guardamos la suscripción del socket para poder cancelarla
  StreamSubscription? _socketSubscription;

  final _messageController = StreamController<Message>.broadcast();
  Stream<Message> get messageStream => _messageController.stream;

  Future<void> connect(String ipAddress, int port) async {
    try {
      // 1. Si ya había un socket o suscripción, los cerramos primero
      await _socketSubscription?.cancel();
      await _socket?.close();

      _socket = await Socket.connect(ipAddress, port);
      print("🔌 [TcpClientService] Conectado exitosamente a $ipAddress:$port");

      final StringBuffer _buffer = StringBuffer();

      // 2. Guardamos la suscripción en la variable
      _socketSubscription = _socket!.listen(
            (data) {
          final decoded = utf8.decode(data);
          _buffer.write(decoded);
          final raw = _buffer.toString();
          final parts = raw.split('\n');

          _buffer.clear();
          _buffer.write(parts.last);

          for (int i = 0; i < parts.length - 1; i++) {
            final part = parts[i].trim();
            if (part.isEmpty) continue;
            try {
              final json = jsonDecode(part);
              final message = Message.fromMap(json);
              print("✉️ [TcpClientService] Mensaje procesado: ${message.content}");
              _messageController.add(message);
            } catch (e) {
              print("❌ [TcpClientService] Error al decodificar JSON: $e");
            }
          }
        },
        onError: (e) {
          print("❌ [TcpClientService] Error en el socket: $e");
          // No lanzamos excepción aquí para no romper el stream,
          // mejor manejamos la desconexión
        },
        onDone: () {
          print("🔌 [TcpClientService] Socket cerrado");
        },
        cancelOnError: true, // Importante: cancelar si hay error
      );
    } catch (e) {
      print("❌ [TcpClientService] Fallo al conectar: $e");
      rethrow;
    }
  }

  Future<void> send(Message message) async {
    if (_socket == null) {
      print("❌ [TcpClientService] Error: Socket nulo");
      throw MessageSendException('Socket no conectado');
    }
    final data = utf8.encode('${jsonEncode(message.toMap())}\n');
    _socket!.add(data);
    print("📤 [TcpClientService] Datos enviados");
  }

  Future<void> disconnect() async {
    // 3. Limpiamos todo al desconectar
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _socket?.close();
    _socket = null;
    print("🔌 [TcpClientService] Recursos liberados");
  }

  void dispose() {
    _socketSubscription?.cancel();
    _messageController.close();
  }
}