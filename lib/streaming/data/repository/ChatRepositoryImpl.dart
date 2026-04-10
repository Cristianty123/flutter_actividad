import 'dart:async';
import '../../domain/model/Message.dart';
import '../../domain/repository/IChatRepository.dart';
import '../../infrastructure/network/TcpClientService.dart';
import '../../infrastructure/network/TcpServerService.dart';

class ChatRepositoryImpl implements IChatRepository {
  final TcpServerService _server;
  final TcpClientService _client;
  bool _isGroupOwner = false;

  static const int chatPort = 8888;

  final StreamController<Message> _unifiedMessageController =
  StreamController<Message>.broadcast();

  // Guardamos las suscripciones para poder cancelarlas
  StreamSubscription? _serverSub;
  StreamSubscription? _clientSub;

  ChatRepositoryImpl(this._server, this._client);

  @override
  Stream<Message> get messageStream => _unifiedMessageController.stream;

  @override
  Future<void> startServer() async {
    _isGroupOwner = true;

    // Cancelar suscripción previa si existía
    await _serverSub?.cancel();

    await _server.start(chatPort);
    print("🏠 [ChatRepository] Servidor iniciado en puerto $chatPort");

    // Solo escuchamos el stream del servidor (mensajes que llegan de clientes remotos)
    _serverSub = _server.messageStream.listen((m) {
      print("📥 [ChatRepository] Recibido en servidor: ${m.content}");
      _unifiedMessageController.add(m);
    });
  }

  @override
  Future<void> connectToServer(String ipAddress) async {
    _isGroupOwner = false;

    String cleanIp = ipAddress.startsWith('/') ? ipAddress.substring(1) : ipAddress;
    print("📱 [ChatRepository] Conectando a $cleanIp:$chatPort");

    // Cancelar suscripción previa si existía
    await _clientSub?.cancel();

    try {
      await _client.connect(cleanIp, chatPort);
    } catch (e) {
      print("❌ [ChatRepository] Error al conectar: $e");
      rethrow;
    }

    // Solo escuchamos el stream del cliente (mensajes que llegan del servidor)
    _clientSub = _client.messageStream.listen((m) {
      print("📥 [ChatRepository] Recibido en cliente: ${m.content}");
      _unifiedMessageController.add(m);
    });
  }

  @override
  Future<void> sendMessage(Message message) async {
    print("📤 [ChatRepository] Enviando: ${message.content}");

    try {
      if (_isGroupOwner) {
        // broadcast() en TcpServerService solo envía a clientes, NO al stream local
        await _server.broadcast(message);
      } else {
        await _client.send(message);
      }

      // Inyección local UNA sola vez — aquí y solo aquí
      _unifiedMessageController.add(message);
      print("✅ [ChatRepository] Mensaje propio añadido localmente");
    } catch (e) {
      print("❌ [ChatRepository] Error al enviar: $e");
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    print("🔌 [ChatRepository] Desconectando...");
    await _serverSub?.cancel();
    await _clientSub?.cancel();
    _serverSub = null;
    _clientSub = null;

    if (_isGroupOwner) {
      await _server.stop();
    } else {
      await _client.disconnect();
    }
  }

  void dispose() {
    _serverSub?.cancel();
    _clientSub?.cancel();
    _unifiedMessageController.close();
  }
}