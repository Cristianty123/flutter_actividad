import 'dart:math';
import 'package:flutter/material.dart';

// Traducción de BackgroundParticles.kt + ParticlesState + Particle
class P5BackgroundParticles extends StatefulWidget {
  const P5BackgroundParticles({super.key});

  @override
  State<P5BackgroundParticles> createState() => _P5BackgroundParticlesState();
}

class _P5BackgroundParticlesState extends State<P5BackgroundParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _state = _ParticlesState();

  @override
  void initState() {
    super.initState();
    // Loop infinito a 60fps — equivalente a withFrameMillis en Compose
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        _state.update(
          DateTime.now().millisecondsSinceEpoch,
          MediaQuery.of(context).size,
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlesPainter(particles: _state.particles),
      size: Size.infinite,
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlesPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation * pi / 180);
      canvas.scale(p.scale);
      // Dibujamos un rombo simple (representación de la partícula P5)
      final path = Path()
        ..moveTo(0, -6)
        ..lineTo(4, 0)
        ..lineTo(0, 6)
        ..lineTo(-4, 0)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => true; // siempre redibujar
}

class _Particle {
  double x, y, scale, rotation;
  double xSpeed, ySpeed, rotationSpeed;
  double period, amplitude;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.xSpeed,
    required this.ySpeed,
    required this.rotationSpeed,
    required this.period,
    required this.amplitude,
    required this.color,
  });
}

// Traducción de ParticlesState
class _ParticlesState {
  static const _maxCount = 25;
  static const _startCount = 8;
  static const _minSpawnInterval = 400;
  static const _spawnVariance = 600;

  final _rng = Random();
  final List<_Particle> particles = [];
  bool _initialized = false;
  int _nextSpawnTime = 0;
  int _lastUpdateTime = 0;

  // Colores de invierno del juego (P5 usa copos de nieve rojos oscuros)
  static const _colors = [Color(0xFF730D00), Color(0xFF9F0B00)];

  void update(int timeMs, Size worldSize) {
    if (!_initialized) {
      for (int i = 0; i < _startCount; i++) {
        _spawnParticle(worldSize, inBounds: true);
      }
      _initialized = true;
      _lastUpdateTime = timeMs;
    }

    if (timeMs > _nextSpawnTime && particles.length < _maxCount) {
      _nextSpawnTime = timeMs +
          _minSpawnInterval +
          _rng.nextInt(_spawnVariance);
      _spawnParticle(worldSize);
    }

    final deltaSeconds = (timeMs - _lastUpdateTime) / 1000.0;

    // Mover y despawnear — traducción del loop en ParticlesState.update()
    particles.removeWhere((p) {
      p.rotation += p.rotationSpeed * deltaSeconds;
      p.x += p.xSpeed * deltaSeconds;
      // La onda sinusoidal del movimiento horizontal (efecto viento)
      p.y += (p.period * sin(p.amplitude * p.x) +
          p.ySpeed * deltaSeconds);

      // Desaparecer si sale del área visible
      return p.x < -100 || p.y > worldSize.height + 100;
    });

    _lastUpdateTime = timeMs;
  }

  void _spawnParticle(Size worldSize, {bool inBounds = false}) {
    particles.add(_Particle(
      x: inBounds
          ? _randomBetween(0, worldSize.width)
          : _randomBetween(0, worldSize.width + 200),
      y: inBounds ? _randomBetween(0, worldSize.height) : -120,
      scale: _randomBetween(0.5, 0.8),
      rotation: _randomBetween(0, 360),
      xSpeed: _randomBetween(-80, 6),
      ySpeed: _randomBetween(60, 90),
      rotationSpeed: _randomBetween(22, 28) * (_rng.nextBool() ? 1 : -1),
      period: _randomBetween(0.3, 0.7),
      amplitude: _randomBetween(0.003, 0.05),
      color: _colors[_rng.nextInt(_colors.length)],
    ));
  }

  double _randomBetween(double min, double max) =>
      min + _rng.nextDouble() * (max - min);
}