import 'package:flutter/material.dart';
import 'package:flutter_sleepy/theme/app_theme.dart'; // for context.sp / context.radii

/// A custom-themable timer dialog that respects your AppTheme
/// (spacing/radii tokens) and per-sound accent via current ColorScheme.
Future<Duration?> showCustomTimerDialog({
  required BuildContext context,
  int minMinutes = 1,
  int maxMinutes = 120,
  int initialMinutes = 30,
}) async {
  assert(minMinutes > 0 && maxMinutes >= minMinutes);

  double selected = initialMinutes
      .clamp(minMinutes, maxMinutes)
      .toDouble();

  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  return showDialog<Duration>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radii.lg),
        ),
        titlePadding: EdgeInsets.fromLTRB(
          context.sp.lg, context.sp.lg, context.sp.lg, context.sp.sm,
        ),
        contentPadding: EdgeInsets.fromLTRB(
          context.sp.lg, context.sp.md, context.sp.lg, context.sp.md,
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          context.sp.lg, 0, context.sp.lg, context.sp.lg,
        ),
        title: Row(
          children: [
            Icon(Icons.timer_rounded, size: 20, color: cs.primary),
            SizedBox(width: context.sp.sm),
            Text(
              'Custom Timer',
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${selected.round()} min',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.sp.md),
                  Slider(
                    value: selected,
                    min: minMinutes.toDouble(),
                    max: maxMinutes.toDouble(),
                    divisions: (maxMinutes - minMinutes) > 0
                        ? (maxMinutes - minMinutes)
                        : null,
                    label: '${selected.round()} min',
                    onChanged: (v) => setState(() => selected = v),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(Duration(minutes: selected.round()));
            },
            child: const Text('Set'),
          ),
        ],
      );
    },
  );
}
