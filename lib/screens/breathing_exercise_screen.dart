import 'dart:async';
import 'package:flutter/material.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  String _instruction = 'Ready to Start?';
  bool _isRunning = false;

  // Define the 4-7-8 cycle durations
  final int _inhaleTime = 4;
  final int _holdTime = 7;
  final int _exhaleTime = 8;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Duration will be set dynamically during the cycle.
    );

    _animation = Tween<double>(begin: 80.0, end: 220.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Prevent memory leaks by disposing of the controller
    _isRunning = false;
    _controller.dispose();
    super.dispose();
  }

  void _toggleExercise() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _runBreathingCycle();
      } else {
        _controller.reset();
        _instruction = 'Ready to Start?';
      }
    });
  }

  Future<void> _runBreathingCycle() async {
    // This loop continues as long as the exercise is running
    while (_isRunning) {
      // --- Inhale Phase ---
      if (!_isRunning) break;
      setState(() {
        _instruction = 'Breathe In...';
        _controller.duration = Duration(seconds: _inhaleTime);
      });
      await _controller.forward(from: 0.0);

      // --- Hold Phase ---
      if (!_isRunning) break;
      setState(() {
        _instruction = 'Hold';
      });
      await Future.delayed(Duration(seconds: _holdTime));

      // --- Exhale Phase ---
      if (!_isRunning) break;
      setState(() {
        _instruction = 'Breathe Out...';
        _controller.duration = Duration(seconds: _exhaleTime);
      });
      await _controller.reverse(from: 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('4-7-8 Breathing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    width: _animation.value,
                    height: _animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primaryContainer.withOpacity(0.8),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              Text(
                _instruction,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _toggleExercise,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: _isRunning ? theme.colorScheme.errorContainer : theme.colorScheme.primary,
                  foregroundColor: _isRunning ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _isRunning ? 'Stop' : 'Start',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}