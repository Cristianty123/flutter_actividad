import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../transitions/P5Transitions.dart';
import '../component/P5MenuButton.dart'; // IMPORTA EL NUEVO COMPONENTE
import 'ConnectionStatus.dart';
import 'LoginScreen.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: const [ConnectionStatus()]
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            child: ClipPath(
              clipper: BottomJaggedClipper(),
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 300,
                  color: const Color(0xFFD32F2F)
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _collageTitle("HELLO,"),
                const SizedBox(height: 20),
                _usernameCollage(username),
                const SizedBox(height: 60),

                // USANDO EL NUEVO COMPONENTE ANIMADO
                P5MenuButton(
                  label: "CERRAR SESIÓN",
                  icon: Icons.logout,
                  onTap: () => Navigator.of(context).pushReplacement(
                      P5Transitions.createRoute(const LoginScreen())
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (tus métodos _usernameCollage, _collageTitle y BottomJaggedClipper se quedan igual)

  Widget _usernameCollage(String name) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: name.toUpperCase().split('').map((char) {
        if (char == ' ') return const SizedBox(width: 20);
        bool isDarkBackground = math.Random().nextBool();
        double randomAngle = (math.Random().nextDouble() - 0.5) * 0.4;

        return Transform.rotate(
          angle: randomAngle,
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkBackground ? Colors.black : Colors.white,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(4, 4))
              ],
            ),
            child: Text(
              char,
              style: TextStyle(
                color: isDarkBackground ? Colors.white : Colors.black,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _collageTitle(String text) {
    return Transform.rotate(
      angle: 0.1,
      child: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.white,
        child: Text(text,
            style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900)
        ),
      ),
    );
  }
}

class BottomJaggedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width * 0.6, size.height * 0.1);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(0, size.height * 0.2);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}