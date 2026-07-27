import 'dart:math';
import 'package:flutter/material.dart';
import '../models/particle.dart';

enum EvolutionStage {
  darkness,        // Scene 1: Floating dust & rays only
  idleNB,          // Scene 2: NB Logo carved from light
  energyBuildup,   // Scene 3: Vibrating, orbiting energy, flare rises
  dissolving,      // Scene 4: Spiral vortex dissolution
  reassembling,    // Scene 6: Converging particles to PropKart
  settledPropKart  // settled gold glow
}

class EvolutionLogo extends StatefulWidget {
  final EvolutionStage stage;
  final double stageProgress;
  final double elapsedSeconds;

  const EvolutionLogo({
    super.key,
    required this.stage,
    required this.stageProgress,
    required this.elapsedSeconds,
  });

  @override
  State<EvolutionLogo> createState() => _EvolutionLogoState();
}

class _EvolutionLogoState extends State<EvolutionLogo> with SingleTickerProviderStateMixin {
  late List<Offset> _nbPoints;
  late List<Offset> _propKartPoints;
  final List<MigrationParticle> _particles = [];
  final List<MigrationParticle> _ambientDust = [];
  final Random _random = Random();
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _nbPoints = _generateHousePoints();
    _propKartPoints = _generatePropKartPoints();
    _initializeParticles();
    _initializeAmbientDust();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EvolutionLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateParticlePhysics();
  }

  void _initializeParticles() {
    const totalParticles = 600; // Increased resolution
    _particles.clear();

    for (int i = 0; i < totalParticles; i++) {
      final ptA = _nbPoints[i % _nbPoints.length];
      final ptB = _propKartPoints[i % _propKartPoints.length];

      // Assign initial properties
      _particles.add(MigrationParticle(
        x: ptA.dx,
        y: ptA.dy,
        vx: 0,
        vy: 0,
        size: _random.nextDouble() * 1.5 + 1.0,
        color: const Color(0xFFFFD700), // Luxury Gold
        maxLife: 12.0,
      )
        ..startX = ptA.dx
        ..startY = ptA.dy
        ..targetX = ptB.dx
        ..targetY = ptB.dy);
    }
  }

  void _initializeAmbientDust() {
    _ambientDust.clear();
    for (int i = 0; i < 45; i++) {
      _ambientDust.add(MigrationParticle(
        x: (_random.nextDouble() - 0.5) * 400,
        y: (_random.nextDouble() - 0.5) * 400,
        vx: (_random.nextDouble() - 0.5) * 10,
        vy: -(_random.nextDouble() * 10 + 5), // floating upward
        size: _random.nextDouble() * 1.5 + 0.5,
        color: const Color(0xFFFFD700).withOpacity(0.3),
        maxLife: _random.nextDouble() * 8 + 4,
      ));
    }
  }

  void _updateParticlePhysics() {
    final progress = widget.stageProgress;
    final elapsed = widget.elapsedSeconds;

    // Update ambient dust drift
    for (var d in _ambientDust) {
      d.x += d.vx * 0.016;
      d.y += d.vy * 0.016;

      // Wrap around bounds
      if (d.x.abs() > 250) d.x = -d.x;
      if (d.y.abs() > 250) d.y = 250;
    }

    if (widget.stage == EvolutionStage.darkness) {
      for (var p in _particles) {
        p.opacity = 0.0;
      }
    } else if (widget.stage == EvolutionStage.idleNB) {
      // Emerge from darkness via moving light sweep
      // Light sweep parameter from -80 to 80
      final double lightSweep = -90.0 + (180.0 * progress);
      for (var p in _particles) {
        p.x = p.startX!;
        p.y = p.startY!;
        p.vx = 0;
        p.vy = 0;

        // Emerge as sweep moves past
        final dist = p.startX! - lightSweep;
        if (dist < 0) {
          p.opacity = 1.0;
        } else if (dist < 20) {
          p.opacity = 1.0 - (dist / 20.0);
        } else {
          p.opacity = 0.0;
        }
      }
    } else if (widget.stage == EvolutionStage.energyBuildup) {
      // Vibrations + orbit particles
      for (var p in _particles) {
        p.opacity = 1.0;
        // Vibration based on exponential progress
        final double vib = sin(elapsed * 75.0 + p.size) * (progress * 2.5);
        p.x = p.startX! + vib;
        p.y = p.startY! + vib;
      }
    } else if (widget.stage == EvolutionStage.dissolving) {
      // Swirl out in vortex spiral galaxy
      for (var p in _particles) {
        final startR = sqrt(p.startX! * p.startX! + p.startY! * p.startY!);
        final startAngle = atan2(p.startY!, p.startX!);

        final t = progress;
        // Vortex expansion
        final r = startR + (160.0 * t) + sin(t * 12.0) * 15.0;
        final angle = startAngle + (t * 2.2 * pi) + (p.size * 0.2);

        p.x = cos(angle) * r;
        p.y = sin(angle) * r - (30.0 * t); // slight upward lift
        p.opacity = max(0.15, 1.0 - t * 0.6);
        p.color = Color.lerp(const Color(0xFFFFD700), const Color(0xFFFF8C00), t)!;
      }
    } else if (widget.stage == EvolutionStage.reassembling) {
      // Converging particles directly into Shape B (PropKart)
      for (var p in _particles) {
        // Find spiral position at dissolve completion (t = 1.0)
        final startR = sqrt(p.startX! * p.startX! + p.startY! * p.startY!);
        final startAngle = atan2(p.startY!, p.startX!);
        final spiralX = cos(startAngle + 2.2 * pi + p.size * 0.2) * (startR + 160.0);
        final spiralY = sin(startAngle + 2.2 * pi + p.size * 0.2) * (startR + 160.0) - 30.0;

        final t = progress;
        final curvedT = Curves.easeOutQuart.transform(t);

        // Interpolate back
        p.x = spiralX + (p.targetX! - spiralX) * curvedT;
        p.y = spiralY + (p.targetY! - spiralY) * curvedT;

        p.opacity = 0.15 + (0.85 * curvedT);
        p.color = Color.lerp(const Color(0xFFFF8C00), const Color(0xFFFFD700), curvedT)!;
      }
    } else if (widget.stage == EvolutionStage.settledPropKart) {
      for (var p in _particles) {
        p.x = p.targetX!;
        p.y = p.targetY!;
        p.opacity = 1.0;
        p.color = const Color(0xFFFFD700);
      }
    }
  }

  List<Offset> _generateHousePoints() {
    final List<Offset> points = [];
    // Detailed Luxury House Outline
    // 1. Double layer roof triangle
    for (double i = -55; i <= 55; i += 3) {
      double y = -35 + (i.abs() * 0.7);
      points.add(Offset(i, y));
      points.add(Offset(i, y - 4));
    }
    // 2. Pillars/Walls
    for (double y = 5; y <= 45; y += 3.5) {
      points.add(Offset(-45, y));
      points.add(Offset(45, y));
      points.add(Offset(-25, y));
      points.add(Offset(25, y));
    }
    // 3. Ground base
    for (double x = -48; x <= 48; x += 3.5) {
      points.add(Offset(x, 45));
    }
    // 4. Initials "N" and "B"
    // Letter N
    for (double y = 12; y <= 32; y += 3) {
      points.add(Offset(-17, y));
      points.add(Offset(-7, y));
    }
    for (double i = 0; i <= 6; i += 1.5) {
      double pct = i / 6.0;
      points.add(Offset(-17 + pct * 10, 12 + pct * 20));
    }
    // Letter B
    for (double y = 12; y <= 32; y += 3) {
      points.add(Offset(7, y));
    }
    for (double x = 7; x <= 17; x += 2.5) {
      points.add(Offset(x, 12));
      points.add(Offset(x, 22));
      points.add(Offset(x, 32));
    }
    points.add(Offset(18, 17));
    points.add(Offset(18, 27));

    return points;
  }

  List<Offset> _generatePropKartPoints() {
    final List<Offset> points = [];
    // Detailed Shopping Cart merged with pitched Mansion Roof
    // 1. Pitch Roof Canopy
    for (double i = -65; i <= 65; i += 3) {
      double y = -30 + (i.abs() * 0.55);
      points.add(Offset(i, y - 10));
    }
    // 2. Cart chassis basket wires
    for (double x = -50; x <= 40; x += 3) {
      points.add(Offset(x, 15));
    }
    for (double y = -20; y <= 15; y += 3) {
      points.add(Offset(-50, y));
      double slantedX = 40 + (y - 15) * 0.25;
      points.add(Offset(slantedX, y));
    }
    // 3. Cart push handle
    for (double x = -60; x <= -50; x += 2.5) {
      points.add(Offset(x, -22));
    }
    for (double y = -22; y <= -12; y += 2.5) {
      points.add(Offset(-60, y));
    }
    // 4. Luxury Wire Wheels
    for (double angle = 0; angle < 2 * pi; angle += pi / 6) {
      points.add(Offset(-32 + 9 * cos(angle), 28 + 9 * sin(angle)));
      points.add(Offset(22 + 9 * cos(angle), 28 + 9 * sin(angle)));
    }
    // 5. Initials "P" and "K"
    // Letter P
    for (double y = -12; y <= 5; y += 2.5) {
      points.add(Offset(-13, y));
    }
    for (double x = -13; x <= -3; x += 2.5) {
      points.add(Offset(x, -12));
      points.add(Offset(x, -4));
    }
    points.add(Offset(-3, -8));

    // Letter K
    for (double y = -12; y <= 5; y += 2.5) {
      points.add(Offset(7, y));
    }
    for (double i = 0; i <= 8; i += 2) {
      points.add(Offset(7 + i, -4 - i));
      points.add(Offset(7 + i, -4 + i));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        // Slow camera zoom & push transformation calculation
        double scale = 2.2;
        double rotation = 0.0;

        final elapsed = widget.elapsedSeconds;
        if (elapsed < 2.0) {
          // Scene 1 push forward
          scale = 1.6 + 0.2 * (elapsed / 2.0);
        } else if (elapsed < 4.5) {
          // Scene 2 zoom
          scale = 1.8 + 0.2 * ((elapsed - 2.0) / 2.5);
        } else if (elapsed < 5.5) {
          // Scene 3 energy build vibration
          scale = 2.0;
        } else if (elapsed < 7.5) {
          // Scene 4 swirl camera rotation
          final progress = (elapsed - 5.5) / 2.0;
          scale = 2.0 + 0.3 * progress;
          rotation = -0.06 * sin(progress * pi);
        } else if (elapsed < 9.5) {
          // Scene 6 reassemble settle
          final progress = (elapsed - 7.5) / 2.0;
          scale = 2.3 - 0.2 * progress;
          rotation = 0.0;
        } else {
          // breathing scale settled
          scale = 2.1 + _breathingController.value * 0.04;
        }

        return Transform.rotate(
          angle: rotation,
          child: CustomPaint(
            size: const Size(300, 300),
            painter: _CinematicLogoPainter(
              particles: _particles,
              ambientDust: _ambientDust,
              stage: widget.stage,
              progress: widget.stageProgress,
              scale: scale,
              elapsed: elapsed,
            ),
          ),
        );
      },
    );
  }
}

class _CinematicLogoPainter extends CustomPainter {
  final List<MigrationParticle> particles;
  final List<MigrationMigrationAmbient> ambientDust;
  final EvolutionStage stage;
  final double progress;
  final double scale;
  final double elapsed;

  _CinematicLogoPainter({
    required this.particles,
    required this.ambientDust,
    required this.stage,
    required this.progress,
    required this.scale,
    required this.elapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw volumetric light rays waving across canvas
    _drawLightRays(canvas, size);

    // Save state for logo and dust scaling
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    // 2. Draw floating ambient dust particles
    final dustPaint = Paint()..style = PaintingStyle.fill;
    for (var d in ambientDust) {
      dustPaint.color = d.color.withOpacity(d.opacity * 0.15);
      canvas.drawCircle(Offset(d.x, d.y), d.size, dustPaint);
    }

    // 3. Draw Main Logo Morph Particle Engine
    final corePaint = Paint()..style = PaintingStyle.fill;

    // Metallic shine sweep progress
    double? shineX;
    if (stage == EvolutionStage.idleNB) {
      shineX = -75.0 + (150.0 * progress);
    }
    // Energy buildup waves
    double? energyWaveX;
    if (stage == EvolutionStage.energyBuildup) {
      energyWaveX = -75.0 + (150.0 * progress);
    }

    for (var p in particles) {
      if (p.opacity <= 0.0) continue;

      Color c = p.color;

      // Apply metallic shine
      if (shineX != null) {
        final dist = (p.x - shineX).abs();
        if (dist < 18.0) {
          final factor = 1.0 - (dist / 18.0);
          c = Color.lerp(c, Colors.white, factor * 0.85)!;
        }
      }

      // Apply energy buildup sweep
      if (energyWaveX != null) {
        final dist = (p.x - energyWaveX).abs();
        if (dist < 12.0) {
          final factor = 1.0 - (dist / 12.0);
          c = Color.lerp(c, Colors.white, factor * 0.95)!;
        }
      }

      // Draw soft glow
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = c.withOpacity(p.opacity * 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(Offset(p.x, p.y), p.size * 2.2, glowPaint);

      // Draw particle core
      corePaint.color = c.withOpacity(p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, corePaint);
    }

    canvas.restore();

    // 4. Draw Cinematic Lens Flare bloom at center transition
    _drawLensFlare(canvas, size);
  }

  void _drawLightRays(Canvas canvas, Size size) {
    final raysCenter = Offset(size.width / 2, -180);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24.0);

    for (int i = 0; i < 5; i++) {
      final angle = pi / 2 + sin(elapsed * 0.3 + i * 1.5) * 0.22;
      final path = Path()
        ..moveTo(raysCenter.dx, raysCenter.dy)
        ..lineTo(raysCenter.dx + cos(angle - 0.06) * 1100, raysCenter.dy + sin(angle - 0.06) * 1100)
        ..lineTo(raysCenter.dx + cos(angle + 0.06) * 1100, raysCenter.dy + sin(angle + 0.06) * 1100)
        ..close();

      paint.color = const Color(0xFFFFD700).withOpacity(0.015 + 0.01 * sin(elapsed * 0.8 + i));
      canvas.drawPath(path, paint);
    }
  }

  void _drawLensFlare(Canvas canvas, Size size) {
    double intensity = 0.0;
    // Explode flash peaks at 7.5s transition
    if (elapsed >= 5.5 && elapsed < 8.0) {
      if (elapsed < 7.5) {
        intensity = (elapsed - 5.5) / 2.0; // rises to 1.0
      } else {
        intensity = 1.0 - (elapsed - 7.5) / 0.5; // fades out quickly
      }
    }

    if (intensity <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Large soft radial glow
    final bloomPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(intensity * 0.8),
          const Color(0xFFFFD700).withOpacity(intensity * 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 220.0));

    canvas.drawCircle(center, 220.0, bloomPaint);

    // Outer bloom ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = const Color(0xFFFFD700).withOpacity(intensity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center, 130.0, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _CinematicLogoPainter oldDelegate) => true;
}

// Simple type alias to handle particles list mapping
typedef MigrationMigrationAmbient = MigrationParticle;
