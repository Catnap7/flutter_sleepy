// Visual backgrounds that adapt to your app's current sound: rainy / waves / campfire.
// - SoundscapeBackground: pass `mode: Soundscape.rainy|waves|campfire`
// - Lightweight, battery-friendly Canvas effects; no external packages.
// - Works nicely behind a transparent Scaffold.
//
// v2 changes (campfire refined):
// - Removed image-based logs. Optional simple vector logs (off by default).
// - Added FlameCore layer (procedural, blurred path flames) so the ignition point looks natural.
// - Brightened base ignition glow and reduced over-attenuation near base.
// - Kept Rainy streaks layer and Ocean controls from prior patch.

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

Color _op(Color c, double o) =>
    c.withAlpha(((o.clamp(0.0, 1.0)) * 255).round());

enum Soundscape { rainy, waves, campfire, pinknoise }

class SoundscapeBackground extends StatelessWidget {
  const SoundscapeBackground({
    super.key,
    required this.mode,
    this.intensity = 1.0,
    this.oceanLevel = 0.76,
    this.showVectorLogs = false, // new: vector logs are optional
  });

  final Soundscape mode;

  /// 0.5 ~ 1.5 recommended. Scales particle counts and amplitudes.
  final double intensity;
  final double oceanLevel;
  final bool showVectorLogs;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case Soundscape.rainy:
        return _RainySky(intensity: intensity);
      case Soundscape.waves:
        return _Ocean(intensity: intensity, oceanLevel: oceanLevel);
      case Soundscape.campfire:
        return _Campfire(intensity: intensity, showVectorLogs: showVectorLogs);
      case Soundscape.pinknoise:
        return _PinkNoise(intensity: intensity);
    }
  }
}

// ====== RAINY ==============================================================
class _RainySky extends StatelessWidget {
  const _RainySky({required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    const top = Color(0xFF0A101C);
    const bottom = Color(0xFF0E1A2B);
    return Stack(children: [
      const _GradientFill(top: top, bottom: bottom),
      _RainLayer(dropCount: (110 * intensity).round()),
      _RainStreakLayer(count: (20 * intensity).round()),
      // const LowMist(),
    ]);
  }
}

class _RainLayer extends StatefulWidget {
  const _RainLayer({required this.dropCount});

  final int dropCount;

  @override
  State<_RainLayer> createState() => _RainLayerState();
}

class _Drop {
  Offset p;
  Offset v;
  double len;
  double thickness;

  _Drop(this.p, this.v, this.len, this.thickness);
}

class _Ripple {
  Offset c;
  double r;
  double age;

  _Ripple(this.c, this.r, this.age);
}

class _RainLayerState extends State<_RainLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final rnd = Random();
  final drops = <_Drop>[];
  final ripples = <_Ripple>[];
  Size last = Size.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ensure(Size size) {
    if (size != last || drops.isEmpty) {
      drops
        ..clear()
        ..addAll(List.generate(widget.dropCount, (_) {
          final x = rnd.nextDouble() * size.width;
          final y = rnd.nextDouble() * size.height;
          final speed = 520 + rnd.nextDouble() * 340;
          final angle = pi * 1.12;
          final v = Offset(cos(angle), sin(angle)) * speed;
          final len = 12 + rnd.nextDouble() * 18;
          final th = 0.9 + rnd.nextDouble() * 0.7;
          return _Drop(Offset(x, y), v, len, th);
        }));
      last = size;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        child: CustomPaint(
            painter: _RainPainter(drops, ripples,
                baseCount: widget.dropCount, onEnsure: _ensure, repaint: _ctrl),
            size: Size.infinite));
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.drops, this.ripples,
      {required this.baseCount,
      required this.onEnsure,
      required Listenable repaint})
      : super(repaint: repaint);
  final int baseCount;
  final List<_Drop> drops;
  final List<_Ripple> ripples;
  final void Function(Size) onEnsure;
  final rnd = Random();
  double _burstClock = 0, _burstTimer = 0, _nextBurst = 8;
  int last = DateTime.now().millisecondsSinceEpoch;

  @override
  void paint(Canvas canvas, Size size) {
    onEnsure(size);
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = (now - last) / 1000.0;
    last = now;
    final p = Paint()..strokeCap = StrokeCap.round;
    _burstClock += dt;
    if (_burstClock > _nextBurst) {
      _burstClock = 0;
      _nextBurst = 8 + rnd.nextDouble() * 6;
      _burstTimer = 1.6;
    }
    final target =
        baseCount + (_burstTimer > 0 ? (baseCount * 0.35).round() : 0);
    while (drops.length < target) {
      final x = rnd.nextDouble() * size.width;
      final speed = 520 + rnd.nextDouble() * 340;
      final angle = pi * 1.12;
      final v = Offset(cos(angle), sin(angle)) * speed;
      final len = 12 + rnd.nextDouble() * 18;
      final th = 0.9 + rnd.nextDouble() * 0.7;
      drops.add(_Drop(Offset(x, -10 - rnd.nextDouble() * 30), v, len, th));
    }
    if (_burstTimer > 0) _burstTimer -= dt;
    for (final d in drops) {
      d.p += d.v * dt;
      if (d.p.dy > size.height + 20) {
        if (rnd.nextDouble() < 0.30) {
          ripples.add(_Ripple(Offset(d.p.dx, size.height - 4), 2, 0));
        }
        d.p =
            Offset(rnd.nextDouble() * size.width, -10 - rnd.nextDouble() * 40);
      }
      final heightFactor = (d.p.dy / size.height).clamp(0.0, 1.0);
      final opacity = 0.22 + (0.38 * heightFactor);
      p
        ..color = _op(Colors.white, opacity)
        ..strokeWidth = d.thickness;
      canvas.drawLine(d.p, d.p - d.v.normalized() * d.len, p);
      final head = Paint()
        ..color = _op(Colors.white, opacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(d.p, d.thickness * 0.55, head);
    }
    final rp = Paint()..style = PaintingStyle.stroke;
    ripples.removeWhere((r) {
      r.age += dt;
      return r.age > 0.9;
    });
    for (final r in ripples) {
      final t = (1 - r.age / 0.9).clamp(0.0, 1.0);
      rp
        ..color = _op(Colors.white, 0.15 * t)
        ..strokeWidth = 1.0 + (1 - t) * 1.0;
      final rad = r.r + r.age * 28;
      canvas.drawCircle(r.c, rad, rp);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => true;
}

// top emitter for long streaks
class _RainStreakLayer extends StatefulWidget {
  const _RainStreakLayer({required this.count});

  final int count;

  @override
  State<_RainStreakLayer> createState() => _RainStreakLayerState();
}

class _Streak {
  Offset p;
  double len;
  double speed;
  double age;
  double life;
  double th;

  _Streak(this.p, this.len, this.speed, this.life, this.age, this.th);
}

class _RainStreakLayerState extends State<_RainStreakLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final rnd = Random();
  final streaks = <_Streak>[];
  Size last = Size.zero;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _ensure(Size s) {
    if (s != last || streaks.length < widget.count) {
      streaks
        ..clear()
        ..addAll(List.generate(widget.count, (_) {
          final x = rnd.nextDouble() * s.width;
          final y = -20 - rnd.nextDouble() * 80;
          final len = 28 + rnd.nextDouble() * 54;
          final speed = 260 + rnd.nextDouble() * 220;
          final life = 0.9 + rnd.nextDouble() * 0.8;
          final th = 1.0 + rnd.nextDouble() * 0.8;
          return _Streak(
              Offset(x, y), len, speed, life, rnd.nextDouble() * life, th);
        }));
      last = s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
        child: CustomPaint(
            painter:
                _RainStreakPainter(streaks, onEnsure: _ensure, repaint: _c),
            size: Size.infinite));
  }
}

class _RainStreakPainter extends CustomPainter {
  _RainStreakPainter(this.streaks,
      {required this.onEnsure, required Listenable repaint})
      : super(repaint: repaint);
  final List<_Streak> streaks;
  final void Function(Size) onEnsure;
  final rnd = Random();
  int last = DateTime.now().millisecondsSinceEpoch;

  @override
  void paint(Canvas canvas, Size size) {
    onEnsure(size);
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = (now - last) / 1000.0;
    last = now;
    final core = Paint()..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final s in streaks) {
      s.age += dt;
      s.p = Offset(s.p.dx, s.p.dy + s.speed * dt);
      if (s.age > s.life || s.p.dy > size.height + 40) {
        s.p =
            Offset(rnd.nextDouble() * size.width, -20 - rnd.nextDouble() * 80);
        s.len = 28 + rnd.nextDouble() * 54;
        s.speed = 260 + rnd.nextDouble() * 220;
        s.life = 0.9 + rnd.nextDouble() * 0.8;
        s.age = 0;
        s.th = 1.0 + rnd.nextDouble() * 0.8;
      }
      final t = (1 - s.age / s.life).clamp(0.0, 1.0);
      final op = 0.20 + 0.60 * t;
      core
        ..color = _op(Colors.white, op * 0.9)
        ..strokeWidth = s.th;
      glow
        ..color = _op(Colors.white, op * 0.35)
        ..strokeWidth = s.th * 2.2;
      final head = s.p;
      final tail = s.p.translate(0, -s.len);
      canvas.drawLine(head, tail, glow);
      canvas.drawLine(head, tail, core);
    }
  }

  @override
  bool shouldRepaint(covariant _RainStreakPainter old) => true;
}

// ====== OCEAN / WAVES ======================================================
class _Ocean extends StatelessWidget {
  const _Ocean({required this.intensity, this.oceanLevel = 0.46});

  final double intensity;
  final double oceanLevel;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const _GradientFill(top: Color(0xFF06121E), bottom: Color(0xFF0B2B3B)),
      _WaveLayer(
          lines: (3 * intensity).clamp(2, 6).toInt(),
          amp: 14 * intensity,
          speed: 0.6 + 0.2 * intensity,
          oceanLevel: oceanLevel),
      const _MoonGlow(),
    ]);
  }
}

class _WaveLayer extends StatefulWidget {
  const _WaveLayer(
      {required this.lines,
      required this.amp,
      required this.speed,
      this.oceanLevel = 0.46});

  final int lines;
  final double amp;
  final double speed;
  final double oceanLevel;

  @override
  State<_WaveLayer> createState() => _WaveLayerState();
}

class _WaveLayerState extends State<_WaveLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        child: CustomPaint(
            painter: _WavesPainter(
                widget.lines, widget.amp, widget.speed, widget.oceanLevel,
                repaint: _c),
            size: Size.infinite));
  }
}

class _WavesPainter extends CustomPainter {
  _WavesPainter(this.lines, this.amp, this.speed, this.oceanLevel,
      {required Listenable repaint})
      : super(repaint: repaint);
  final int lines;
  final double amp;
  final double speed;
  final double oceanLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    for (int i = 0; i < lines; i++) {
      final p = Path();
      final yBase = size.height * oceanLevel + i * 18;
      final a = amp * (1 - i / lines * 0.5);
      final k = 2 * pi / (size.width * 0.9);
      p.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 8) {
        final y = yBase + sin(k * x + t * (speed + i * 0.12)) * a;
        p.lineTo(x, y);
      }
      p.lineTo(size.width, size.height);
      p.lineTo(0, size.height);
      p.close();
      final alpha = 0.18 - i * 0.03;
      final color = i == 0
          ? _op(const Color(0xFF9ADCF8), 0.18)
          : _op(Colors.white, (alpha.clamp(0.06, 0.18) as double));
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter old) => true;
}

class _MoonGlow extends StatelessWidget {
  const _MoonGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
        child: CustomPaint(size: Size.infinite, painter: _MoonPainter()));
  }
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.13);

// moon glow
    final glow = Paint()
      ..color = _op(Colors.white, 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawCircle(center, 60, glow);

// moon core
    final core = Paint()..color = _op(Colors.white, 0.8);
    canvas.drawCircle(center, 10, core);

// water reflection strip (3 colors → provide 3 stops)
    final strip = Rect.fromLTWH(
        size.width * 0.68, size.height * 0.58, size.width * 0.22, 6);
    final reflection = Paint()
      ..shader = ui.Gradient.linear(
        strip.topLeft,
        strip.topRight,
        [
          _op(Colors.white, 0.0),
          _op(Colors.white, 0.40),
          _op(Colors.white, 0.0),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawRect(strip, reflection);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) => false;
}

// ====== CAMPFIRE ===========================================================
class _Campfire extends StatelessWidget {
  const _Campfire({required this.intensity, required this.showVectorLogs});

  final double intensity;
  final bool showVectorLogs;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const _GradientFill(top: Color(0xFF1A0C07), bottom: Color(0xFF2A120A)),
      if (showVectorLogs) const _VectorLogs(),
      // const _FlameCore(),
      _EmberLayer(count: (40 * intensity).round()),
      const _WarmFlicker(),
    ]);
  }
}

class _FlameCore extends StatefulWidget {
  const _FlameCore({super.key});

  @override
  State<_FlameCore> createState() => _FlameCoreState();
}

class _FlameCoreState extends State<_FlameCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
        child: CustomPaint(
            size: Size.infinite, painter: _FlameCorePainter(repaint: _c)));
  }
}

// NEW: procedural flame core at the base (ignition point)
// ---- CAMPFIRE: Flame core painter with explicit stops ---------------------
class _FlameCorePainter extends CustomPainter {
  _FlameCorePainter({required Listenable repaint}) : super(repaint: repaint);

  Path _flamePath(double cx, double baseY, double h, double w, double sway) {
    final p = Path();
    p.moveTo(cx - w / 2, baseY);
    p.cubicTo(cx - w / 2, baseY - h * 0.35, cx - w * 0.25 + sway,
        baseY - h * 0.75, cx, baseY - h);
    p.cubicTo(cx + w * 0.25 + sway, baseY - h * 0.75, cx + w / 2,
        baseY - h * 0.35, cx + w / 2, baseY);
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final cx = size.width * 0.5;
    final baseY = size.height * 0.90;

// Strong ignition disk (3 colors → provide 3 stops)
    final strong = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, baseY),
        140,
        [
          _op(const Color(0xFFFFB469), 0.55),
          _op(const Color(0xFFFF7A3A), 0.20),
          _op(Colors.transparent, 0.0),
        ],
        const [0.0, 0.6, 1.0],
      );
    canvas.drawCircle(Offset(cx, baseY), 40, strong);

// Layered flame shapes
    final layers = [
      [30.0, 20.0, const Color(0xFFFFE3A1), const Color(0xFFFF9A4D), 18.0, 1.3],
      [42.0, 60.0, const Color(0xFFFFD27A), const Color(0xFFFF7A3A), 14.0, 1.7],
      [64.0, 70.0, const Color(0xFFFFC05C), const Color(0xFFFF5E2B), 10.0, 2.2],
    ];

    for (final L in layers) {
      final h = L[0] as double;
      final w = L[1] as double;
      final top = L[2] as Color;
      final base = L[3] as Color;
      final blur = L[4] as double;
      final sp = L[5] as double;

      final sway = sin(t * sp) * 8.0;
      final path = _flamePath(cx, baseY, h, w + sin(t * sp * 0.7) * 8, sway);

      final glow = Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, baseY),
          Offset(cx, baseY - h),
          [
            _op(base, 0.35),
            _op(top, 0.0),
          ],
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

      final grad = Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx, baseY),
          Offset(cx, baseY - h),
          [
            _op(base, 0.85),
            _op(top, 0.65),
            _op(top, 0.0),
          ],
          const [0.0, 0.35, 1.0],
        );

      canvas.drawPath(path, glow);
      canvas.drawPath(path, grad);
    }
  }

  @override
  bool shouldRepaint(covariant _FlameCorePainter oldDelegate) => true;
}

class _Ember {
  Offset p;
  Offset v;
  double r;
  double life;
  double age;

  _Ember(this.p, this.v, this.r, this.life, this.age);
}

class _EmberLayer extends StatefulWidget {
  const _EmberLayer({required this.count});

  final int count;

  @override
  State<_EmberLayer> createState() => _EmberLayerState();
}

class _EmberLayerState extends State<_EmberLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final rnd = Random();
  final embers = <_Ember>[];
  Size last = Size.zero;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 16))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _ensure(Size s) {
    if (s != last || embers.isEmpty) {
      embers
        ..clear()
        ..addAll(List.generate(widget.count, (_) {
          final x = s.width * 0.5 + (rnd.nextDouble() - 0.5) * 120;
          // final y = s.height * 0.98 + rnd.nextDouble() * 16;
          // 화면 살짝 아래서 아지랑이 올라오는것처럼 변경
          final y = s.height + rnd.nextDouble() * 8;
          final v = Offset(
              (rnd.nextDouble() - 0.5) * 18, -(36 + rnd.nextDouble() * 64));
          final r = 1.2 + rnd.nextDouble() * 2.4;
          final life = 1.6 + rnd.nextDouble() * 2.0;
          return _Ember(Offset(x, y), v, r, life, rnd.nextDouble() * life);
        }));
      last = s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        child: CustomPaint(
            painter: _EmberPainter(embers, onEnsure: _ensure, repaint: _c),
            size: Size.infinite));
  }
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.embers,
      {required this.onEnsure, required Listenable repaint})
      : super(repaint: repaint);
  final List<_Ember> embers;
  final void Function(Size) onEnsure;
  final rnd = Random();
  int last = DateTime.now().millisecondsSinceEpoch;

  @override
  void paint(Canvas canvas, Size size) {
    onEnsure(size);
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = (now - last) / 1000.0;
    last = now;
    final halo = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final core = Paint();
    for (final e in embers) {
      e.age += dt;
      if (e.age > e.life) {
        e.age = 0;
        /*e.p = Offset(size.width * 0.5 + (rnd.nextDouble() - 0.5) * 120,
            size.height * 0.90 + rnd.nextDouble() * 16);*/
        e.p = Offset(size.width * 0.5 + (rnd.nextDouble() - 0.5) * 120,
            size.height + rnd.nextDouble() * 8);
        e.v = Offset(
            (rnd.nextDouble() - 0.5) * 18, -(36 + rnd.nextDouble() * 64));
      }
      e.p += e.v * dt;
      e.v = Offset(e.v.dx * 0.985, e.v.dy - 8 * dt);
      final t = (1 - e.age / e.life).clamp(0.0, 1.0);
      final c =
          Color.lerp(const Color(0xFFFFC37A), const Color(0xFFFF5E2B), 1 - t)!;
      final bf = ((e.p.dy - size.height * 0.78) / (size.height * 0.22))
          .clamp(0.0, 1.0);
      final atten = 1.0 - 0.08 * bf;
      halo.color = _op(c, 0.22 * t * atten);
      core.color = _op(c, 0.92 * t * atten);
      canvas.drawCircle(e.p, e.r * 2.6, halo);
      canvas.drawCircle(e.p, e.r, core);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter old) => true;
}

class _WarmFlicker extends StatefulWidget {
  const _WarmFlicker({super.key});

  @override
  State<_WarmFlicker> createState() => _WarmFlickerState();
}

class _WarmFlickerState extends State<_WarmFlicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final o = 0.03 + 0.02 * (_c.value);
          return Container(color: _op(Colors.black, o));
        });
  }
}

// ====== Common pieces ======================================================
class _GradientFill extends StatelessWidget {
  const _GradientFill({required this.top, required this.bottom});

  final Color top;
  final Color bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, bottom])));
  }
}

extension on Offset {
  double get len => sqrt(dx * dx + dy * dy);

  Offset normalized() => len == 0 ? this : this * (1 / len);

  Offset operator +(Offset o) => Offset(dx + o.dx, dy + o.dy);

  Offset operator -(Offset o) => Offset(dx - o.dx, dy - o.dy);

  Offset operator *(double s) => Offset(dx * s, dy * s);
}

// Optional: simple vector logs (off by default)
class _VectorLogs extends StatelessWidget {
  const _VectorLogs({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
        child: CustomPaint(size: Size.infinite, painter: _LogsPainter()));
  }
}

class _LogsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final y = size.height * 0.92;
    final rrect = (Rect rect, double r) =>
        RRect.fromRectAndRadius(rect, Radius.circular(r));
    Paint logPaint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.fill;
    final brown = const Color(0xFF694428);
    final dark = const Color(0xFF4A2E1C);
    canvas.save();
    canvas.translate(cx - 90, y - 12);
    canvas.rotate(-0.25);
    canvas.drawRRect(
        rrect(const Rect.fromLTWH(0, 0, 180, 26), 13), logPaint(brown));
    canvas.drawRRect(
        rrect(const Rect.fromLTWH(12, 5, 156, 16), 10), logPaint(dark));
    canvas.restore();
    canvas.save();
    canvas.translate(cx - 90, y - 12);
    canvas.rotate(0.25);
    canvas.drawRRect(
        rrect(const Rect.fromLTWH(0, 0, 180, 26), 13), logPaint(brown));
    canvas.drawRRect(
        rrect(const Rect.fromLTWH(12, 5, 156, 16), 10), logPaint(dark));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogsPainter oldDelegate) => false;
}

// ====== PINK NOISE (Animated Pink Waves) ===================================
class _PinkNoise extends StatefulWidget {
  const _PinkNoise({required this.intensity});

  final double intensity;

  @override
  State<_PinkNoise> createState() => _PinkNoiseState();
}

class _PinkNoiseState extends State<_PinkNoise>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0.0; // seconds

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _t = elapsed.inMicroseconds / 1e6; // continuous time for seamless loop
      });
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter:
              _PinkNoisePainter(phaseSeconds: _t, intensity: widget.intensity),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _PinkNoisePainter extends CustomPainter {
  _PinkNoisePainter({required this.phaseSeconds, required this.intensity});

  final double phaseSeconds; // seconds (continuous)
  final double intensity; // 0.5~1.5 권장

  @override
  void paint(Canvas canvas, Size size) {
    final t = phaseSeconds;

    // 1) BG gradient (먼저 그리기)
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        const [Color(0xFFFFB6D5), Color(0xFFFCC2E5)],
        const [0.0, 0.65],
      );
    canvas.drawRect(rect, bg);

    // 2) Waves (How it Works 헤더 느낌 그대로, 살짝 스케일만 intensity로)
    //    k: 가로 주기(폭 기준), speed: 시간 위상 속도, base: 각 레이어의 기준 높이
    final ampBase = 20.0 * intensity;
    final waves = [
      _PinkWaveSpec(
          color: const Color(0xFFFD7EB2).withOpacity(0.35),
          amp: ampBase * 0.8,
          k: 2.0,
          speed: 0.9,
          base: 0.77),
      _PinkWaveSpec(
          color: const Color(0xFFFC93C7).withOpacity(0.35),
          amp: ampBase * 1.1,
          k: 1.5,
          speed: 1.2,
          base: 0.79),
      _PinkWaveSpec(
          color: const Color(0xFFFFABD6).withOpacity(0.35),
          amp: ampBase * 1.35,
          k: 1.0,
          speed: 1.6,
          base: 0.74),
    ];

    for (final w in waves) {
      final path = Path()..moveTo(0, size.height);
      // 가로 한 폭에서 위상 2π*k 만큼 진행하도록 고정 → 화면 좌우 경계에서 끊김 느낌 없음
      final omegaX = 2 * pi * w.k / size.width;

      // 성능: 폭에 비례해 샘플 간격 자동 조정(대략 4~7px)
      final step = (size.width / 160).clamp(4.0, 7.0);
      for (double x = 0; x <= size.width; x += step) {
        final y = size.height * w.base + sin(omegaX * x + t * w.speed) * w.amp;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = w.color;
      canvas.drawPath(path, paint);
    }

    // 3) 아주 약한 비네트(상단 밝음 → 하단 살짝 어둡게)로 콘텐츠 대비 강화 (선택)
    final vignette = Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        [
          _op(Colors.black, 0.8),
          _op(Colors.black, 0.25),
          _op(Colors.black, 0.01),
        ],
        const [0.0, 0.7, 1.0],
      );
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant _PinkNoisePainter old) =>
      old.phaseSeconds != phaseSeconds || old.intensity != intensity;
}

class _PinkWaveSpec {
  final Color color;
  final double amp;
  final double k; // number of cycles across width
  final double speed; // phase speed
  final double base; // baseline (0..1 of height)
  const _PinkWaveSpec({
    required this.color,
    required this.amp,
    required this.k,
    required this.speed,
    required this.base,
  });
}
