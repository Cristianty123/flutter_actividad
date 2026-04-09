import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/P5Theme.dart';

class P5TypingIndicator extends StatefulWidget {
  final bool visible;

  const P5TypingIndicator({super.key, required this.visible});

  @override
  State<P5TypingIndicator> createState() => _P5TypingIndicatorState();
}

class _P5TypingIndicatorState extends State<P5TypingIndicator> {
  bool _dot1 = false, _dot2 = false, _dot3 = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _startAnimation();
  }

  @override
  void didUpdateWidget(P5TypingIndicator old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _startAnimation();
    } else if (!widget.visible && old.visible) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    _runLoop();
  }

  void _stopAnimation() {
    _timer?.cancel();
    setState(() {
      _dot1 = false;
      _dot2 = false;
      _dot3 = false;
    });
  }

  Future<void> _runLoop() async {
    // Traducción exacta del DotsState de TypingIndicator.kt
    while (mounted && widget.visible) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _dot1 = true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _dot2 = true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _dot3 = true);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _dot1 = false);
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() => _dot2 = false);
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() => _dot3 = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return SizedBox(
      width: kAvatarWidth,
      height: kAvatarHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: CustomPaint(
          painter: _TypingBubblePainter(
            dot1: _dot1,
            dot2: _dot2,
            dot3: _dot3,
          ),
        ),
      ),
    );
  }
}

class _TypingBubblePainter extends CustomPainter {
  final bool dot1, dot2, dot3;

  _TypingBubblePainter({
    required this.dot1,
    required this.dot2,
    required this.dot3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = kPersonaWhite;
    final redPaint = Paint()..color = kPersonaRed;

    // Burbuja base (misma forma que Entry pero sin texto)
    final bubblePath = Path();
    bubblePath.moveTo(_d(31.7), _d(3.1));
    bubblePath.lineTo(size.width * 0.8, 0);
    bubblePath.lineTo(size.width * 0.8 - _d(23), size.height * 0.7);
    bubblePath.lineTo(_d(15.6), size.height * 0.7 - _d(8));
    bubblePath.close();
    canvas.drawPath(bubblePath, whitePaint);

    // Los 3 puntitos rojos
    final centerY = size.height * 0.35;
    final dotRadius = 4.0;

    if (dot1) canvas.drawCircle(Offset(_d(45), centerY), dotRadius, redPaint);
    if (dot2) canvas.drawCircle(Offset(_d(60), centerY), dotRadius, redPaint);
    if (dot3) canvas.drawCircle(Offset(_d(75), centerY), dotRadius, redPaint);
  }

  @override
  bool shouldRepaint(_TypingBubblePainter old) =>
      old.dot1 != dot1 || old.dot2 != dot2 || old.dot3 != dot3;
}

double _d(double value) => value;