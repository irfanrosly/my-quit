import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  int mood = 3;      // 1..5
  int craving = 3;   // 1..5
  final TextEditingController noteCtrl = TextEditingController();

  final moods = const ['😞','🙁','😐','🙂','😄'];

  @override
  void initState() {
    super.initState();
    final g = context.read<GamificationProvider>();
    final today = g.todayLog();
    if (today != null) {
      mood = today.mood;
      craving = today.craving;
      noteCtrl.text = today.note ?? '';
    }
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GamificationProvider>();
    final today = g.todayLog();

    return Scaffold(
      appBar: AppBar(title: const Text('Mood & Craving Log')),
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

          Text('Mood (1–5)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(5, (i) {
              final idx = i + 1;
              return ChoiceChip(
                label: Text('${moods[i]}  $idx'),
                selected: mood == idx,
                onSelected: (_) => setState(() => mood = idx),
              );
            }),
          ),

          const SizedBox(height: 16),
          Text('Craving level (1–5)', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: craving.toDouble(),
            min: 1, max: 5, divisions: 4,
            label: '$craving',
            onChanged: (v) => setState(() => craving = v.round()),
          ),

          const SizedBox(height: 8),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              await context.read<GamificationProvider>().addMoodLog(
                mood: mood, craving: craving, note: noteCtrl.text.trim(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(today == null
                  ? 'Logged! (+2 pts)'
                  : 'Updated today\'s log (+2 pts)')),
              );
            },
            icon: const Icon(Icons.save),
            label: Text(today == null ? 'Save today\'s log' : 'Update today\'s log'),
          ),

          const SizedBox(height: 20),
          Text('Past 7 days', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const _RecentList(),
          const SizedBox(height: 12),
          const _TinyBars(),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<GamificationProvider>().recent7;
    if (logs.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('No logs yet'),
          subtitle: Text('Log your first mood & craving today.'),
        ),
      );
    }
    return Column(
      children: logs.map((e) {
        final d = '${e.date.day.toString().padLeft(2,'0')}/${e.date.month.toString().padLeft(2,'0')}';
        final face = ['😞','🙁','😐','🙂','😄'][e.mood-1];
        return Card(
          child: ListTile(
            leading: Text(face, style: const TextStyle(fontSize: 22)),
            title: Text('Mood ${e.mood} • Craving ${e.craving}'),
            subtitle: e.note?.isNotEmpty == true ? Text(e.note!) : null,
            trailing: Text(d),
          ),
        );
      }).toList(),
    );
  }
}

class _TinyBars extends StatelessWidget {
  const _TinyBars();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<GamificationProvider>().recent7;
    if (logs.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('7-day mini chart'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: logs.map((e) {
                final mh = e.mood * 10.0;     // mood bar height
                final ch = e.craving * 10.0;  // craving bar height
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(height: mh, width: 10, color: Colors.blue),
                      const SizedBox(height: 4),
                      Container(height: ch, width: 10, color: Colors.red),
                      const SizedBox(height: 4),
                      Text('${e.date.day}', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: Colors.blue, label: 'Mood'),
                SizedBox(width: 12),
                _Legend(color: Colors.red, label: 'Craving'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color; final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
