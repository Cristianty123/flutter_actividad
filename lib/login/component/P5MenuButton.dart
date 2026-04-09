import 'package:flutter/material.dart';

class P5MenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double angle;

  const P5MenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.angle = -0.05,
  });

  @override
  State<P5MenuButton> createState() => _P5MenuButtonState();
}

class _P5MenuButtonState extends State<P5MenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
        child: InkWell(
          onTap: widget.onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Capa de Sombra Blanca (desplazada)
              Transform.translate(
                offset: const Offset(6, 6),
                child: _buttonShape(Colors.white),
              ),
              // Capa de Fondo Negro
              _buttonShape(Colors.black),
              // Contenido (Icono + Texto)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 24),
                    const SizedBox(width: 15),
                    Text(
                      widget.label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttonShape(Color color) {
    return ClipPath(
      clipper: _ButtonShapeClipper(),
      child: Container(
        width: 280,
        height: 60,
        color: color,
      ),
    );
  }
}

// Movimos el Clipper aquí adentro para que el componente sea independiente
class _ButtonShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.05, 0);
    path.lineTo(size.width, size.height * 0.1);
    path.lineTo(size.width * 0.95, size.height);
    path.lineTo(0, size.height * 0.9);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}