import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Revamped "How it works" page for Pink Noise.
class ExplainScreenV2 extends StatefulWidget {
  const ExplainScreenV2({super.key});

  @override
  State<ExplainScreenV2> createState() => _ExplainScreenV2State();
}

class _ExplainScreenV2State extends State<ExplainScreenV2>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 200,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Sleep benefits of pink noise'),
            flexibleSpace: const FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeaderWavesTicker(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList.list(children: const [
              SizedBox(height: 8),
              _EffectCard(
                icon: Icons.nightlight_round,
                title: 'Better sleep quality',
                description:
                    'Pink noise can support deeper sleep and improve overall sleep quality. You may sleep longer and wake up feeling more refreshed.',
              ),
              _EffectCard(
                icon: Icons.psychology_alt,
                title: 'Improved focus and memory',
                description:
                    'Better sleep helps your brain recover. Pink noise is associated with stronger memory consolidation and clearer daytime focus.',
              ),
              _EffectCard(
                icon: Icons.hearing,
                title: 'Tinnitus masking support',
                description:
                    'As a stable background sound, pink noise may make tinnitus less noticeable for some listeners.',
              ),
              _EffectCard(
                icon: Icons.self_improvement,
                title: 'Lower stress before bed',
                description:
                    'Soft, consistent audio can calm your mind. Pink noise helps create a relaxing bedtime routine.',
              ),
              SizedBox(height: 16),
            ]),
          ),
          const SliverToBoxAdapter(
            child: _SectionCard(
              title: 'How it works',
              children: [
                _Bullet(
                    'Pink noise follows a 1/f power spectrum: lower frequencies carry more energy and higher frequencies gently roll off.'),
                _Bullet(
                    'This smoother profile makes sudden environmental sounds feel less sharp and less disruptive.'),
                _Bullet(
                    'That can reduce nighttime arousals and help keep sleep stages more stable.'),
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: _SectionCard(
              title: 'Usage tips',
              children: [
                _Bullet(
                    'Start at a low volume and increase slowly. Keep it below normal conversation level.'),
                _Bullet(
                    'Use a 30-60 minute timer by default, then adjust based on your sleep pattern.'),
                _Bullet(
                    'Many people find a bedside speaker more comfortable than earphones overnight.'),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: _FaqSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.5)
              : Colors.white.withOpacity(0.9),
          border: Border(
            top: BorderSide(
              color: (isDark ? Colors.white24 : Colors.black12),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16 + 6),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            /*Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, 'play_pink_noise');
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play pink noise'),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Header with animated pink waves driven by an ever-increasing phase
class _HeaderWavesTicker extends StatefulWidget {
  const _HeaderWavesTicker();
  @override
  State<_HeaderWavesTicker> createState() => _HeaderWavesTickerState();
}

class _HeaderWavesTickerState extends State<_HeaderWavesTicker>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _phase = 0; // seconds

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _phase = elapsed.inMicroseconds / 1e6; // continuous time (s)
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
    return ClipRect(
      child: CustomPaint(
        painter: _PinkWavePainter(phaseSeconds: _phase),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PinkWavePainter extends CustomPainter {
  _PinkWavePainter({required this.phaseSeconds});

  final double phaseSeconds; // continuous time in seconds

  @override
  void paint(Canvas canvas, Size size) {
    final t = phaseSeconds; // use directly for continuous phase

    // 1) Draw gradient BACKGROUND first so waves appear on top
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFB6D5), Color(0xFFFCC2E5)],
        stops: [0.0, 0.6],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // 2) Then draw 3 layered waves (higher z-order)
    final waves = [
      _WaveSpec(
          color: const Color(0xFFFD7EB2).withOpacity(0.35),
          amp: 16,
          k: 2.0,
          speed: 0.9,
          base: 0.58),
      _WaveSpec(
          color: const Color(0xFFFC93C7).withOpacity(0.35),
          amp: 22,
          k: 1.5,
          speed: 1.2,
          base: 0.62),
      _WaveSpec(
          color: const Color(0xFFFFABD6).withOpacity(0.35),
          amp: 28,
          k: 1.0,
          speed: 1.6,
          base: 0.66),
    ];

    for (final w in waves) {
      final path = Path()..moveTo(0, size.height);
      final omegaX = 2 * math.pi * w.k / size.width; // phase advance over width
      for (double x = 0; x <= size.width; x += 4) {
        final y =
            size.height * w.base + math.sin(omegaX * x + t * w.speed) * w.amp;
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

    // 3) Foreground title text (optional)
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Sleep benefits of pink noise',
        style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);
    tp.paint(canvas, const Offset(20, 140));

    final sub = TextPainter(
      text: const TextSpan(
        text:
            'How it works - predictable 1/f sound helps reduce sleep disruptions.',
        style: TextStyle(fontSize: 13, height: 1.25, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);
    sub.paint(canvas, const Offset(20, 168));
  }

  @override
  bool shouldRepaint(covariant _PinkWavePainter old) =>
      old.phaseSeconds != phaseSeconds;
}

class _WaveSpec {
  final Color color;
  final double amp; // amplitude
  final double k; // number of half-waves across width (approx)
  final double speed; // phase speed (rad/s factor)
  final double base; // baseline as fraction of height
  _WaveSpec({
    required this.color,
    required this.amp,
    required this.k,
    required this.speed,
    required this.base,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Content Widgets

class _EffectCard extends StatelessWidget {
  const _EffectCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...children,
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 6),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          SizedBox(height: 8),
          _FaqTile(
            q: 'How is it different from white noise?',
            a: 'White noise has equal power across all frequencies. Pink noise follows a 1/f curve, so lower frequencies are stronger. It usually sounds softer and more natural.',
          ),
          _FaqTile(
            q: 'How loud should it be?',
            a: 'Too loud can keep you alert. Keep it clearly below conversation volume: present, but not distracting.',
          ),
          _FaqTile(
            q: 'Earphones or speaker?',
            a: 'Most users find a speaker more comfortable for sleep, but this depends on your environment and preference.',
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.q, required this.a});
  final String q;
  final String a;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(q,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [Text(a, style: theme.textTheme.bodyMedium)],
        ),
      ),
    );
  }
}
