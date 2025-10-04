import 'package:flutter/material.dart';
import 'package:flutter_sleepy/data/tracks.dart';
import 'package:flutter_sleepy/models/track.dart';

class SoundSelectorCard extends StatelessWidget {
  const SoundSelectorCard({
    super.key,
    required this.value, // 'rainy' | 'waves' | 'camp fire'
    required this.onChanged,
  });

  final String value;
  final void Function(String) onChanged;

  // Helper to map track titles to icons
  IconData _getIconForTrack(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('rain')) return Icons.water_drop_outlined;
    if (lowerTitle.contains('waves')) return Icons.waves_outlined;
    if (lowerTitle.contains('fire')) return Icons.fireplace_outlined;
    if (lowerTitle.contains('pink')) return Icons.graphic_eq_outlined;
    if (lowerTitle.contains('thunder')) return Icons.thunderstorm_outlined;
    if (lowerTitle.contains('white')) return Icons.noise_aware_outlined;
    return Icons.music_note_outlined; // Default icon
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          const SizedBox(height: 12),

          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.center,
            children: TracksData.tracks.map((track) {
              final isSelected = value == track.title.toLowerCase();
              return _SoundButton(
                track: track,
                icon: _getIconForTrack(track.title),
                isSelected: isSelected,
                onTap: () => onChanged(track.title.toLowerCase()),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SoundButton extends StatelessWidget {
  const _SoundButton({
    required this.track,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final Track track;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final backgroundColor =
        isSelected ? cs.primaryContainer : cs.surfaceContainerHighest.withOpacity(0.35);
    final foregroundColor = isSelected ? cs.onPrimaryContainer : cs.onSurface;
    final borderColor = isSelected ? cs.primary.withOpacity(0.75) : cs.outlineVariant.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(icon, size: 32, color: foregroundColor),
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foregroundColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}