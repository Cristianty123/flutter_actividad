// ui/widgets/P5ConfirmDialog.dart
import 'package:flutter/material.dart';
import '../theme/P5Theme.dart';

class P5ConfirmDialog {
  static Future<bool> show(
      BuildContext context, {
        required String title,
        required String message,
        String confirmLabel = 'CONFIRMAR',
        String cancelLabel = 'CANCELAR',
      }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirm',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack, // la misma animación que P5ErrorDialog
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: kPersonaGrey,
              border: Border.all(color: kPersonaWhite, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera blanca igual que P5ErrorDialog
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: kPersonaWhite,
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kPersonaBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // Mensaje
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 24),
                  child: Text(
                    message.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kPersonaWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Dos botones palpitantes
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _P5PulsingButton(
                        label: cancelLabel,
                        onTap: () => Navigator.pop(context, false),
                        color: const Color(0xFF2E2E2E),
                        borderColor: kPersonaWhite,
                        textColor: kPersonaWhite,
                        angle: 0.04,
                      ),
                      _P5PulsingButton(
                        label: confirmLabel,
                        onTap: () => Navigator.pop(context, true),
                        color: kPersonaRed,
                        borderColor: kPersonaWhite,
                        textColor: kPersonaWhite,
                        angle: -0.04,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }
}

// Botón con animación de pulso — mismo concepto que P5AnimatedButton del login
class _P5PulsingButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final double angle;

  const _P5PulsingButton({
    required this.label,
    required this.onTap,
    required this.color,
    required this.borderColor,
    required this.textColor,
    this.angle = -0.05,
  });

  @override
  State<_P5PulsingButton> createState() => _P5PulsingButtonState();
}

class _P5PulsingButtonState extends State<_P5PulsingButton>
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
    return ScaleTransition(
      scale: _scale,
      child: Transform.rotate(
        angle: widget.angle,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color,
              border: Border.all(color: widget.borderColor, width: 2),
              boxShadow: const [
                BoxShadow(color: kPersonaWhite, offset: Offset(3, 3))
              ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
    );
  }
}