import 'package:flutter/material.dart';

class ExplainScreen extends StatelessWidget {
  const ExplainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("핑크 노이즈의 수면 효과"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            const EffectCard(
              title: "수면의 질 향상",
              description:
              "핑크 노이즈는 깊은 수면을 유도하여 전반적인 수면의 질을 향상시킬 수 있습니다. 더 오래 자고 일어났을 때 더욱 상쾌함을 느낄 수 있습니다.",
            ),
            const EffectCard(
              title: "집중력 및 기억력 개선",
              description:
              "양질의 수면은 뇌의 기능을 최적화하는 데 도움이 됩니다. 특히, 핑크 노이즈는 기억력과 학습 능력을 증진시키는 효과가 있어, 깨어 있는 동안 더 나은 집중력을 발휘할 수 있습니다.",
            ),
            const EffectCard(
              title: "이명 증상 완화",
              description:
              "핑크 노이즈는 귀에서 발생하는 불쾌한 소리인 이명을 완화하는 데 도움이 될 수 있습니다. 배경 소음으로 작용하여 이명 증상을 덜 느끼게 합니다.",
            ),
            const EffectCard(
              title: "스트레스 감소",
              description:
              "부드럽고 일정한 소리는 스트레스를 줄이고 마음을 진정시키는 데 도움이 됩니다. 핑크 노이즈를 통해 심신의 이완을 경험해 보세요.",
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("돌아가기"),
            ),
          ],
        ),
      ),
    );
  }
}

class EffectCard extends StatelessWidget {
  final String title;
  final String description;

  const EffectCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}
