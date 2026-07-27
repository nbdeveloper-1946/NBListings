import 'package:flutter/material.dart';

class MigrationParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double opacity;
  final double maxLife;
  double life; // Remaining lifetime from maxLife down to 0.0

  // Particle evolution reassembly targets
  double? targetX;
  double? targetY;
  double? startX;
  double? startY;
  double? blueprintX;
  double? blueprintY;
  double? skylineX;
  double? skylineY;

  MigrationParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
    required this.maxLife,
  }) : life = maxLife;

  bool get isDead => life <= 0.0;

  void update(double dt, {double gravity = 0.0, double drag = 1.0}) {
    x += vx * dt;
    y += vy * dt;
    vy += gravity * dt;
    vx *= drag;
    vy *= drag;
    life -= dt;
    if (life < 0) life = 0;
    opacity = life / maxLife;
  }
}
