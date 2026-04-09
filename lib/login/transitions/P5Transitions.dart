import 'package:flutter/material.dart';

class P5Transitions {
  static Route createRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {

        // Curva de aceleración agresiva tipo P5
        var curve = Curves.easeInOutQuart;
        var curveTween = CurveTween(curve: curve);

        // Definimos la entrada diagonal (de abajo-derecha a centro)
        final tween = Tween(
          begin: const Offset(1.0, 1.0),
          end: Offset.zero,
        ).chain(curveTween);

        return Stack(
          children: [
            // Capa de fondo negro que "limpia" la pantalla anterior
            FadeTransition(
              opacity: animation,
              child: Container(color: Colors.black),
            ),
            // La nueva pantalla entrando con deslizamiento
            SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          ],
        );
      },
    );
  }
}