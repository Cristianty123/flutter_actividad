import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'AppDependencies.dart';
import 'infrastructure/permissions/PermissionService.dart';
import 'infrastructure/wifi/WifiDirectService.dart';
import 'infrastructure/network/TcpServerService.dart';
import 'infrastructure/network/TcpClientService.dart';
import 'infrastructure/audio/AudioService.dart';
import 'data/repository/WifiDirectRepositoryImpl.dart';
import 'data/repository/ChatRepositoryImpl.dart';
import 'data/repository/AudioRepositoryImpl.dart';
import 'data/repository/UserRepositoryImpl.dart';
import 'application/wifi/DiscoverPeersUseCase.dart';
import 'application/wifi/ConnectToPeerUseCase.dart';
import 'application/wifi/DisconnectUseCase.dart';
import 'application/chat/InitializeChatUseCase.dart';
import 'application/chat/SendMessageUseCase.dart';
import 'application/chat/WatchMessagesUseCase.dart';
import 'application/chat/SendTypingStatusUseCase.dart';
import 'application/chat/SetUsernameUseCase.dart';
import 'application/chat/SetAvatarUseCase.dart';
import 'application/audio/StartVoiceStreamUseCase.dart';
import 'application/audio/StopVoiceStreamUseCase.dart';
import 'ui/viewmodel/SetupViewModel.dart';
import 'ui/viewmodel/DiscoveryViewModel.dart';
import 'ui/viewmodel/ChatViewModel.dart';
import 'ui/screens/SetupScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solicitar permisos PRIMERO — antes de tocar Wi-Fi Direct o audio
  final permissions = PermissionService();
  final granted = await permissions.requestAll();

  if (!granted) {
    // Si los permisos críticos fueron denegados, mostrar pantalla de error
    runApp(const _PermissionDeniedApp());
    return;
  }

  // Infrastructure
  final wifiService = WifiDirectService();
  final tcpServer  = TcpServerService();
  final tcpClient  = TcpClientService();
  final audioService = AudioService();

  await wifiService.initialize();
  await audioService.initialize();

  // Repositories
  final wifiRepo  = WifiDirectRepositoryImpl(wifiService);
  final chatRepo  = ChatRepositoryImpl(tcpServer, tcpClient);
  final audioRepo = AudioRepositoryImpl(audioService);
  final userRepo  = UserRepositoryImpl();

  // Use cases
  final discoverPeers = DiscoverPeersUseCase(wifiRepo);
  final connectToPeer = ConnectToPeerUseCase(wifiRepo);
  final disconnect    = DisconnectUseCase(wifiRepo, chatRepo);
  final initChat      = InitializeChatUseCase(chatRepo, wifiRepo, userRepo);
  final sendMessage   = SendMessageUseCase(chatRepo, userRepo);
  final watchMessages = WatchMessagesUseCase(chatRepo);
  final sendTyping    = SendTypingStatusUseCase(chatRepo, userRepo);
  final startVoice    = StartVoiceStreamUseCase(audioRepo, wifiRepo, chatRepo);
  final stopVoice     = StopVoiceStreamUseCase(audioRepo, chatRepo);

  // IP inicial vacía — se llenará después del handshake Wi-Fi Direct
  final myIp = await userRepo.getIpAddress();

  // ViewModels
  final deps = AppDependencies(
    setupVm: SetupViewModel(
      SetUsernameUseCase(userRepo),
      SetAvatarUseCase(userRepo),
    ),
    discoveryVm: DiscoveryViewModel(
      discoverPeers,
      connectToPeer,
      disconnect,
      initChat,
      wifiRepo,
    ),
    chatVm: ChatViewModel(
      sendMessage: sendMessage,
      watchMessages: watchMessages,
      sendTypingStatus: sendTyping,
      startVoice: startVoice,
      stopVoice: stopVoice,
      myIp: myIp,
    ),
  );

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SetupScreen(deps: deps),
  ));
}

class _PermissionDeniedApp extends StatelessWidget {
  const _PermissionDeniedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: Color(0xFFC41001), size: 64),
                const SizedBox(height: 24),
                const Text(
                  'PERMISOS REQUERIDOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Esta app necesita permisos de ubicación y micrófono para funcionar.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => openAppSettings(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC41001),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Text(
                      'ABRIR AJUSTES',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}