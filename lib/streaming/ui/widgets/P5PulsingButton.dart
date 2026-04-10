import 'package:flutter/material.dart';
import '../theme/P5Theme.dart';

class P5PulsingButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap; // null = deshabilitado
  final double angle;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsets padding;

  const P5PulsingButton({
    super.key,
    required this.label,
    required this.onTap,
    this.angle = -0.02,
    this.color = kPersonaRed,
    this.borderColor = kPersonaWhite,
    this.textColor = kPersonaWhite,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  });

  @override
  State<P5PulsingButton> createState() => _P5PulsingButtonState();
}

class _P5PulsingButtonState extends State<P5PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return ScaleTransition(
      scale: _scale,
      child: Transform.rotate(
        angle: widget.angle,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: disabled ? Colors.grey.shade800 : widget.color,
              border: Border.all(color: widget.borderColor, width: 2),
              boxShadow: disabled
                  ? null
                  : const [
                BoxShadow(color: kPersonaWhite, offset: Offset(4, 4))
              ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: disabled ? Colors.white38 : widget.textColor,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}