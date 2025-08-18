import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_sleepy/l10n/l10n_ext.dart';
import 'package:flutter/scheduler.dart';

/// Revamped "How it works" page for Pink Noise (V2 → fixes)
/// - SliverAppBar + FlexibleSpaceBar header → 본문 스크롤 시 헤더 침범/가림 문제 해결
/// - Header 파도 애니메이션을 Ticker로 구동 → phase가 연속적으로 증가하여 끊김 제거
/// - 하단 CTA는 bottomNavigationBar로 고정
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
            title: Text(context.l10n.howItWorks),
            flexibleSpace: const FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeaderWavesTicker(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList.list(children: [
              const SizedBox(height: 8),
              _EffectCard(
                icon: Icons.nightlight_round,
                title: context.l10n.effects_sleepQuality,
                description: context.l10n.effects_sleepQuality_desc,
              ),
              _EffectCard(
                icon: Icons.psychology_alt,
                title: context.l10n.effects_focusMemory,
                description: context.l10n.effects_focusMemory_desc,
              ),
              _EffectCard(
                icon: Icons.hearing,
                title: context.l10n.effects_tinnitus,
                description: context.l10n.effects_tinnitus_desc,
              ),
              _EffectCard(
                icon: Icons.self_improvement,
                title: context.l10n.effects_stress,
                description: context.l10n.effects_stress_desc,
              ),
              const SizedBox(height: 16),
            ]),
          ),
          SliverToBoxAdapter(
            child: _SectionCard(
              title: context.l10n.section_how,
              children: [
                _Bullet(context.l10n.how_bullet_1),
                _Bullet(context.l10n.how_bullet_2),
                _Bullet(context.l10n.how_bullet_3),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionCard(
              title: context.l10n.section_tips,
              children: [
                _Bullet(context.l10n.tips_bullet_1),
                _Bullet(context.l10n.tips_bullet_2),
                _Bullet(context.l10n.tips_bullet_3),
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
                label: Text(context.l10n.back),
              ),
            ),
            const SizedBox(width: 12),
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
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = context.l10n.howItWorks;
    final subtitle = context.l10n.howItWorksSubtitle;
    return ClipRect(
      child: CustomPaint(
        painter: _PinkWavePainter(phaseSeconds: _phase, title: title, subtitle: subtitle),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PinkWavePainter extends CustomPainter {
  _PinkWavePainter({required this.phaseSeconds, required this.title, required this.subtitle});

  final double phaseSeconds; // continuous time in seconds
  final String title;
  final String subtitle;

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
      _WaveSpec(color: const Color(0xFFFD7EB2).withOpacity(0.35), amp: 16, k: 2.0, speed: 0.9, base: 0.58),
      _WaveSpec(color: const Color(0xFFFC93C7).withOpacity(0.35), amp: 22, k: 1.5, speed: 1.2, base: 0.62),
      _WaveSpec(color: const Color(0xFFFFABD6).withOpacity(0.35), amp: 28, k: 1.0, speed: 1.6, base: 0.66),
    ];

    for (final w in waves) {
      final path = Path()..moveTo(0, size.height);
      final omegaX = 2 * math.pi * w.k / size.width; // phase advance over width
      for (double x = 0; x <= size.width; x += 4) {
        final y = size.height * w.base + math.sin(omegaX * x + t * w.speed) * w.amp;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();

      final paint = Paint()..style = PaintingStyle.fill..color = w.color;
      canvas.drawPath(path, paint);
    }

    // 3) Foreground title text (optional)
    final tp = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);
    tp.paint(canvas, const Offset(20, 140));

    final sub = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: const TextStyle(fontSize: 13, height: 1.25, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);
    sub.paint(canvas, const Offset(20, 168));
  }

  @override
  bool shouldRepaint(covariant _PinkWavePainter old) => old.phaseSeconds != phaseSeconds;

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
      color:
      isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
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
                    style:
                    theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
      color:
      isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _FaqTile(
            q: context.l10n.faq_q1,
            a: context.l10n.faq_a1,
          ),
          _FaqTile(
            q: context.l10n.faq_q2,
            a: context.l10n.faq_a2,
          ),
          _FaqTile(
            q: context.l10n.faq_q3,
            a: context.l10n.faq_a3,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(q,
              style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [Text(a, style: theme.textTheme.bodyMedium)],
        ),
      ),
    );
  }
}
