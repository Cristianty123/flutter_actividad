import 'package:flutter/material.dart';

class P5AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double angle;

  const P5AnimatedButton({
    super.key,
    required this.label,
    required this.onTap,
    this.angle = -0.05,
  });

  @override
  State<P5AnimatedButton> createState() => _P5AnimatedButtonState();
}

class _P5AnimatedButtonState extends State<P5AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Velocidad del pulso
    )..repeat(reverse: true); // Hace que vaya y vuelva automáticamente

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Transform.rotate(
        angle: widget.angle,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            shape: const BeveledRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          onPressed: widget.onTap,
          child: Text(
            widget.label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}