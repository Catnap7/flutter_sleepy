import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Color _op(Color c, double o) {
  final clamped = o.clamp(0.0, 1.0);
  return c.withAlpha((clamped * 255).round());
}

enum Soundscape { rainy, waves, campfire }

class SoundscapeBackground extends StatelessWidget {
  const SoundscapeBackground({
    super.key,
    required this.mode,
    this.intensity = 1.0,
    this.oceanLevel = 0.46,
    this.logsAssetPath, // optional for campfire
  });

  final Soundscape mode;

  /// 0.5 ~ 1.5 recommended. Scales particle counts and amplitudes.
  final double intensity;
  final double oceanLevel;

  /// If provided, an Image.asset will be drawn at the base of the campfire.
  final String? logsAssetPath;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case Soundscape.rainy:
        return _RainySky(intensity: intensity);
      case Soundscape.waves:
        return _Ocean(intensity: intensity, oceanLevel: oceanLevel);
      case Soundscape.campfire:
        return _Campfire(intensity: intensity, logsAssetPath: logsAssetPath);
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
      _RainLayer(dropCount: (220 * intensity).round()),
      // base drizzle
      _RainStreakLayer(count: (60 * intensity).round()),
      // NEW: falling streaks from top
      const _LowMist(),
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
          final speed =
              520 + rnd.nextDouble() * 340; // a bit slower for visibility
          final angle = pi * 1.12; // slightly slanted
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
        size: Size.infinite,
      ),
    );
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

    // burst scheduling and top-up to maintain drizzle with periodic bursts
    _burstClock += dt;
    if (_burstClock > _nextBurst) {
      _burstClock = 0;
      _nextBurst = 8 + rnd.nextDouble() * 6;
      _burstTimer = 1.6;
    }
    final target =
        baseCount + (_burstTimer > 0 ? (baseCount * 0.35).round() : 0);

    // top-up
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

    // update & draw drops
    for (final d in drops) {
      d.p += d.v * dt;
      if (d.p.dy > size.height + 20) {
        if (rnd.nextDouble() < 0.30) {
          ripples.add(_Ripple(Offset(d.p.dx, size.height - 4), 2, 0));
        }
        d.p =
            Offset(rnd.nextDouble() * size.width, -10 - rnd.nextDouble() * 40);
      }

      // height-based opacity
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

    // ripples
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

// NEW: top emitter layer for long rain streaks (more dramatic, like flames but inverted)
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
          final speed = 260 + rnd.nextDouble() * 220; // px/s
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
        // respawn at top
        s.p =
            Offset(rnd.nextDouble() * size.width, -20 - rnd.nextDouble() * 80);
        s.len = 28 + rnd.nextDouble() * 54;
        s.speed = 260 + rnd.nextDouble() * 220;
        s.life = 0.9 + rnd.nextDouble() * 0.8;
        s.age = 0;
        s.th = 1.0 + rnd.nextDouble() * 0.8;
      }
      final t = (1 - s.age / s.life).clamp(0.0, 1.0);
      final op = 0.20 + 0.60 * t; // fade out over life
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

class _LowMist extends StatefulWidget {
  const _LowMist({super.key});

  @override
  State<_LowMist> createState() => _LowMistState();
}

class _LowMistState extends State<_LowMist>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
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
            painter: _MistPainter(repaint: _c), size: Size.infinite));
  }
}

class _MistPainter extends CustomPainter {
  _MistPainter({required Listenable repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final g = Paint()
      ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.6), Offset(0, size.height), [
        _op(Colors.white, 0.02 + 0.02 * (0.5 + 0.5 * sin(t * 0.5))),
        _op(Colors.white, 0.10)
      ]);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
        g);
  }

  @override
  bool shouldRepaint(covariant _MistPainter old) => true;
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
    final glow = Paint()
      ..color = _op(Colors.white, 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawCircle(center, 60, glow);
    final core = Paint()..color = _op(Colors.white, 0.8);
    canvas.drawCircle(center, 10, core);
    final strip = Rect.fromLTWH(
        size.width * 0.68, size.height * 0.58, size.width * 0.22, 6);
    final grad = Paint()
      ..shader = ui.Gradient.linear(strip.topLeft, strip.topRight, [
        _op(Colors.white, 0.0),
        _op(Colors.white, 0.4),
        _op(Colors.white, 0.0)
      ]);
    canvas.drawRect(strip, grad);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) => false;
}

// ====== CAMPFIRE ===========================================================
class _Campfire extends StatelessWidget {
  const _Campfire({required this.intensity, this.logsAssetPath});

  final double intensity;
  final String? logsAssetPath;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const _GradientFill(top: Color(0xFF1A0C07), bottom: Color(0xFF2A120A)),
      if (logsAssetPath != null)
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(logsAssetPath!,
                        width: MediaQuery.of(context).size.width * 0.55,
                        fit: BoxFit.contain)))),
      _EmberLayer(count: (90 * intensity).round()),
      const _WarmFlicker(),
    ]);
  }
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
          final y = s.height * 0.86 + rnd.nextDouble() * 16;
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

    // brighter ignition base glow (more visible at the base)
    final origin = Offset(size.width * 0.5, size.height * 0.9);
    final baseStrong = Paint()
      ..shader = ui.Gradient.radial(origin, 130,
          [_op(const Color(0xFFFFA95C), 0.38), _op(Colors.transparent, 0.0)]);
    canvas.drawCircle(origin, 130, baseStrong);

    for (final e in embers) {
      e.age += dt;
      if (e.age > e.life) {
        e.age = 0;
        e.p = Offset(size.width * 0.5 + (rnd.nextDouble() - 0.5) * 120,
            size.height * 0.86 + rnd.nextDouble() * 16);
        e.v = Offset(
            (rnd.nextDouble() - 0.5) * 18, -(36 + rnd.nextDouble() * 64));
      }
      e.p += e.v * dt;
      e.v = Offset(e.v.dx * 0.985, e.v.dy - 8 * dt); // buoyancy
      final t = (1 - e.age / e.life).clamp(0.0, 1.0);
      final c =
          Color.lerp(const Color(0xFFFFC37A), const Color(0xFFFF5E2B), 1 - t)!;
      // Slight attenuation near bottom (reduced -> brighter at base)
      final bf = ((e.p.dy - size.height * 0.75) / (size.height * 0.25))
          .clamp(0.0, 1.0);
      final atten = 1.0 - 0.12 * bf; // was 0.45 (too dim)
      halo.color = _op(c, 0.22 * t * atten);
      core.color = _op(c, 0.90 * t * atten);
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
