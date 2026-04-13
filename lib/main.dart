import 'package:flutter/material.dart';

// Importaciones de los diferentes módulos con alias
import 'calculadora/calculadora.dart' as calc;
import 'login/Main.dart' as p5_login;
import 'parcial/app.dart' as parcial;
// Para el streaming, como tiene una inicialización compleja, 
// importaremos lo necesario para recrear su arranque
import 'streaming/AppDependencies.dart' as st_deps;
import 'streaming/ui/screens/SetupScreen.dart' as st_ui;
import 'streaming/infrastructure/permissions/PermissionService.dart' as st_perm;
import 'streaming/infrastructure/wifi/WifiDirectService.dart';
import 'streaming/infrastructure/network/TcpServerService.dart';
import 'streaming/infrastructure/network/TcpClientService.dart';
import 'streaming/infrastructure/audio/AudioService.dart';
import 'streaming/data/repository/WifiDirectRepositoryImpl.dart';
import 'streaming/data/repository/ChatRepositoryImpl.dart';
import 'streaming/data/repository/AudioRepositoryImpl.dart';
import 'streaming/data/repository/UserRepositoryImpl.dart';
import 'streaming/application/wifi/DiscoverPeersUseCase.dart';
import 'streaming/application/wifi/ConnectToPeerUseCase.dart';
import 'streaming/application/wifi/DisconnectUseCase.dart';
import 'streaming/application/chat/InitializeChatUseCase.dart';
import 'streaming/application/chat/SendMessageUseCase.dart';
import 'streaming/application/chat/WatchMessagesUseCase.dart';
import 'streaming/application/chat/SendTypingStatusUseCase.dart';
import 'streaming/application/chat/SetUsernameUseCase.dart';
import 'streaming/application/chat/SetAvatarUseCase.dart';
import 'streaming/application/audio/StartVoiceStreamUseCase.dart';
import 'streaming/application/audio/StopVoiceStreamUseCase.dart';
import 'streaming/ui/viewmodel/SetupViewModel.dart';
import 'streaming/ui/viewmodel/DiscoveryViewModel.dart';
import 'streaming/ui/viewmodel/ChatViewModel.dart';

void main() {
  runApp(const ModuleLauncherApp());
}

class ModuleLauncherApp extends StatelessWidget {
  const ModuleLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selector de Proyectos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const ModuleSelectorScreen(),
    );
  }
}

class ModuleSelectorScreen extends StatelessWidget {
  const ModuleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS PROYECTOS FLUTTER'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[50],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModuleCard(
            context,
            title: 'Calculadora',
            subtitle: 'Operaciones matemáticas básicas',
            icon: Icons.calculate,
            color: Colors.deepPurple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const calc.MyApp())),
          ),
          _buildModuleCard(
            context,
            title: 'Login Persona 5',
            subtitle: 'Interfaz estilizada con animaciones',
            icon: Icons.login,
            color: const Color(0xFFD32F2F),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const p5_login.MyApp())),
          ),
          _buildModuleCard(
            context,
            title: 'Conecta Local (Parcial)',
            subtitle: 'App de servicios y emprendedores',
            icon: Icons.store,
            color: const Color(0xFF4F46E5),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const parcial.EmprendeApp())),
          ),
          _buildModuleCard(
            context,
            title: 'Phantom Chat (Streaming)',
            subtitle: 'P2P Chat con Wi-Fi Direct',
            icon: Icons.chat_bubble,
            color: Colors.black,
            onTap: () => _launchStreaming(context),
          ),
          _buildModuleCard(
            context,
            title: 'Actividad Inicial',
            subtitle: 'Colores favoritos y Stack',
            icon: Icons.palette,
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActividadScreen(title: 'Actividad'))),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // Recreamos la lógica del main de streaming para que funcione desde aquí
  Future<void> _launchStreaming(BuildContext context) async {
    final permissions = st_perm.PermissionService();
    final granted = await permissions.requestAll();

    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos denegados para Streaming'))
      );
      return;
    }

    // Inicializar dependencias manualmente como en streaming/main.dart
    final wifiService = WifiDirectService();
    final tcpServer = TcpServerService();
    final tcpClient = TcpClientService();
    final audioService = AudioService();

    await wifiService.initialize();
    await audioService.initialize();

    final wifiRepo = WifiDirectRepositoryImpl(wifiService);
    final chatRepo = ChatRepositoryImpl(tcpServer, tcpClient);
    final audioRepo = AudioRepositoryImpl(audioService);
    final userRepo = UserRepositoryImpl();

    final deps = st_deps.AppDependencies(
      userRepo: userRepo,
      setupVm: SetupViewModel(SetUsernameUseCase(userRepo), SetAvatarUseCase(userRepo)),
      discoveryVm: DiscoveryViewModel(
        DiscoverPeersUseCase(wifiRepo),
        ConnectToPeerUseCase(wifiRepo),
        DisconnectUseCase(wifiRepo, chatRepo),
        InitializeChatUseCase(chatRepo, wifiRepo, userRepo),
        wifiRepo,
      ),
      chatVm: ChatViewModel(
        sendMessage: SendMessageUseCase(chatRepo, userRepo),
        watchMessages: WatchMessagesUseCase(chatRepo),
        sendTypingStatus: SendTypingStatusUseCase(chatRepo, userRepo),
        startVoice: StartVoiceStreamUseCase(audioRepo, wifiRepo, chatRepo),
        stopVoice: StopVoiceStreamUseCase(audioRepo, chatRepo),
        myIp: '',
      ),
    );

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => st_ui.SetupScreen(deps: deps)));
    }
  }
}

/// Esta es tu clase original de Actividad movida aquí para el selector
class ActividadScreen extends StatefulWidget {
  const ActividadScreen({super.key, required this.title});
  final String title;
  @override
  State<ActividadScreen> createState() => _ActividadScreenState();
}

class _ActividadScreenState extends State<ActividadScreen> {
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: 20,
              left: 20,
              child: Text(
                'ACTIVIDAD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),


                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Mis colores favoritos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _crearCuadro(Colors.redAccent),
                        const SizedBox(width: 12),
                        _crearCuadro(Colors.green),
                        const SizedBox(width: 12),
                        _crearCuadro(Colors.blueAccent),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Hecho en Flutter',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ),
      )
    );
  }
  Widget _crearCuadro(Color color){
    return Container(
      width: 80,
      height: 80,
      color: color,
    );
  }
}
