import 'dart:math';
import 'package:flutter/material.dart';
import '../models/particle.dart';

class FireworkBurst {
  final double centerX;
  final double centerY;
  final List<MigrationParticle> particles;
  final double maxLife;
  double life;

  FireworkBurst({
    required this.centerX,
    required this.centerY,
    required this.particles,
    required this.maxLife,
  }) : life = maxLife;

  bool get isDead => life <= 0;

  void update(double dt) {
    life -= dt;
    for (var p in particles) {
      p.update(dt, gravity: 90.0, drag: 0.98);
    }
  }
}

class FireworksPainter extends CustomPainter {
  final List<FireworkBurst> bursts;

  FireworksPainter({required this.bursts});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var burst in bursts) {
      for (var p in burst.particles) {
        if (p.isDead) continue;

        // Draw outer soft glow
        final glowPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = p.color.withOpacity(p.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(Offset(p.x, p.y), p.size * 2.5, glowPaint);

        // Draw core particle
        paint.color = p.color.withOpacity(p.opacity);
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FireworksPainter oldDelegate) => true;
}
