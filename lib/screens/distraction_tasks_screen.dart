import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';

class DistractionTasksScreen extends StatefulWidget {
  const DistractionTasksScreen({super.key});

  @override
  State<DistractionTasksScreen> createState() => _DistractionTasksScreenState();
}

class _DistractionTasksScreenState extends State<DistractionTasksScreen>
    with TickerProviderStateMixin {
  final tasks = const [
    {'name': 'Do physical activity', 'icon': Icons.fitness_center},
    {'name': 'Drink water', 'icon': Icons.water_drop},
    {'name': 'Message a buddy', 'icon': Icons.message},
    {'name': 'Eat fruits/chew gum', 'icon': Icons.apple},
    {'name': 'Meditate/pray', 'icon': Icons.self_improvement},
    {'name': 'Positive affirmation', 'icon': Icons.psychology},
    {'name': 'Go for a walk', 'icon': Icons.directions_walk},
    {'name': 'Relax & breathe', 'icon': Icons.spa},
    {'name': 'Do household chores', 'icon': Icons.cleaning_services},
    {'name': 'Stress ball', 'icon': Icons.sports_baseball},
    {'name': 'Listen to music', 'icon': Icons.music_note},
    {'name': 'Watch television', 'icon': Icons.tv},
  ];

  String? selectedTask;
  int durationSec = 90; // default 90s
  Timer? _timer;
  int remaining = 0;
  bool running = false;
  bool completed = false;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: durationSec),
    );
  }

  void _start() {
    if (selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a task first')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      running = true;
      completed = false;
      remaining = durationSec;
    });

    _progressController.duration = Duration(seconds: durationSec);
    _progressController.forward(from: 0.0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      if (remaining <= 1) {
        t.cancel();
        setState(() {
          remaining = 0;
          running = false;
          completed = true;
        });
        HapticFeedback.heavyImpact();
        await context.read<GamificationProvider>().addCravingManaged(); // +3 pts & save
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Awesome! You completed the task (+3 pts)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (remaining <= 10) {
          HapticFeedback.lightImpact();
        }
        setState(() => remaining--);
      }
    });
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _progressController.stop();
    setState(() {
      running = false;
      remaining = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _mmss(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GamificationProvider>();
    final progress = remaining > 0 ? (1 - remaining / durationSec) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distraction Mini-Tasks'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade100,
                  Colors.orange.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Distraction',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                      ),
                      Text(
                        'Choose an activity to help ride out the craving',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Task selection
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Choose Your Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Task chips with icons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tasks.map((task) {
              final taskName = task['name'] as String;
              final taskIcon = task['icon'] as IconData;
              final isSelected = selectedTask == taskName;

              return FilterChip(
                avatar: Icon(
                  taskIcon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.orange.shade700,
                ),
                label: Text(taskName),
                selected: isSelected,
                onSelected: running ? null : (_) {
                  HapticFeedback.selectionClick();
                  setState(() => selectedTask = taskName);
                },
                selectedColor: Colors.orange.shade400,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                elevation: isSelected ? 4 : 0,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Duration selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: Colors.grey[700]),
                const SizedBox(width: 12),
                const Text('Duration:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<int>(
                    selected: {durationSec},
                    onSelectionChanged: running ? null : (Set<int> selection) {
                      HapticFeedback.selectionClick();
                      setState(() => durationSec = selection.first);
                    },
                    segments: const [
                      ButtonSegment(value: 60, label: Text('60s')),
                      ButtonSegment(value: 90, label: Text('90s')),
                      ButtonSegment(value: 120, label: Text('2 min')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Timer display
          Center(
            child: Column(
              children: [
                // Circular progress indicator
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing circle (only when running)
                        if (running)
                          Container(
                            width: 220 + (_pulseController.value * 20),
                            height: 220 + (_pulseController.value * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange.withOpacity(0.1 * (1 - _pulseController.value)),
                            ),
                          ),
                        // Progress circle
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _CircularProgressPainter(
                                  progress: running ? _progressController.value : progress,
                                  color: completed ? Colors.green : Colors.orange,
                                ),
                                child: child,
                              );
                            },
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _mmss(remaining > 0 ? remaining : durationSec),
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 56,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: running
                                          ? Colors.orange.shade100
                                          : completed
                                              ? Colors.green.shade100
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      running
                                          ? 'Keep going!'
                                          : completed
                                              ? 'Complete!'
                                              : 'Ready to start',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: running
                                            ? Colors.orange.shade700
                                            : completed
                                                ? Colors.green.shade700
                                                : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Action buttons
                if (!running && !completed)
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: const Text('Start Activity', style: TextStyle(fontSize: 16)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                if (running)
                  OutlinedButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.stop_circle_outlined, size: 28),
                    label: const Text('Cancel', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(color: Colors.red.shade300),
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
                        Icons.celebration,
                        size: 64,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Great Job!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You successfully completed: $selectedTask',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade400,
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

          const SizedBox(height: 32),

          // Points display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade200,
                  Colors.amber.shade300,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Total Points: ${g.totalPoints}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 6, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
