import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';

class DistractionTasksScreen extends StatefulWidget {
  const DistractionTasksScreen({super.key});

  @override
  State<DistractionTasksScreen> createState() => _DistractionTasksScreenState();
}

class _DistractionTasksScreenState extends State<DistractionTasksScreen> {
  final tasks = const [
    'Do physical activity or exercise',
    'Drink a glass of water',
    'Message a support buddy',
    'Eat fruits/chew gum',
    'Meditate/pray',
    'Say a positive affirmation',
    'Go for a walk',
    'Relax',
    'Do household chores',
    'Play with a stress ball',
    'Listen to music',
    'Watch television',
  ];

  String? selectedTask;
  int durationSec = 90; // default 90s
  Timer? _timer;
  int remaining = 0;
  bool running = false;
  bool completed = false;

  void _start() {
    if (selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih satu mini-task dulu')),
      );
      return;
    }
    setState(() {
      running = true;
      completed = false;
      remaining = durationSec;
    });
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
        await context.read<GamificationProvider>().addCravingManaged(); // +3 pts & save
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nice! +3 points')),
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
    final g = context.watch<GamificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Distraction Mini-Tasks')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Your Points'),
              trailing: Text('${g.totalPoints}'),
            ),
          ),
          const SizedBox(height: 12),

          Text('Please pick a task', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: tasks.map((t) {
              final sel = selectedTask == t;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => setState(() => selectedTask = t),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Duration: '),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: durationSec,
                items: const [
                  DropdownMenuItem(value: 60, child: Text('60s (quick)')),
                  DropdownMenuItem(value: 90, child: Text('90s (default)')),
                  DropdownMenuItem(value: 120, child: Text('120s')),
                ],
                onChanged: running ? null : (v) => setState(() => durationSec = v ?? 90),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  _mmss(remaining > 0 ? remaining : durationSec),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  running ? 'Stay with it…' : (completed ? 'Completed!' : 'Ready?'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (!running && !completed)
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                if (running)
                  OutlinedButton.icon(
                    onPressed: () {
                      _timer?.cancel();
                      setState(() {
                        running = false;
                        remaining = 0;
                      });
                    },
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Cancel'),
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
        ],
      ),
    );
  }
}
