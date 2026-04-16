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
    await _socketSubscription?.cancel();
    await _socket?.close();

    const maxRetries = 5;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print("🔌 [TcpClientService] Intento $attempt/$maxRetries → $ipAddress:$port");
        _socket = await Socket.connect(
          ipAddress,
          port,
          timeout: const Duration(seconds: 5),
        );
        print("✅ [TcpClientService] Conectado a $ipAddress:$port");

        final buffer = StringBuffer();

        _socketSubscription = _socket!.listen(
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
                print("✉️ [TcpClientService] Mensaje: ${message.content}");
                _messageController.add(message);
              } catch (e) {
                print("❌ [TcpClientService] Error JSON: $e");
              }
            }
          },
          onError: (e) => print("❌ [TcpClientService] Error socket: $e"),
          onDone: () => print("🔌 [TcpClientService] Socket cerrado"),
          cancelOnError: true,
        );

        return; // éxito, salir del loop

      } catch (e) {
        print("⚠️ [TcpClientService] Intento $attempt fallido: $e");
        if (attempt < maxRetries) {
          print("⏳ Reintentando en ${retryDelay.inSeconds}s...");
          await Future.delayed(retryDelay);
        } else {
          print("❌ [TcpClientService] Agotados los reintentos");
          rethrow;
        }
      }
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