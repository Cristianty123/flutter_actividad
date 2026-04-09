import 'package:flutter/material.dart';
import '../theme/P5Theme.dart';

class P5MessageReply extends StatelessWidget {
  final String text;

  const P5MessageReply({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: CustomPaint(
          painter: _ReplyBubblePainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(44, 20, 40, 20),
            child: Text(
              text,
              style: const TextStyle(
                color: kPersonaBlack,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blackPaint = Paint()..color = kPersonaBlack;
    final whitePaint = Paint()..color = kPersonaWhite;

    // Orden: outerBox negro → outerStem negro → innerStem blanco → innerBox blanco
    canvas.drawPath(_outerBox(size), blackPaint);
    canvas.drawPath(_outerStem(size), blackPaint);
    canvas.drawPath(_innerStem(size), whitePaint);
    canvas.drawPath(_innerBox(size), whitePaint);
  }

  // Traducción de replyOuterBox() - nótese que usa size.width dinámico
  Path _outerBox(Size s) {
    final p = Path();
    p.moveTo(0, 0);
    p.lineTo(s.width - _d(35), _d(4));
    p.lineTo(s.width - _d(10.7), s.height - _d(6.6));
    p.lineTo(_d(35.5), s.height);
    p.close();
    return p;
  }

  // Traducción de replyInnerBox()
  Path _innerBox(Size s) {
    final p = Path();
    p.moveTo(_d(12), _d(5));
    p.lineTo(s.width - _d(36), _d(9.5));
    p.lineTo(s.width - _d(16.4), s.height - _d(11.7));
    p.lineTo(_d(36.5), s.height - _d(3.5));
    p.close();
    return p;
  }

  // Traducción de replyOuterStem()
  Path _outerStem(Size s) {
    final vertY = s.height;
    final p = Path();
    p.moveTo(s.width - _d(37.6), vertY - _d(42.3));
    p.lineTo(s.width - _d(20.8), vertY - _d(30.2));
    p.lineTo(s.width - _d(19.4), vertY - _d(36.8));
    p.lineTo(s.width, vertY - _d(19.6));
    p.lineTo(s.width - _d(10.3), vertY - _d(19.6));
    p.lineTo(s.width - _d(12), vertY - _d(12.3));
    p.lineTo(s.width - _d(27.6), vertY - _d(15.2));
    p.close();
    return p;
  }

  // Traducción de replyInnerStem()
  Path _innerStem(Size s) {
    final vertY = s.height;
    final p = Path();
    p.moveTo(s.width - _d(33.1), vertY - _d(33.2));
    p.lineTo(s.width - _d(19.3), vertY - _d(26.3));
    p.lineTo(s.width - _d(16.4), vertY - _d(31.6));
    p.lineTo(s.width - _d(4.2), vertY - _d(21));
    p.lineTo(s.width - _d(12.4), vertY - _d(23.4));
    p.lineTo(s.width - _d(14), vertY - _d(17.2));
    p.lineTo(s.width - _d(28.6), vertY - _d(21.2));
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(_ReplyBubblePainter old) => false;
}

double _d(double value) => value;