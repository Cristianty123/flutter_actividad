import 'package:flutter/material.dart';
import '../theme/P5Theme.dart';

// Coordenadas de los dos puntos donde la línea toca cada mensaje
// Traducción de LineCoordinates en TranscriptState.kt
class P5LineCoordinates {
  final Offset leftPoint;
  final Offset rightPoint;

  const P5LineCoordinates({
    required this.leftPoint,
    required this.rightPoint,
  });
}

// Modifier equivalente — en Flutter lo hacemos como widget wrapper
// Traducción de drawConnectingLine() en connectingLineModifier.kt
class P5ConnectingLine extends StatelessWidget {
  final P5LineCoordinates topCoords;
  final P5LineCoordinates bottomCoords;
  final double progress; // 0.0 → 1.0, animado desde ChatViewModel
  final Widget child;

  const P5ConnectingLine({
    super.key,
    required this.topCoords,
    required this.bottomCoords,
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConnectingLinePainter(
        topCoords: topCoords,
        bottomCoords: bottomCoords,
        progress: progress,
      ),
      child: child,
    );
  }
}

class _ConnectingLinePainter extends CustomPainter {
  final P5LineCoordinates topCoords;
  final P5LineCoordinates bottomCoords;
  final double progress;

  _ConnectingLinePainter({
    required this.topCoords,
    required this.bottomCoords,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Interpolamos los puntos inferiores según el progreso de animación
    // Traducción de lerp(topLeft, bottomLeft, fraction = entry1.lineProgress.value)
    final currentBottomLeft = Offset.lerp(
      topCoords.leftPoint,
      bottomCoords.leftPoint,
      progress,
    )!;
    final currentBottomRight = Offset.lerp(
      topCoords.rightPoint,
      bottomCoords.rightPoint,
      progress,
    )!;

    final path = Path()
      ..moveTo(topCoords.leftPoint.dx, topCoords.leftPoint.dy)
      ..lineTo(topCoords.rightPoint.dx, topCoords.rightPoint.dy)
      ..lineTo(currentBottomRight.dx, currentBottomRight.dy)
      ..lineTo(currentBottomLeft.dx, currentBottomLeft.dy)
      ..close();

    // Sombra difuminada debajo (traducción del shadowPaint con BlurMaskFilter)
    final shadowPaint = Paint()
      ..color = kPersonaBlack.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.save();
    canvas.translate(0, 16); // translate(top = 16.dp) del original
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // La línea negra real
    canvas.drawPath(path, Paint()..color = kPersonaBlack);
  }

  @override
  bool shouldRepaint(_ConnectingLinePainter old) =>
      old.progress != progress ||
          old.topCoords != topCoords ||
          old.bottomCoords != bottomCoords;
}