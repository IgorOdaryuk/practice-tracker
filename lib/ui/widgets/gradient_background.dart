import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// App-wide *living* background: several large coloured glows drift, pulse and
/// overlap (additive blending) over a dark base, so the backdrop visibly flows
/// like an aurora / lava lamp — always in motion.
///
/// Wired once via `MaterialApp.builder`. Only the painted layer repaints
/// (Ticker → ValueNotifier); the UI ([child]) sits on top.
class GradientBackground extends StatefulWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  final Widget child;

  /// Master switch for the motion. Off → a static painted backdrop. Kept off in
  /// tests (so `pumpAndSettle` can settle) and forced off when the platform
  /// requests reduced motion.
  final bool animate;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(GradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No point burning GPU on an aurora nobody can see; resume when we're back.
    _syncTicker(resumed: state == AppLifecycleState.resumed);
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  void _syncTicker({bool resumed = true}) {
    final shouldRun = widget.animate && !_reduceMotion && resumed;
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AuroraPainter(_time),
        willChange: widget.animate,
        child: widget.child,
      ),
    );
  }
}

/// A drifting, pulsing coloured glow.
class _Blob {
  const _Blob({
    required this.color,
    required this.baseX,
    required this.baseY,
    required this.ampX,
    required this.ampY,
    required this.freqX,
    required this.freqY,
    required this.phase,
    required this.radius,
    required this.alpha,
  });

  final Color color;
  final double baseX, baseY, ampX, ampY, freqX, freqY, phase, radius, alpha;
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.time) : super(repaint: time);

  final ValueNotifier<double> time;

  static const List<Color> _base = [
    Color(0xFF1E0A3C),
    Color(0xFF0E0622),
    Color(0xFF060309),
  ];

  static const List<_Blob> _blobs = [
    _Blob(
      color: Color(0xFF7C3AED),
      baseX: 0.30, baseY: 0.28, ampX: 0.34, ampY: 0.22,
      freqX: 0.33, freqY: 0.27, phase: 0.0, radius: 0.95, alpha: 0.42,
    ),
    _Blob(
      color: Color(0xFFE95FE0),
      baseX: 0.72, baseY: 0.40, ampX: 0.28, ampY: 0.30,
      freqX: 0.24, freqY: 0.37, phase: 1.7, radius: 0.80, alpha: 0.32,
    ),
    _Blob(
      color: Color(0xFF4361EE),
      baseX: 0.45, baseY: 0.75, ampX: 0.36, ampY: 0.24,
      freqX: 0.41, freqY: 0.21, phase: 3.1, radius: 0.90, alpha: 0.34,
    ),
    _Blob(
      color: Color(0xFFB388FF),
      baseX: 0.62, baseY: 0.68, ampX: 0.30, ampY: 0.34,
      freqX: 0.29, freqY: 0.31, phase: 4.6, radius: 0.72, alpha: 0.30,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final rect = Offset.zero & size;

    // Dark base.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _base,
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Additive drifting glows.
    for (final b in _blobs) {
      final cx = size.width * (b.baseX + b.ampX * math.sin(t * b.freqX + b.phase));
      final cy = size.height *
          (b.baseY + b.ampY * math.cos(t * b.freqY + b.phase * 1.3));
      final r = size.width * b.radius * (0.9 + 0.12 * math.sin(t * 0.5 + b.phase));
      final center = Offset(cx, cy);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              b.color.withValues(alpha: b.alpha),
              b.color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) => false; // via Listenable
}
