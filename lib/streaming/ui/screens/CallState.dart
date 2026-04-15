import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/P5Theme.dart';
import '../widgets/P5BackgroundParticles.dart';

enum CallState {
  calling,     // tú iniciaste, esperando que el otro acepte
  incoming,    // te están llamando
  connected,   // en llamada activa
}

class CallScreen extends StatefulWidget {
  final String callerName;      // nombre de quien llama
  final String callerInitial;   // inicial para el avatar
  final Color callerColor;      // color del avatar
  final CallState initialState;
  final VoidCallback onHangUp;
  final VoidCallback? onAccept; // solo para estado incoming

  const CallScreen({
    super.key,
    required this.callerName,
    required this.callerInitial,
    required this.callerColor,
    required this.initialState,
    required this.onHangUp,
    this.onAccept,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  late CallState _state;
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  // Cronómetro de llamada conectada
  Timer? _timer;
  int _seconds = 0;

  // Animación de los puntos "Llamando..."
  int _dots = 1;
  Timer? _dotsTimer;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;

    // Pulso del avatar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Puntos animados para "Llamando..."
    if (_state == CallState.calling) {
      _startDotsAnimation();
    }
  }

  void _startDotsAnimation() {
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dots = (_dots % 3) + 1);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  // Llamado desde ChatViewModel cuando llega CALL_ACCEPT o cuando
  // el otro dispositivo empieza a enviar audio
  void connectCall() {
    setState(() => _state = CallState.connected);
    _dotsTimer?.cancel();
    _startTimer();
  }

  String get _timerText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _dotsText => '.' * _dots;

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _dotsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPersonaBlack,
      body: Stack(
        children: [
          const Positioned.fill(child: P5BackgroundParticles()),

          // Franja roja diagonal de fondo estilo P5
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipPath(
              clipper: _DiagonalClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.55,
                color: kPersonaRed,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Estado de la llamada
                Transform.rotate(
                  angle: -0.03,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: kPersonaBlack,
                      border: Border.all(color: kPersonaWhite, width: 2),
                    ),
                    child: Text(
                      _stateLabel,
                      style: const TextStyle(
                        color: kPersonaWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Avatar pulsante
                ScaleTransition(
                  scale: _pulse,
                  child: _buildAvatar(),
                ),

                const SizedBox(height: 24),

                // Nombre
                Text(
                  widget.callerName.toUpperCase(),
                  style: const TextStyle(
                    color: kPersonaWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                // Cronómetro o puntos
                Text(
                  _state == CallState.connected
                      ? _timerText
                      : _state == CallState.calling
                      ? 'LLAMANDO$_dotsText'
                      : 'LLAMADA ENTRANTE',
                  style: TextStyle(
                    color: _state == CallState.connected
                        ? const Color(0xFF00C853)
                        : kPersonaWhite.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(),

                // Botones de acción
                _buildActions(),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _stateLabel {
    switch (_state) {
      case CallState.calling:
        return 'PHANTOM CALL';
      case CallState.incoming:
        return 'LLAMADA ENTRANTE';
      case CallState.connected:
        return 'EN LLAMADA';
    }
  }

  Widget _buildAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: widget.callerColor,
        border: Border.all(color: kPersonaWhite, width: 4),
        boxShadow: [
          BoxShadow(
            color: widget.callerColor.withOpacity(0.5),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.callerInitial.toUpperCase(),
          style: const TextStyle(
            color: kPersonaWhite,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_state == CallState.incoming) {
      // Dos botones: rechazar y aceptar
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CallButton(
            icon: Icons.call_end,
            color: kPersonaRed,
            label: 'RECHAZAR',
            onTap: widget.onHangUp,
          ),
          _CallButton(
            icon: Icons.call,
            color: const Color(0xFF00C853),
            label: 'ACEPTAR',
            onTap: () {
              setState(() => _state = CallState.connected);
              _startTimer();
              widget.onAccept?.call();
            },
          ),
        ],
      );
    }

    // calling o connected: solo botón colgar
    return _CallButton(
      icon: Icons.call_end,
      color: kPersonaRed,
      label: 'COLGAR',
      onTap: widget.onHangUp,
    );
  }
}

class _CallButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  State<_CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<_CallButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scale,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: widget.color,
                border: Border.all(color: kPersonaWhite, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.6),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(widget.icon, color: kPersonaWhite, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: const TextStyle(
            color: kPersonaWhite,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(size.width, 0);
    p.lineTo(size.width, size.height * 0.8);
    p.lineTo(size.width * 0.3, size.height);
    p.lineTo(0, size.height * 0.85);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_) => false;
}