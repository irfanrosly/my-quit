import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';
import 'breathing_exercise_screen.dart';
import 'distraction_tasks_screen.dart';
import 'mood_log_screen.dart'; // <--- tambah import

class CravingToolkitScreen extends StatelessWidget {
  const CravingToolkitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GamificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Craving Toolkit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Breathing Exercise
          Card(
            child: ListTile(
              leading: const Icon(Icons.air),
              title: const Text('Breathing Exercise'),
              subtitle: const Text('3-minute guided breathing'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BreathingExerciseScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Distraction Mini-Tasks
          Card(
            child: ListTile(
              leading: const Icon(Icons.games_outlined),
              title: const Text('Distraction Mini-Tasks'),
              subtitle: const Text('90-second quick tasks to ride out cravings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DistractionTasksScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Mood & Craving Log  (+2 pts per log)
          Card(
            child: ListTile(
              leading: const Icon(Icons.mood_outlined),
              title: const Text('Mood & Craving Log'),
              subtitle: const Text('Track mood and cravings daily (+2 pts)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MoodLogScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Call Support (placeholder)
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Call Support'),
              subtitle: const Text('Reach a quitline / buddy'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon: Support contacts')),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Points summary
          Card(
            child: ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Your Points'),
              trailing: Text('${g.totalPoints}'),
            ),
          ),
        ],
      ),
    );
  }
}
