import 'dart:async';
import '../../domain/model/Message.dart';
import '../../domain/repository/IChatRepository.dart';
import '../../infrastructure/network/TcpClientService.dart';
import '../../infrastructure/network/TcpServerService.dart';

class ChatRepositoryImpl implements IChatRepository {
  final TcpServerService _server;
  final TcpClientService _client;
  bool _isGroupOwner = false;

  // Puerto estandarizado para evitar errores de conexión rechazada
  static const int chatPort = 8888;

  // Controlador unificado para que la UI vea TODO (enviados y recibidos)
  final StreamController<Message> _unifiedMessageController = StreamController<Message>.broadcast();

  ChatRepositoryImpl(this._server, this._client) {
    // Escuchamos lo que llega desde el socket (otros dispositivos)
    // y lo enviamos al flujo de la UI
    _server.messageStream.listen((m) {
      print("📥 [ChatRepository] Mensaje recibido vía Servidor: ${m.content}");
      _unifiedMessageController.add(m);
    });

    _client.messageStream.listen((m) {
      print("📥 [ChatRepository] Mensaje recibido vía Cliente: ${m.content}");
      _unifiedMessageController.add(m);
    });
  }

  @override
  Stream<Message> get messageStream => _unifiedMessageController.stream;

  @override
  Future<void> startServer() async {
    _isGroupOwner = true;
    print("🏠 [ChatRepository] Iniciando Servidor en puerto $chatPort");
    await _server.start(chatPort);
  }

  @override
  Future<void> connectToServer(String ipAddress) async {
    _isGroupOwner = false;

    // CORRECCIÓN CRUCIAL: Limpiamos la barra '/' que manda Android
    // para evitar el error de "Failed host lookup"
    String cleanIp = ipAddress;
    if (ipAddress.startsWith('/')) {
      cleanIp = ipAddress.substring(1);
    }

    print("📱 [ChatRepository] Conectando a $cleanIp en puerto $chatPort");

    try {
      await _client.connect(cleanIp, chatPort);
    } catch (e) {
      print("❌ [ChatRepository] Error al conectar el cliente: $e");
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(Message message) async {
    print("📤 [ChatRepository] Intentando enviar: ${message.content}");

    try {
      if (_isGroupOwner) {
        // El Servidor envía a todos los clientes conectados
        await _server.broadcast(message);
      } else {
        // El Cliente envía al Servidor
        await _client.send(message);
      }

      // INYECCIÓN LOCAL: Para que tú veas tu propio mensaje en pantalla
      // solo si el envío por socket no falló.
      _unifiedMessageController.add(message);
      print("🔄 [ChatRepository] Mensaje propio inyectado localmente");

    } catch (e) {
      print("❌ [ChatRepository] Error al enviar mensaje: $e");
      // Opcional: podrías inyectar un mensaje de error al stream para la UI
    }
  }

  @override
  Future<void> disconnect() async {
    print("🔌 [ChatRepository] Desconectando servicios...");
    if (_isGroupOwner) {
      await _server.stop();
    } else {
      await _client.disconnect();
    }
  }

  void dispose() {
    _unifiedMessageController.close();
  }
}