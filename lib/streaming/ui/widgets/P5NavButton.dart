import 'package:flutter/material.dart';
import '../theme/P5Theme.dart';

class P5NavButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool pointsLeft; // true = atrás, false = siguiente (como el original)

  const P5NavButton({
    super.key,
    required this.onTap,
    this.pointsLeft = false,
  });

  @override
  State<P5NavButton> createState() => _P5NavButtonState();
}

class _P5NavButtonState extends State<P5NavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Transform.scale(
          scaleX: widget.pointsLeft ? -1 : 1,
          child: CustomPaint(
            size: const Size(130, 57),
            painter: _NextButtonPainter(),
          ),
        ),
      ),
    );
  }
}

// Traducción exacta del next.xml — círculo blanco + flecha + forma angular negra
class _NextButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = kPersonaBlack;
    final white = Paint()..color = kPersonaWhite;

    // Forma angular negra de fondo (el polígono irregular del next.xml)
    final bgPath = Path();
    // Escala los puntos del pathData original (viewportWidth=130, viewportHeight=57)
    final sx = size.width / 130;
    final sy = size.height / 57;

    bgPath.moveTo(47.24 * sx, 3.82 * sy);
    bgPath.lineTo(60.8 * sx, 4.69 * sy);
    bgPath.lineTo(64.65 * sx, 10.83 * sy);
    bgPath.lineTo(65.92 * sx, 4.01 * sy);
    bgPath.lineTo(77.18 * sx, 7.10 * sy);
    bgPath.lineTo(78.38 * sx, 12.84 * sy);
    bgPath.lineTo(87.26 * sx, 9.16 * sy);
    bgPath.lineTo(91.69 * sx, 15.31 * sy);
    bgPath.lineTo(101.05 * sx, 15.47 * sy);
    bgPath.lineTo(101.93 * sx, 8.47 * sy);
    bgPath.lineTo(114.0 * sx, 4.01 * sy);
    bgPath.lineTo(115.68 * sx, 12.37 * sy);
    bgPath.lineTo(119.69 * sx, 12.49 * sy);
    bgPath.lineTo(122.13 * sx, 20.81 * sy);
    bgPath.lineTo(119.08 * sx, 23.79 * sy);
    bgPath.lineTo(119.38 * sx, 29.48 * sy);
    bgPath.lineTo(126.33 * sx, 34.40 * sy);
    bgPath.lineTo(117.97 * sx, 47.66 * sy);
    bgPath.lineTo(109.87 * sx, 42.77 * sy);
    bgPath.lineTo(105.98 * sx, 44.83 * sy);
    bgPath.lineTo(100.63 * sx, 44.72 * sy);
    bgPath.lineTo(98.64 * sx, 43.38 * sy);
    bgPath.lineTo(95.89 * sx, 44.98 * sy);
    bgPath.lineTo(85.81 * sx, 45.22 * sy);
    bgPath.lineTo(84.40 * sx, 41.66 * sy);
    bgPath.lineTo(80.18 * sx, 43.05 * sy);
    bgPath.lineTo(78.37 * sx, 48.19 * sy);
    bgPath.lineTo(79.97 * sx, 51.67 * sy);
    bgPath.lineTo(65.42 * sx, 52.20 * sy);
    bgPath.lineTo(63.17 * sx, 47.24 * sy);
    bgPath.lineTo(60.61 * sx, 51.21 * sy);
    bgPath.lineTo(46.67 * sx, 51.51 * sy);
    bgPath.close();
    canvas.drawPath(bgPath, black);

    // Círculo blanco de la izquierda (el que tiene la flecha)
    final circleCenter = Offset(24.72 * sx, 27.48 * sy);
    final outerR = 21.36 * sx;
    final innerR = (21.36 - 1.68) * sx; // grosor del anillo
    canvas.drawCircle(circleCenter, outerR, white);
    canvas.drawCircle(circleCenter, innerR, black);

    // Flecha dentro del círculo
    final arrowPath = Path();
    arrowPath.moveTo(21.02 * sx, 38.99 * sy);
    arrowPath.lineTo(16.91 * sx, 36.94 * sy);
    arrowPath.lineTo(26.37 * sx, 27.48 * sy);
    arrowPath.lineTo(16.91 * sx, 18.02 * sy);
    arrowPath.lineTo(21.02 * sx, 15.96 * sy);
    arrowPath.lineTo(32.53 * sx, 27.48 * sy);
    arrowPath.close();
    canvas.drawPath(arrowPath, white);
  }

  @override
  bool shouldRepaint(_NextButtonPainter old) => false;
}