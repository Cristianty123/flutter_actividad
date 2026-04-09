import 'package:flutter/material.dart';
import 'P5AnimatedButton.dart';

class P5ErrorDialog {
  static void show(BuildContext context, String title, String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Error",
      barrierColor: Colors.black87, // Fondo oscurecido
      transitionDuration: const Duration(milliseconds: 400),

      // ANIMACIÓN DE PERSONA 5 (Sale de abajo hacia arriba)
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // Empieza fuera de la pantalla (abajo)
            end: const Offset(0, 0),   // Termina en su posición original
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
              color: const Color(0xFF2E2E2E), // Gris carbón P5
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera con estilo de alerta
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // Cuerpo del mensaje
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Text(
                    message.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Botón OK (usando tu componente animado)
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: P5AnimatedButton(
                    label: "OK",
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}