import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/crm_design_system.dart';
import '../models/particle.dart';
import '../services/preferences_service.dart';
import '../services/redirect_service.dart';
import '../services/analytics_service.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/glow_button.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> with TickerProviderStateMixin {
  late AnimationController _timelineController;
  final MigrationPreferencesService _preferencesService = MigrationPreferencesService();
  final MigrationRedirectService _redirectService = MigrationRedirectService();
  final MigrationAnalyticsService _analyticsService = MigrationAnalyticsService();

  // Staged timeline state values
  double _elapsed = 0.0;
  final List<MigrationParticle> _storyboardParticles = [];
  final Random _random = Random();
  bool _particlesGenerated = false;

  // Cinematic control flags
  bool _cinematicFinished = false;
  bool _showCountdown = false;
  bool _countdownCancelled = false;
  int _secondsRemaining = 5;
  Timer? _countdownTimer;

  // Haptic state triggers
  bool _hapticNBTriggered = false;
  bool _hapticWaveTriggered = false;
  bool _hapticPropKartTriggered = false;

  @override
  void initState() {
    super.initState();
    _analyticsService.logEvent('migration_shown');

    // 7-second premium elongated storyboard timeline
    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    _timelineController.addListener(_onTimelineTick);
    _timelineController.forward().then((_) {
      _onCinematicFinished();
    });
  }

  @override
  void dispose() {
    _timelineController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onTimelineTick() {
    if (!mounted) return;

    final double elapsed = _timelineController.value * 7.0;

    // Trigger precise haptics based on visual milestones
    if (elapsed >= 1.0 && !_hapticNBTriggered) {
      _hapticNBTriggered = true;
      HapticFeedback.lightImpact();
    }
    if (elapsed >= 1.2 && !_hapticWaveTriggered) {
      _hapticWaveTriggered = true;
      HapticFeedback.mediumImpact();
    }
    if (elapsed >= 4.6 && !_hapticPropKartTriggered) {
      _hapticPropKartTriggered = true;
      HapticFeedback.vibrate();
    }

    // Lazy initialization of particle storyboard points
    if (elapsed >= 0.0 && !_particlesGenerated) {
      _particlesGenerated = true;
      _initializeStoryboardPoints();
    }

    // Mathematical coordinate interpolation based on elapsed storyboard phase (7.0s timeline)
    setState(() {
      _elapsed = elapsed;

      for (var p in _storyboardParticles) {
        if (elapsed < 1.2) {
          p.x = p.startX!;
          p.y = p.startY!;
          p.opacity = 0.0;
        } else if (elapsed < 2.8) {
          // Phase 2: old logo dissolves into blueprint wires of house (1.2s - 2.8s)
          final t = (elapsed - 1.2) / 1.6;
          p.x = _lerp(p.startX!, p.blueprintX!, t);
          p.y = _lerp(p.startY!, p.blueprintY!, t);
          p.opacity = t;
          p.color = const Color(0xFF5CA380); // signature green blueprint wires
        } else if (elapsed < 4.6) {
          // Phase 3: blueprint wires expand to gold skyline outline (2.8s - 4.6s)
          final t = (elapsed - 2.8) / 1.8;
          p.x = _lerp(p.blueprintX!, p.skylineX!, t);
          p.y = _lerp(p.blueprintY!, p.skylineY!, t);
          p.opacity = 1.0;
          p.color = Color.lerp(const Color(0xFF5CA380), const Color(0xFFFFD700), t)!; // Morphing cyan to gold
        } else if (elapsed < 5.8) {
          // Phase 4: skyline collapse to center molten gold (4.6s - 5.8s)
          final t = (elapsed - 4.6) / 1.2;
          if (t < 0.8) {
            final tCollapse = t / 0.8;
            final ease = Curves.easeIn.transform(tCollapse);
            p.x = _lerp(p.skylineX!, 0.0, ease);
            p.y = _lerp(p.skylineY!, 0.0, ease);
            p.opacity = 1.0 - tCollapse * 0.4;
            p.color = const Color(0xFFFFD700);
          } else {
            p.opacity = 0.0;
          }
        } else {
          p.opacity = 0.0;
        }
      }
    });
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _initializeStoryboardPoints() {
    const int count = 280; // Optimized particle count for connecting lines
    _storyboardParticles.clear();

    final housePoints = _generateHouseWireframe(110);
    final skylinePoints = _generateSkylineWireframe(170);

    for (int i = 0; i < count; i++) {
      // Dispersed start points within circular bounds of launcher icon
      final angle = _random.nextDouble() * 2 * pi;
      final dist = _random.nextDouble() * 50;
      final startX = cos(angle) * dist;
      final startY = sin(angle) * dist;

      final bp = housePoints[i % housePoints.length];
      final sk = skylinePoints[i % skylinePoints.length];

      _storyboardParticles.add(MigrationParticle(
        x: startX,
        y: startY,
        vx: 0,
        vy: 0,
        size: _random.nextDouble() * 1.8 + 1.2,
        color: const Color(0xFF5CA380),
        maxLife: 7.0,
      )
        ..startX = startX
        ..startY = startY
        ..blueprintX = bp.dx
        ..blueprintY = bp.dy
        ..skylineX = sk.dx
        ..skylineY = sk.dy);
    }
  }

  List<Offset> _generateHouseWireframe(double size) {
    final List<Offset> points = [];
    final half = size / 2;
    // Roof triangle
    for (double x = -half; x <= half; x += 4) {
      double y = -half + (x.abs() * 0.8) - 10;
      points.add(Offset(x, y));
    }
    // Left & right walls
    for (double y = -half + (half * 0.8) - 10; y <= half; y += 4) {
      points.add(Offset(-half + 10, y));
      points.add(Offset(half - 10, y));
    }
    // Floor
    for (double x = -half + 10; x <= half - 10; x += 4) {
      points.add(Offset(x, half));
    }
    return points;
  }

  List<Offset> _generateSkylineWireframe(double size) {
    final List<Offset> points = [];
    // Villa (left house)
    for (double x = -75; x <= -35; x += 4) {
      double y = -30 + ((x + 55).abs() * 0.8);
      points.add(Offset(x, y));
    }
    for (double y = -10; y <= 50; y += 4) {
      points.add(Offset(-75, y));
      points.add(Offset(-35, y));
    }
    for (double x = -75; x <= -35; x += 4) {
      points.add(Offset(x, 50));
    }

    // Apartment skyscraper (center height)
    for (double x = -18; x <= 18; x += 4) {
      points.add(Offset(x, -65));
      points.add(Offset(x, 50));
    }
    for (double y = -65; y <= 50; y += 4) {
      points.add(Offset(-18, y));
      points.add(Offset(18, y));
    }

    // Slanted commercial block (right)
    for (double x = 30; x <= 75; x += 4) {
      double y = -20 - (x - 30) * 0.45;
      points.add(Offset(x, y));
    }
    for (double y = -40; y <= 50; y += 4) {
      points.add(Offset(30, y));
      points.add(Offset(75, y));
    }
    for (double x = 30; x <= 75; x += 4) {
      points.add(Offset(x, 50));
    }

    return points;
  }

  void _onCinematicFinished() {
    if (!mounted || _cinematicFinished) return;
    setState(() {
      _cinematicFinished = true;
    });
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _showCountdown = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _countdownTimer?.cancel();
          _analyticsService.logEvent('migration_countdown_finished');
          _performMigration();
        }
      });
    });
  }

  Future<void> _performMigration() async {
    _countdownTimer?.cancel();
    _analyticsService.logEvent('migration_redirect');

    await _preferencesService.markMigrationAsSeen();
    final success = await _redirectService.redirectToPropKart();

    if (success) {
      _analyticsService.logEvent('migration_redirect_success');
    } else {
      _analyticsService.logEvent('migration_failed');
    }
  }

  Future<void> _skipMigration() async {
    _countdownTimer?.cancel();
    _analyticsService.logEvent('migration_skipped');
    await _preferencesService.markMigrationAsSeen();
    if (mounted) {
      context.go('/splash');
    }
  }

  void _stayHere() {
    _countdownTimer?.cancel();
    _analyticsService.logEvent('migration_countdown_cancelled');
    setState(() {
      _countdownCancelled = true;
      _showCountdown = false;
    });
  }

  // Background smooth color fade (expanded to 7s)
  Color _getBackgroundColor() {
    if (_elapsed < 2.8) {
      return Colors.white;
    } else if (_elapsed < 4.6) {
      final t = (_elapsed - 2.8) / 1.8;
      return Color.lerp(Colors.white, const Color(0xFF0F0F11), Curves.easeInOut.transform(t))!;
    } else {
      return const Color(0xFF090909);
    }
  }

  // Old logo opacity calculations
  double _getOldLogoOpacity() {
    if (_elapsed < 1.2) return 1.0;
    if (_elapsed < 1.6) return 1.0 - (_elapsed - 1.2) / 0.4;
    return 0.0;
  }

  // Old logo emitting green glow intensity
  double _getGlowIntensity() {
    if (_elapsed < 1.2) return _elapsed / 1.2;
    return 0.0;
  }

  // New logo opacity calculations
  double _getNewLogoOpacity() {
    if (_elapsed < 4.6) return 0.0;
    if (_elapsed < 5.4) return (_elapsed - 4.6) / 0.8;
    return 1.0;
  }

  // New logo scale (zoom from 0.8 to 1.0)
  double _getNewLogoScale() {
    if (_elapsed < 4.6) return 0.8;
    if (_elapsed < 6.4) {
      final t = (_elapsed - 4.6) / 1.8;
      return 0.8 + 0.2 * Curves.easeOutCubic.transform(t);
    }
    return 1.0;
  }

  // Tagline reveal positions
  double _getTaglineOffset() {
    if (_elapsed < 5.4) return 18.0;
    if (_elapsed < 6.6) {
      final t = (_elapsed - 5.4) / 1.2;
      return 18.0 * (1.0 - Curves.easeOutCubic.transform(t));
    }
    return 0.0;
  }

  // Tagline opacity
  double _getTaglineOpacity() {
    if (_elapsed < 5.4) return 0.0;
    if (_elapsed < 6.6) return (_elapsed - 5.4) / 1.2;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();
    final oldLogoOpacity = _getOldLogoOpacity();
    final newLogoOpacity = _getNewLogoOpacity();
    final glowIntensity = _getGlowIntensity();
    final scaleVal = _getNewLogoScale();

    final taglineOffset = _getTaglineOffset();
    final taglineOpacity = _getTaglineOpacity();

    final bool enableShimmer = _elapsed >= 5.8 && _elapsed < 7.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Blueprint Vector Lines & Skyline Particles Painter (centered)
          if (_elapsed >= 1.2 && _elapsed < 5.8)
            Positioned.fill(
              child: CustomPaint(
                painter: _BlueprintStoryboardPainter(
                  particles: _storyboardParticles,
                  elapsed: _elapsed,
                ),
              ),
            ),

          // 2. Old Logo Stack (Breathing Green Glow backplate)
          if (oldLogoOpacity > 0)
            Center(
              child: Opacity(
                opacity: oldLogoOpacity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Emitting green glow backplate
                    if (glowIntensity > 0)
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5CA380).withOpacity(glowIntensity * 0.4),
                              blurRadius: 40 * glowIntensity,
                              spreadRadius: 8 * glowIntensity,
                            ),
                          ],
                        ),
                      ),
                    Image.asset(
                      'assets/images/launcher.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),

          // 3. New Logo Stack (Zoom & Shimmer sweep using custom ShaderMask to prevent web rendering errors)
          if (newLogoOpacity > 0 && !_cinematicFinished)
            Center(
              child: Opacity(
                opacity: newLogoOpacity,
                child: Transform.scale(
                  scale: scaleVal,
                  child: _MetallicLogoSweep(
                    enabled: enableShimmer,
                    child: Image.asset(
                      'assets/images/splash.png',
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

          // 4. Staged Tagline Reveal
          if (_elapsed >= 5.4 && !_cinematicFinished)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: taglineOpacity,
                child: Transform.translate(
                  offset: Offset(0, taglineOffset),
                  child: Center(
                    child: Text(
                      'BUY  •  SELL  •  RENT  •  CONNECT',
                      style: CRMTypography.captionBold.copyWith(
                        color: const Color(0xFFFFD700), // Gold
                        fontSize: 14,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 5. Skip Button (Top Right)
          if (_cinematicFinished)
            Positioned(
              top: CRMSpacing.xl + 12,
              right: CRMSpacing.xl,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  ),
                ),
                onPressed: _skipMigration,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(
                  'Close',
                  style: CRMTypography.bodyMedium.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms),
            ),

          // 6. Staged Glassmorphic Overlay Panel
          if (_cinematicFinished)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/splash.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                  ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: CRMSpacing.m),
                  Text(
                    'PROPKART',
                    style: CRMTypography.display.copyWith(
                      color: const Color(0xFFFFD700),
                      letterSpacing: 4.0,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 800.ms).shimmer(
                        duration: 2000.ms,
                        colors: [const Color(0xFFFFD700), Colors.white, const Color(0xFFFFD700)],
                      ),
                  const SizedBox(height: CRMSpacing.xl),
                  Text(
                    'Thank you for being part of NB Listings.\nWe\'re excited to welcome you to our next chapter.',
                    textAlign: TextAlign.center,
                    style: CRMTypography.bodyMedium.copyWith(
                      color: Colors.white70,
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ).animate().fadeIn(duration: 900.ms),
                  const SizedBox(height: CRMSpacing.l),
                  Text(
                    'NB Listings has officially evolved into',
                    style: CRMTypography.caption.copyWith(
                      color: Colors.white38,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
                  const SizedBox(height: CRMSpacing.xs),
                  Text(
                    'PROPKART',
                    style: CRMTypography.bodyMedium.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
                  const SizedBox(height: 50),
                  if (_showCountdown)
                    MigrationCountdownWidget(
                      secondsRemaining: _secondsRemaining,
                      onOpenNow: _performMigration,
                      onStayHere: _stayHere,
                    ).animate().fadeIn(duration: 600.ms),
                  if (_countdownCancelled) ...[
                    MigrationGlowButton(
                      label: 'Open PropKart',
                      onPressed: _performMigration,
                    ).animate().fadeIn(duration: 600.ms),
                    const SizedBox(height: CRMSpacing.m),
                    TextButton(
                      onPressed: _skipMigration,
                      child: Text(
                        'Continue to old app',
                        style: CRMTypography.caption.copyWith(
                          color: Colors.white38,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ).animate().fadeIn(duration: 800.ms),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BlueprintStoryboardPainter extends CustomPainter {
  final List<MigrationParticle> particles;
  final double elapsed;

  _BlueprintStoryboardPainter({required this.particles, required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw vector wireframe outlines connecting the blueprint/skyline coordinates
    if (elapsed >= 1.2 && elapsed < 4.6) {
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);

      if (elapsed < 2.8) {
        // Blueprint stage: glowing cyan/emerald green lines connecting house wireframe
        linePaint.color = const Color(0xFF5CA380).withOpacity(0.22 * ((elapsed - 1.2) / 1.6));
      } else {
        // Skyline stage: glowing luxury gold lines connecting skyline wireframe
        linePaint.color = const Color(0xFFFFD700).withOpacity(0.22 * (1.0 - (elapsed - 2.8) / 1.8));
      }

      // Draw lines between succeeding nodes to complete the outline shapes
      for (int i = 0; i < particles.length - 1; i++) {
        // Break lines occasionally to make it look like sketch segments rather than a continuous loop
        if (i % 25 != 0) {
          canvas.drawLine(
            Offset(center.dx + particles[i].x, center.dy + particles[i].y),
            Offset(center.dx + particles[i + 1].x, center.dy + particles[i + 1].y),
            linePaint,
          );
        }
      }
    }

    // Draw the glowing dust/particles
    for (var p in particles) {
      if (p.opacity <= 0.0) continue;

      // Outer halo/glow effect
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = p.color.withOpacity(p.opacity * 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(Offset(center.dx + p.x, center.dy + p.y), p.size * 2.0, glowPaint);

      // Core particle
      paint.color = p.color.withOpacity(p.opacity);
      canvas.drawCircle(Offset(center.dx + p.x, center.dy + p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintStoryboardPainter oldDelegate) => true;
}

// Custom 100% Web-compatible metallic sweep shader effect to avoid solid box package bugs
class _MetallicLogoSweep extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _MetallicLogoSweep({required this.child, required this.enabled});

  @override
  State<_MetallicLogoSweep> createState() => _MetallicLogoSweepState();
}

class _MetallicLogoSweepState extends State<_MetallicLogoSweep> with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.enabled) {
      _sweepController.repeat();
    }
  }

  @override
  void didUpdateWidget(_MetallicLogoSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_sweepController.isAnimating) {
      _sweepController.repeat();
    } else if (!widget.enabled && _sweepController.isAnimating) {
      _sweepController.stop();
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _sweepController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop, // guarantees overlay shine respects transparency masks
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.35),
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.35),
                Colors.white.withOpacity(0.0),
              ],
              stops: const [0.15, 0.35, 0.5, 0.65, 0.85],
              transform: _SlantedSweepTransform(_sweepController.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlantedSweepTransform extends GradientTransform {
  final double percent;
  const _SlantedSweepTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double width = bounds.width;
    final double tx = -width + (width * 2 * percent);
    return Matrix4.translationValues(tx, 0.0, 0.0);
  }
}
