/// Lightweight, battery-friendly LOW MIST layer for Flutter Canvas.
/// - Add a soft ground fog near the bottom of the screen.
/// - No external packages; works well behind a transparent Scaffold.
///
/// Usage:
///   Stack(children:[
///     ...your background...
///     const LowMist(
///       intensity: 1.0,         // 0.5 ~ 1.5
///       heightFraction: 0.45,   // bottom 45% gets fog
///       color: Color(0xFFFFFFFF),
///     ),
///   ])
///
/// Tips:
/// - Decrease intensity on low-end devices (e.g., 0.8)
/// - You can place it above/below rain/waves as desired.

import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';

Color _op(Color c, double o) => c.withAlpha(((o.clamp(0.0, 1.0)) * 255).round());

class LowMist extends StatefulWidget {
  const LowMist({
    super.key,
    this.intensity = 0.5,      // scales wisp count, blur, opacity
    this.heightFraction = 0.45, // portion of the screen height covered from bottom
    this.color = Colors.white,  // fog color (usually white)
    this.baseOpacity = 0.10,    // background gradient opacity near bottom
    this.wispOpacity = 0.08,    // individual wisp max opacity
    this.speed = 14.0,          // px/s horizontal drift speed (scaled by intensity)
    this.blurSigma = 10.0,      // blur for wisps
  });

  final double intensity;
  final double heightFraction;
  final Color color;
  final double baseOpacity;
  final double wispOpacity;
  final double speed;
  final double blurSigma;

  @override
  State<LowMist> createState() => _LowMistState();
}

class _Wisp {
  _Wisp(this.p, this.rx, this.ry, this.vx, this.phase, this.phaseSpeed);
  Offset p;      // center position
  double rx;     // x radius
  double ry;     // y radius
  double vx;     // horizontal speed (px/s)
  double phase;  // for subtle vertical wobble
  double phaseSpeed; // wobble speed
}

class _LowMistState extends State<LowMist> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final rnd = Random();
  final wisps = <_Wisp>[];
  Size last = Size.zero;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _ensure(Size s) {
    final desired = (10 * widget.intensity).clamp(6, 18).round();
    if (s != last || wisps.length != desired) {
      wisps
        ..clear()
        ..addAll(List.generate(desired, (_) {
          final hTop = s.height * (1.0 - widget.heightFraction);
          final y = lerpDouble(hTop + 8, s.height - 8, rnd.nextDouble())!;
          final x = rnd.nextDouble() * s.width;
          final rx = 80 + rnd.nextDouble() * 160;   // wide ovals
          final ry = 18 + rnd.nextDouble() * 34;    // shallow height
          final vx = (widget.speed + rnd.nextDouble() * widget.speed) * (rnd.nextBool() ? 1 : -1);
          final ph = rnd.nextDouble() * 2 * pi;
          final ps = 0.4 + rnd.nextDouble() * 0.8;  // wobble speed
          return _Wisp(Offset(x, y), rx, ry, vx, ph, ps);
        }));
      last = s;
    }
  }

  int _lastMs = DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _LowMistPainter(
            wisps: wisps,
            onEnsure: _ensure,
            color: widget.color,
            heightFraction: widget.heightFraction,
            baseOpacity: widget.baseOpacity * widget.intensity.clamp(0.75, 1.5),
            wispOpacity: widget.wispOpacity * widget.intensity.clamp(0.6, 1.6),
            blurSigma: widget.blurSigma * (0.8 + 0.4 * widget.intensity),
            repaint: _c,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _LowMistPainter extends CustomPainter {
  _LowMistPainter({
    required this.wisps,
    required this.onEnsure,
    required this.color,
    required this.heightFraction,
    required this.baseOpacity,
    required this.wispOpacity,
    required this.blurSigma,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<_Wisp> wisps;
  final void Function(Size) onEnsure;
  final Color color;
  final double heightFraction;
  final double baseOpacity;
  final double wispOpacity;
  final double blurSigma;

  int last = DateTime.now().millisecondsSinceEpoch;

  @override
  void paint(Canvas canvas, Size size) {
    onEnsure(size);

    // time step
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = (now - last) / 1000.0; // seconds
    last = now;

    final yTop = size.height * (1.0 - heightFraction);

    // 1) Soft base gradient
    final baseGrad = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, yTop),
        Offset(0, size.height),
        [
          _op(color, baseOpacity * 0.05),
          _op(color, baseOpacity),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, yTop, size.width, size.height - yTop), baseGrad);

    // 2) Drifting wisps (blurred ovals)
    final glow = Paint()
      ..color = _op(color, wispOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    final core = Paint()..color = _op(color, wispOpacity * 0.65);

    for (final w in wisps) {
      // update motion
      final wobble = sin(w.phase) * (w.ry * 0.15);
      w.phase += w.phaseSpeed * dt;
      var nx = w.p.dx + w.vx * dt;
      var ny = (w.p.dy + wobble).clamp(yTop + w.ry, size.height - w.ry);

      // wrap horizontally so flow never ends
      if (nx < -w.rx) nx = size.width + w.rx;
      if (nx > size.width + w.rx) nx = -w.rx;
      w.p = Offset(nx, ny);

      final rect = Rect.fromCenter(center: w.p, width: w.rx * 2, height: w.ry * 2);
      canvas.drawOval(rect, glow); // soft halo
      canvas.drawOval(rect, core); // subtle core
    }

    // 3) Slight top feathering to avoid a hard edge
    final feather = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, yTop - 24),
        Offset(0, yTop + 24),
        [
          _op(color, 0.0),
          _op(color, baseOpacity * 0.35),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, yTop - 24, size.width, 48), feather);
  }

  @override
  bool shouldRepaint(covariant _LowMistPainter oldDelegate) => true;
}
