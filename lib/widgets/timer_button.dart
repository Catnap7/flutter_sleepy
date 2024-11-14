import 'package:flutter/material.dart';

class TimerButton extends StatelessWidget {
  final String label;
  final Duration duration;
  final VoidCallback onPressed;

  const TimerButton({
    required this.label,
    required this.duration,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(label),
    );
  }
}