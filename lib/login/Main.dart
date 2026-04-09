import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'widget/LoginScreen.dart';
import 'widget/RegisterScreen.dart';
import 'component/P5ErrorDialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Pasamos a StatefulWidget para que el "oído" de internet esté siempre activo
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _avisoMostrado = false;

  // Clave para mostrar el diálogo sin importar en qué pantalla estés
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        if (!_avisoMostrado) {
          _mostrarAvisoOffline();
          _avisoMostrado = true;
        }
      } else {
        // Si vuelve el internet, reseteamos para que pueda avisar si se vuelve a ir
        _avisoMostrado = false;
      }
    });
  }

  void _mostrarAvisoOffline() {
    // Usamos el navigatorKey para que el diálogo salga sobre la pantalla actual
    final context = navigatorKey.currentState?.overlay?.context;
    if (context != null) {
      P5ErrorDialog.show(
          context,
          "ESTADO: OFFLINE",
          "No se ha encontrado una conexion a internet"
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // <--- CRUCIAL para que el diálogo funcione globalmente
      debugShowCheckedModeBanner: false,
      title: 'Lab Login',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}