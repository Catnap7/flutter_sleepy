import 'package:flutter/material.dart';

class SoundSelectorCard extends StatelessWidget {
  const SoundSelectorCard({
    super.key,
    required this.value, // 'rainy' | 'waves' | 'camp fire'
    required this.onChanged,
  });

  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const items = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'rainy', child: Text('Rainy')),
      DropdownMenuItem(value: 'waves', child: Text('Waves')),
      DropdownMenuItem(value: 'camp fire', child: Text('Camp Fire')),
      DropdownMenuItem(value: 'pink noise', child: Text('Pink Noise')),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Caption row (prevents label overlap & matches app tone)
          Row(
            children: [
              Icon(Icons.music_note_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Choose a sound',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            items: items,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            dropdownColor: cs.surface,
            iconEnabledColor: cs.primary,
            iconDisabledColor: cs.outline,
            decoration: InputDecoration(
              // prefixIcon: Icon(Icons.audiotrack_rounded, color: cs.primary),
              filled: true,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              fillColor: cs.surfaceContainerHighest.withOpacity(0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
