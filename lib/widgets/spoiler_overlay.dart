import 'dart:math';

import 'package:flutter/material.dart';

/// Wraps [child] with an animated particle overlay when [isHidden] is true.
///
/// The word/heading stays visible; only the content wrapped here is hidden.
/// Particles drift gently (seeded, deterministic) over a surface-tinted fill.
class SpoilerOverlay extends StatefulWidget {
  final Widget child;
  final bool isHidden;
  /// Shifts particle seed so two overlays on the same card look different.
  final int seed;

  const SpoilerOverlay({
    super.key,
    required this.child,
    required this.isHidden,
    this.seed = 0,
  });

  @override
  State<SpoilerOverlay> createState() => _SpoilerOverlayState();
}

class _SpoilerOverlayState extends State<SpoilerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _particles = List.generate(
      110,
      (i) => _Particle._fromSeed(i + widget.seed * 110),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg      = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Stack(
      children: [
        // Child — layout preserved so card height never collapses.
        AnimatedOpacity(
          opacity: widget.isHidden ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: widget.child,
        ),
        // Particle overlay — always in tree, opacity-controlled for smooth fade.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !widget.isHidden,
            child: AnimatedOpacity(
              opacity: widget.isHidden ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(
                    t:             _ctrl.value,
                    particles:     _particles,
                    particleColor: primary,
                    bgColor:       bg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Particle data ─────────────────────────────────────────────────────────────

class _Particle {
  final double x;       // 0..1 normalised
  final double y;       // 0..1 normalised
  final double radius;  // px
  final double speed;   // animation cycles per repeat
  final double phase;   // radian offset

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
  });

  factory _Particle._fromSeed(int seed) {
    final r = Random(seed * 47 + 13);
    return _Particle(
      x:      r.nextDouble(),
      y:      r.nextDouble(),
      radius: 1.0 + r.nextDouble() * 1.5,
      speed:  0.2 + r.nextDouble() * 0.5,
      phase:  r.nextDouble() * 2 * pi,
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double        t;
  final List<_Particle> particles;
  final Color         particleColor;
  final Color         bgColor;

  _ParticlePainter({
    required this.t,
    required this.particles,
    required this.particleColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Near-opaque background fill to fully obscure the content beneath.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = bgColor.withAlpha(238),
    );

    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final angle = t * 2 * pi * p.speed + p.phase;
      final dx    = p.x * size.width  + sin(angle) * 6.0;
      final dy    = p.y * size.height + cos(angle * 0.71) * 5.0;
      final alpha = (0.35 + 0.55 * sin(angle + pi * 0.5).abs()).clamp(0.0, 1.0);
      paint.color = particleColor.withOpacity(alpha);
      canvas.drawCircle(
        Offset(
          dx.clamp(p.radius, size.width  - p.radius),
          dy.clamp(p.radius, size.height - p.radius),
        ),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
