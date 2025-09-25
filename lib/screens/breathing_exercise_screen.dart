import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> {
  static const totalSeconds = 180; // 3 minutes
  int remaining = totalSeconds;
  Timer? _timer;
  bool completed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (remaining <= 1) {
        t.cancel();
        setState(() {
          remaining = 0;
          completed = true;
        });
        // Award points once
        context.read<GamificationProvider>().completeBreathingExercise();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Great job! Breathing exercise completed (+5 pts)')),
        );
      } else {
        setState(() => remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _mmss(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final phase = (remaining % 16);
    // Simple breathing pattern: 4s inhale, 7s hold, 5s exhale (4-7-8)
    String cue;
    if (phase < 4) {
      cue = 'Inhale…';
    } else if (phase < 11) {
      cue = 'Hold…';
    } else {
      cue = 'Exhale…';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Exercise')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _mmss(remaining),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                cue,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 140,
                height: 140,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cue == 'Inhale…'
                        ? Colors.blue.withOpacity(0.25)
                        : cue == 'Hold…'
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.35),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!completed)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      remaining = totalSeconds;
                      completed = false;
                    });
                    _start();
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Restart'),
                ),
              if (completed)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
