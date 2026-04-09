import 'package:flutter/material.dart';
import 'P5Avatar.dart';
import '../theme/P5Theme.dart';

class P5MessageEntry extends StatelessWidget {
  final String text;
  final String senderName;
  final String? avatarPath;
  final Color accentColor;

  const P5MessageEntry({
    super.key,
    required this.text,
    required this.senderName,
    this.avatarPath,
    this.accentColor = kPersonaRed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          P5Avatar(
            name: senderName,
            avatarPath: avatarPath,
            accentColor: accentColor,
          ),
          const SizedBox(width: 0), // el overlap lo maneja el painter
          Flexible(
            child: CustomPaint(
              painter: _EntryBubblePainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(42, 20, 32, 20),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: kPersonaWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = kPersonaWhite;
    final blackPaint = Paint()..color = kPersonaBlack;

    // Orden: outerBox blanco → outerStem blanco → innerStem negro → innerBox negro
    canvas.drawPath(_outerBox(size), whitePaint);
    canvas.drawPath(_outerStem(size), whitePaint);
    canvas.drawPath(_innerStem(size), blackPaint);
    canvas.drawPath(_innerBox(size), blackPaint);
  }

  // Traducción de outerBox() en Entry.kt
  Path _outerBox(Size s) {
    final p = Path();
    p.moveTo(_d(31.7), _d(3.1));
    p.lineTo(s.width, 0);
    p.lineTo(s.width - _d(23), s.height);
    p.lineTo(_d(15.6), s.height - _d(8));
    p.close();
    return p;
  }

  // Traducción de innerBox()
  Path _innerBox(Size s) {
    final p = Path();
    p.moveTo(_d(33), _d(7.7));
    p.lineTo(s.width - _d(13), _d(3.7));
    p.lineTo(s.width - _d(25.7), s.height - _d(4.6));
    p.lineTo(_d(20.4), s.height - _d(12));
    p.close();
    return p;
  }

  // Traducción de outerStem() - el pico de la burbuja
  Path _outerStem(Size s) {
    final vertY = _getStemY(s.height);
    final p = Path();
    p.moveTo(0, vertY - _d(19.2));
    p.lineTo(_d(19.5), vertY - _d(37.2));
    p.lineTo(_d(20.8), vertY - _d(31.5));
    p.lineTo(_d(32.4), vertY - _d(39.3));
    p.lineTo(_d(30.6), vertY - _d(15.8));
    p.lineTo(_d(11.7), vertY - _d(12.6));
    p.lineTo(_d(10), vertY - _d(20));
    p.close();
    return p;
  }

  // Traducción de innerStem()
  Path _innerStem(Size s) {
    final vertY = _getStemY(s.height);
    final p = Path();
    p.moveTo(_d(4.6), vertY - _d(22.2));
    p.lineTo(_d(17), vertY - _d(33.2));
    p.lineTo(_d(19.3), vertY - _d(28.1));
    p.lineTo(_d(34.4), vertY - _d(36.5));
    p.lineTo(_d(34), vertY - _d(21.4));
    p.lineTo(_d(14.4), vertY - _d(18.6));
    p.lineTo(_d(12.8), vertY - _d(25.4));
    p.close();
    return p;
  }

  // Traducción de getStemY()
  double _getStemY(double boxHeight) {
    if (boxHeight + _d(4) > kAvatarHeight) {
      return kAvatarHeight - _d(16);
    } else {
      return boxHeight - _d(5);
    }
  }

  @override
  bool shouldRepaint(_EntryBubblePainter old) => false;
}

double _d(double value) => value;