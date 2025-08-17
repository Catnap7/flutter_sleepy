import 'package:flutter/material.dart';

/// A mood-aware call-to-action button that adapts to the current ColorScheme.
/// Works great with your per-sound accent (primary changes by sound).
class ThemedActionButton extends StatelessWidget {
  const ThemedActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Base tones — derived from current scheme (already tinted per sound)
    final baseBg = cs.primaryContainer.withOpacity(0.88);
    final baseFg = cs.onPrimaryContainer;

    final pressedBg = Color.alphaBlend(cs.primary.withOpacity(0.22), cs.primaryContainer);
    final hoveredBg = Color.alphaBlend(cs.primary.withOpacity(0.12), cs.primaryContainer);

    final sideIdle   = BorderSide(color: cs.primary.withOpacity(0.28));
    final sideHover  = BorderSide(color: cs.primary.withOpacity(0.40));
    final sidePress  = BorderSide(color: cs.primary.withOpacity(0.55));

    final pad = dense ? const EdgeInsets.symmetric(horizontal: 18, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 14);

    final radius = BorderRadius.circular(16);

    final style = ButtonStyle(
      padding: WidgetStateProperty.all(pad),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: radius)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return pressedBg;
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return hoveredBg;
        return baseBg;
      }),
      foregroundColor: WidgetStateProperty.all(baseFg),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return cs.primary.withOpacity(0.12);
        if (states.contains(WidgetState.hovered)) return cs.primary.withOpacity(0.06);
        return Colors.transparent;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return sidePress;
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return sideHover;
        return sideIdle;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return 0.0;
        if (states.contains(WidgetState.pressed)) return 0.0;
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return 2.0;
        return 1.0;
      }),
      shadowColor: WidgetStateProperty.all(cs.primary.withOpacity(0.20)),
      minimumSize: WidgetStateProperty.all(Size(dense ? 0 : 0, dense ? 44 : 48)),
      alignment: Alignment.center,
    );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 10),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        )
      ],
    );

    return ElevatedButton(style: style, onPressed: onPressed, child: child);
  }
}


