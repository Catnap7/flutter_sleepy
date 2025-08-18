import 'dart:math' as math;
import 'package:flutter/material.dart';
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
            title: const Text('핑크 노이즈의 수면 효과'),
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
                title: '수면의 질 향상',
                description:
                '핑크 노이즈는 깊은 수면을 유도하여 전반적인 수면의 질을 향상시킬 수 있습니다. 더 오래 자고 일어났을 때 더욱 상쾌함을 느낄 수 있습니다.',
              ),
              _EffectCard(
                icon: Icons.psychology_alt,
                title: '집중력 및 기억력 개선',
                description:
                '양질의 수면은 뇌의 기능을 최적화하는 데 도움이 됩니다. 특히, 핑크 노이즈는 기억력과 학습 능력 향상과 연관되어 깨어 있는 동안 더 나은 집중력을 돕습니다.',
              ),
              _EffectCard(
                icon: Icons.hearing,
                title: '이명 증상 완화',
                description:
                '핑크 노이즈는 배경 소음으로 작용해 귀에서 들리는 불쾌한 이명을 상대적으로 덜 느끼게 할 수 있습니다.',
              ),
              _EffectCard(
                icon: Icons.self_improvement,
                title: '스트레스 감소',
                description:
                '부드럽고 일정한 소리는 마음을 진정시키는 데 도움이 됩니다. 핑크 노이즈로 심신의 이완을 경험해 보세요.',
              ),
              SizedBox(height: 16),
            ]),
          ),
          const SliverToBoxAdapter(
            child: _SectionCard(
              title: '작동 원리 (How it works)',
              children: [
                _Bullet('핑크 노이즈는 주파수 f에 대해 1/f 파워 스펙트럼을 가지며, 저주파 성분이 더 크고 고주파로 갈수록 에너지가 서서히 줄어듭니다.'),
                _Bullet('이 스펙트럼은 뇌가 예측 가능한 패턴을 인지하도록 도와, 외부의 급격한 소음 변화를 상대적으로 덜 민감하게 만듭니다.'),
                _Bullet('결과적으로 각성(arousal) 빈도를 낮추고, 깊은 수면 단계의 안정화에 기여할 수 있습니다.'),
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: _SectionCard(
              title: '사용 팁',
              children: [
                _Bullet('볼륨은 낮게 시작해 천천히 올리세요. 대화 소리보다 작게, 숨소리 같은 느낌이 좋습니다.'),
                _Bullet('수면 모드에서는 30~60분 타이머를 기본값으로 쓰고, 필요 시 전체 밤새도록 재생해 보세요.'),
                _Bullet('이어폰보다 스피커/수면 스피커가 편안한 경우가 많습니다.'),
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
                label: const Text('돌아가기'),
              ),
            ),
            const SizedBox(width: 12),
            /*Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, 'play_pink_noise');
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('핑크 노이즈 재생'),
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
    })..start();
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
      text: const TextSpan(
        text: '핑크 노이즈의 수면 효과',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);
    tp.paint(canvas, const Offset(20, 140));

    final sub = TextPainter(
      text: const TextSpan(
        text: 'How it works — 예측 가능한 1/f 소리로 외부 자극에 덜 깨어나도록 도와줍니다.',
        style: TextStyle(fontSize: 13, height: 1.25, color: Colors.black87),
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
        children: const [
          SizedBox(height: 8),
          _FaqTile(
            q: '화이트 노이즈와 무엇이 다른가요?',
            a:
            '화이트 노이즈는 모든 주파수에 동일한 파워가 분포하고, 핑크 노이즈는 1/f 형태로 저주파가 더 강합니다. 일반적으로 핑크 노이즈가 덜 날카롭고 더 자연스럽게 들립니다.',
          ),
          _FaqTile(
            q: '얼마나 크게 틀어야 하나요?',
            a:
            '너무 크면 오히려 각성될 수 있어요. 대화 소리보다 확실히 낮게, 존재감은 있지만 거슬리지 않는 수준이 좋습니다.',
          ),
          _FaqTile(
            q: '이어폰 vs 스피커?',
            a: '대부분은 스피커가 더 편안합니다. 다만 소음 환경이나 개인 취향에 따라 달라질 수 있어요.',
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
