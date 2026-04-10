import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/wifi/DiscoverPeersUseCase.dart';
import '../../application/wifi/ConnectToPeerUseCase.dart';
import '../../application/wifi/DisconnectUseCase.dart';
import '../../application/chat/InitializeChatUseCase.dart';
import '../../domain/model/PeerDevice.dart';
import '../../domain/model/ConnectionStatus.dart';
import '../../domain/repository/IWifiDirectRepository.dart';

class DiscoveryViewModel extends ChangeNotifier {
  final DiscoverPeersUseCase _discoverPeers;
  final ConnectToPeerUseCase _connectToPeer;
  final DisconnectUseCase _disconnect;
  final InitializeChatUseCase _initializeChat;
  final IWifiDirectRepository _wifiRepo;

  DiscoveryViewModel(
      this._discoverPeers,
      this._connectToPeer,
      this._disconnect,
      this._initializeChat,
      this._wifiRepo,
      );

  List<PeerDevice> peers = [];
  ConnectionStatus status = ConnectionStatus.disconnected;
  String? errorMessage;
  bool get isConnected => status == ConnectionStatus.connected;
  bool get isSearching => status == ConnectionStatus.discovering;

  StreamSubscription? _peersSubscription;
  StreamSubscription? _statusSubscription;

  // Llamar desde initState de la pantalla
  void init() {
    // Cancelar suscripciones previas antes de crear nuevas
    _peersSubscription?.cancel();
    _statusSubscription?.cancel();

    // Limpiar estado al reiniciar
    peers = [];
    status = ConnectionStatus.disconnected;
    errorMessage = null;

    _peersSubscription = _wifiRepo.peersStream.listen((newPeers) {
      peers = newPeers;
      notifyListeners();
    });

    _statusSubscription = _wifiRepo.statusStream.listen((newStatus) {
      status = newStatus;
      notifyListeners();

      if (newStatus == ConnectionStatus.connected) {
        _initializeChat.execute().catchError((e) {
          errorMessage = 'Error al iniciar chat: $e';
          notifyListeners();
        });
      }
    });
  }

  Future<void> discoverPeers() async {
    errorMessage = null;
    try {
      await _discoverPeers.execute();
    } catch (e) {
      errorMessage = 'Error al buscar dispositivos: $e';
      notifyListeners();
    }
  }

  Future<void> connectTo(PeerDevice peer) async {
    errorMessage = null;
    try {
      await _connectToPeer.execute(peer);
    } catch (e) {
      errorMessage = 'Error al conectar: $e';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _disconnect.execute();
    peers = [];
    status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _peersSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}