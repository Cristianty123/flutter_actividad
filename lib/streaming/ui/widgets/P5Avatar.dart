import 'package:flutter/material.dart';
import '../theme/P5Theme.dart';

class P5Avatar extends StatelessWidget {
  final String? avatarPath;   // foto local, null = inicial
  final String name;          // para mostrar la inicial
  final Color accentColor;    // el color del rombo de cada usuario

  const P5Avatar({
    super.key,
    required this.name,
    this.avatarPath,
    this.accentColor = kPersonaRed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kAvatarWidth,
      height: kAvatarHeight,
      child: CustomPaint(
        painter: _AvatarPainter(accentColor: accentColor),
        child: ClipPath(
          clipper: _AvatarClipper(),
          child: avatarPath != null
              ? Image.asset(avatarPath!, fit: BoxFit.cover)
              : _InitialFallback(name: name),
        ),
      ),
    );
  }
}

class _InitialFallback extends StatelessWidget {
  final String name;
  const _InitialFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, right: 8),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: kPersonaWhite,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

// Pinta las 3 capas de fondo: negra, blanca y de color
class _AvatarPainter extends CustomPainter {
  final Color accentColor;
  _AvatarPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Capa negra (la más exterior)
    canvas.drawPath(
      _blackBox(size),
      Paint()..color = kPersonaBlack,
    );
    // Capa blanca (borde interior)
    canvas.drawPath(
      _whiteBox(size),
      Paint()..color = kPersonaWhite,
    );
    // Capa de color del usuario
    canvas.drawPath(
      _colorBox(size),
      Paint()..color = accentColor,
    );
  }

  // Traducción directa de avatarBlackBox() en Avatar.kt
  Path _blackBox(Size s) {
    final p = Path();
    p.moveTo(0, _d(17));
    p.lineTo(_d(100.5), _d(27.2));
    p.lineTo(_d(110), _d(72.7));
    p.lineTo(_d(33.4), _d(90));
    p.close();
    return p;
  }

  // Traducción de avatarWhiteBox()
  Path _whiteBox(Size s) {
    final p = Path();
    p.moveTo(_d(16.4), _d(20.5));
    p.lineTo(_d(96.7), _d(30.4));
    p.lineTo(_d(106.4), _d(70));
    p.lineTo(_d(37.8), _d(80.4));
    p.close();
    return p;
  }

  // Traducción de avatarColoredBox()
  Path _colorBox(Size s) {
    final p = Path();
    p.moveTo(_d(22.5), _d(28));
    p.lineTo(_d(94.4), _d(31.4));
    p.lineTo(_d(104.3), _d(67.5));
    p.lineTo(_d(40), _d(76.6));
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.accentColor != accentColor;
}

// Recorta la imagen para que no se salga del rombo
class _AvatarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(_d(10.3), _d(-5.6));
    p.lineTo(_d(114.7), _d(-5.6));
    p.lineTo(_d(114.7), _d(65.6));
    p.lineTo(_d(40), _d(76.6));
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_AvatarClipper old) => false;
}

// En Flutter los CustomPainter ya trabajan en logical pixels
// igual que dp en Kotlin, así que _d() es 1:1
double _d(double value) => value;