import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConnectivityResult>>(
      // 1. Obtenemos el estado inicial para que no aparezca "OFFLINE" por error al cargar
      future: Connectivity().checkConnectivity(),
      builder: (context, futureSnapshot) {
        return StreamBuilder<List<ConnectivityResult>>(
          // 2. Escuchamos los cambios en tiempo real
          stream: Connectivity().onConnectivityChanged,
          initialData: futureSnapshot.data, // Usamos el dato del Future como base
          builder: (context, streamSnapshot) {
            // 3. Priorizamos el stream, si no hay nada, usamos el future, si no, asumimos none temporalmente
            final results = streamSnapshot.data ?? futureSnapshot.data ?? [ConnectivityResult.none];

            // Verificamos si hay alguna conexión activa (Wifi, Móvil, Ethernet, etc.)
            final bool isOnline = results.any((result) => result != ConnectivityResult.none);

            return Padding(
              padding: const EdgeInsets.only(right: 20, top: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rombo con el estilo de Persona 5
                  Transform.rotate(
                    angle: 0.2,
                    child: ClipPath(
                      clipper: IrregularRhombusClipper(),
                      child: AnimatedContainer( // Añadido para que el cambio de color sea suave
                        duration: const Duration(milliseconds: 300),
                        width: 100,
                        height: 40,
                        color: isOnline ? const Color(0xFF00C853) : const Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                  Text(
                    isOnline ? "ONLINE" : "OFFLINE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class IrregularRhombusClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.2, 0);
    path.lineTo(size.width, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height);
    path.lineTo(0, size.height * 0.9);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}