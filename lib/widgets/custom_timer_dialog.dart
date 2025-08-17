import 'package:flutter/material.dart';

/// Displays a dialog that allows the user to pick a custom duration
/// using a slider. The caller can specify the minimum and maximum
/// number of minutes available. The dialog returns a [Duration]
/// representing the user's selection when the "Set" button is pressed,
/// or `null` if the dialog is dismissed.
Future<Duration?> showCustomTimerDialog({
  required BuildContext context,
  int minMinutes = 1,
  int maxMinutes = 120,
  int initialMinutes = 30,
}) async {
  double selectedMinutes = initialMinutes.toDouble().clamp(minMinutes.toDouble(), maxMinutes.toDouble());

  return showDialog<Duration>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Custom Timer Setting',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${selectedMinutes.round()} Min',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: selectedMinutes,
                    min: minMinutes.toDouble(),
                    max: maxMinutes.toDouble(),
                    divisions: maxMinutes - minMinutes,
                    label: '${selectedMinutes.round()} Min',
                    onChanged: (value) {
                      setState(() {
                        selectedMinutes = value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = selectedMinutes.round();
              Navigator.of(context).pop(Duration(minutes: minutes));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
            child: const Text('ok'),
          ),
        ],
      );
    },
  );
}