import 'package:flutter/material.dart';
import 'package:flutter_sleepy/theme/theme_controller.dart';

class ThemeSettingsScreen extends StatelessWidget {
  final ThemeController controller;
  const ThemeSettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget tile({required String title, required String subtitle, required AppThemeOption value, required IconData icon}) {
      final selected = controller.option == value;
      return ListTile(
        leading: Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected ? Icon(Icons.radio_button_checked, color: cs.primary) : const Icon(Icons.radio_button_off),
        onTap: () async {
          await controller.setOption(value);
          // ignore: use_build_context_synchronously
          Navigator.of(context).maybePop();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          tile(
            title: 'Sleep Mode',
            subtitle: 'Muted warm tones optimized for bedtime',
            value: AppThemeOption.sleep,
            icon: Icons.bedtime_rounded,
          ),
          tile(
            title: 'Day Mode',
            subtitle: 'Brighter, vibrant palette',
            value: AppThemeOption.day,
            icon: Icons.wb_sunny_rounded,
          ),
          tile(
            title: 'Dynamic (Android 12+)',
            subtitle: 'Adapts to system wallpaper colors when available',
            value: AppThemeOption.dynamic,
            icon: Icons.color_lens_rounded,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tip: Sleep Mode avoids bright blues/whites to reduce melatonin disruption, using gentle purples and warm grays.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final v = controller.bgIntensity;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Background FX Intensity', style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: v,
                            min: 0.5,
                            max: 1.5,
                            divisions: 10,
                            label: v.toStringAsFixed(2),
                            onChanged: (nv) => controller.setBgIntensity(nv),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(v.toStringAsFixed(2), textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                    Text(
                      'Lower saves battery, higher adds detail. Default 1.00',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

