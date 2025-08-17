import 'package:flutter/material.dart';

/// Displays a dialog that allows the user to pick a custom duration
/// using a slider. The caller can specify the minimum and maximum
/// number of minutes available. The dialog returns a [Duration]
/// representing the user's selection when the "Set" button is pressed,
/// or `null` if the dialog is dismissed.
Future<Duration?> showCustomTimerDialog({
  required BuildContext context,
  int minMinutes = 1,
  int maxMinutes = 180,
  int initialMinutes = 30,
}) async {
  double selectedMinutes = initialMinutes.toDouble().clamp(minMinutes.toDouble(), maxMinutes.toDouble());

  return showDialog<Duration>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          '커스텀 타이머 설정',
          style: const TextStyle(color: Colors.tealAccent),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${selectedMinutes.round()} 분',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: selectedMinutes,
                    min: minMinutes.toDouble(),
                    max: maxMinutes.toDouble(),
                    divisions: maxMinutes - minMinutes,
                    label: '${selectedMinutes.round()} 분',
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
            child: const Text('취소', style: TextStyle(color: Colors.tealAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = selectedMinutes.round();
              Navigator.of(context).pop(Duration(minutes: minutes));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: const Text('설정', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}