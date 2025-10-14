import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> with SingleTickerProviderStateMixin {
  static const totalSeconds = 180; // 3 minutes
  int remaining = totalSeconds;
  Timer? _timer;
  bool completed = false;
  late AnimationController _breathController;
  int _lastPhase = 0;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
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
        _breathController.stop();
        // Award points once
        context.read<GamificationProvider>().completeBreathingExercise();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Great job! Breathing exercise completed (+5 pts)')),
        );
      } else {
        setState(() => remaining--);
        _updateBreathingAnimation();
      }
    });
  }

  void _updateBreathingAnimation() {
    final phase = remaining % 16;

    // Trigger haptic feedback on phase change
    if (_lastPhase != phase && (phase == 0 || phase == 4 || phase == 11)) {
      HapticFeedback.lightImpact();
    }
    _lastPhase = phase;

    if (phase < 4) {
      // Inhale: expand
      _breathController.duration = const Duration(seconds: 4);
      _breathController.forward(from: (phase) / 4);
    } else if (phase < 11) {
      // Hold: stay expanded
      _breathController.value = 1.0;
    } else {
      // Exhale: contract
      _breathController.duration = const Duration(seconds: 5);
      _breathController.reverse(from: 1.0 - ((phase - 11) / 5));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  String _mmss(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  Color _getPhaseColor(String cue) {
    switch (cue) {
      case 'Inhale…':
        return const Color(0xFF4FC3F7); // Light blue
      case 'Hold…':
        return const Color(0xFF7E57C2); // Purple
      case 'Exhale…':
        return const Color(0xFF81C784); // Green
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = (remaining % 16);
    final progress = 1.0 - (remaining / totalSeconds);

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
      appBar: AppBar(
        title: const Text('Breathing Exercise'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getPhaseColor(cue).withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _mmss(remaining),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _breathController,
                  builder: (context, child) {
                    final scale = 0.6 + (_breathController.value * 0.4);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _getPhaseColor(cue).withOpacity(0.6),
                              _getPhaseColor(cue).withOpacity(0.2),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getPhaseColor(cue).withOpacity(0.4),
                              blurRadius: 40 * scale,
                              spreadRadius: 10 * scale,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getPhaseColor(cue).withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    cue,
                    key: ValueKey(cue),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _getPhaseColor(cue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  cue == 'Inhale…'
                      ? 'Breathe in slowly through your nose'
                      : cue == 'Hold…'
                          ? 'Hold your breath gently'
                          : 'Breathe out slowly through your mouth',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                if (!completed)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        remaining = totalSeconds;
                        completed = false;
                        _lastPhase = 0;
                      });
                      _breathController.reset();
                      _start();
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restart'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                if (completed)
                  Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.green[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Exercise Complete!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
