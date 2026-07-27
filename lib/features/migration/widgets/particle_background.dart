import 'dart:math';
import 'package:flutter/material.dart';
import '../models/particle.dart';

class ParticleBackground extends StatefulWidget {
  final Widget child;
  const ParticleBackground({super.key, required this.child});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<MigrationParticle> _particles = [];
  final Random _random = Random();
  late DateTime _lastTime;

  @override
  void initState() {
    super.initState();
    _lastTime = DateTime.now();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _controller.addListener(_updateParticles);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    if (!mounted) return;
    
    final now = DateTime.now();
    final dt = now.difference(_lastTime).inMilliseconds / 1000.0;
    _lastTime = now;

    if (dt <= 0) return;

    setState(() {
      // Update existing particles
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.update(dt, gravity: 0.0, drag: 1.0);
        if (p.isDead) {
          _particles.removeAt(i);
        }
      }

      // Lazy spawn new ambient particles (floating dust)
      if (_particles.length < 60 && _random.nextDouble() < 0.15) {
        final size = MediaQuery.of(context).size;
        _particles.add(MigrationParticle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          vx: (_random.nextDouble() - 0.5) * 12.0,
          vy: -(_random.nextDouble() * 12.0 + 4.0), // slow drift upwards
          size: _random.nextDouble() * 1.5 + 0.8,
          color: Colors.amber.shade100,
          maxLife: _random.nextDouble() * 6.0 + 4.0,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundParticlePainter(particles: _particles),
      child: widget.child,
    );
  }
}

class _BackgroundParticlePainter extends CustomPainter {
  final List<MigrationParticle> particles;
  _BackgroundParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      paint.color = p.color.withOpacity(p.opacity * 0.3);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundParticlePainter oldDelegate) => true;
}
