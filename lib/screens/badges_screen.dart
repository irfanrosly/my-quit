import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  // Master list semua badges + description + icon
  List<_BadgeMeta> get _allBadges => const [
  _BadgeMeta(
    title: 'Day 1: Fresh Start',
    description: 'Smoke-free day one – the start of something great.',
    icon: Icons.wb_sunny_outlined,
  ),
  _BadgeMeta(
    title: '72 Hours: Detox Hero',
    description: 'Day 3 – breathe easier and feel more energetic',
    icon: Icons.bolt_outlined,
  ),
  _BadgeMeta(
    title: '1 Week: Stable Steps',
    description: 'Week 1 - Lungs are working better and blood’s moving well.',
    icon: Icons.directions_walk,
  ),
  _BadgeMeta(
    title: '14 Days: Halfway Fortnight',
    description: 'Week 2 - Momentum is getting stronger',
    icon: Icons.flag_circle_outlined,
  ),
  _BadgeMeta(
    title: '3 Months: Clearer Breath',
    description: 'Month 3 - Breathing gets easier, and appetite improves.',
    icon: Icons.air_outlined,
  ),
  _BadgeMeta(
    title: '6 Months: Strong Will',
    description: 'Month 6 - Resilience is clearly proven!',
    icon: Icons.shield_outlined,
  ),
  _BadgeMeta(
    title: 'RM100 Saved',
    description: 'Your savings journey has begun!',
    icon: Icons.savings_outlined,
  ),
  _BadgeMeta(
    title: 'RM500 Saved',
    description: 'Your wallet’s smiling!',
    icon: Icons.account_balance_wallet_outlined,
  ),
  _BadgeMeta(
    title: 'RM1000 Saved',
    description: 'Your money’s ready to work for you!',
    icon: Icons.attach_money,
  ),
  _BadgeMeta(
    title: '5 Mini-Tasks Completed',
    description: 'Great coping',
    icon: Icons.task_alt,
  ),
  _BadgeMeta(
    title: '10 Mini-Tasks Completed',
    description: 'Ten mini-tasks - consistent!',
    icon: Icons.star_half,
  ),
  _BadgeMeta(
    title: '20 Mini-Tasks Completed',
    description: 'Twenty mini-tasks - champion!',
    icon: Icons.workspace_premium_outlined,
  ),
  _BadgeMeta(
  title: '7 Days Logged',
  description: 'Mood & craving logged for a week - keep the rhythm going!',
  icon: Icons.event_available,
),
_BadgeMeta(
  title: '30 Days Logged',
  description: 'Consistent logging for 30 days - your commitment speaks volumes!',
  icon: Icons.calendar_month,
),

];

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GamificationProvider>();
    final unlocked = g.badges.toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ringkasan
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events),
              title: Text('Unlocked: ${unlocked.length}/${_allBadges.length}'),
              subtitle: const Text('Collect all badges by staying consistent!'),
            ),
          ),
          const SizedBox(height: 12),

          // Grid badges
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _allBadges.map((b) {
              final isUnlocked = unlocked.contains(b.title);
              return _BadgeTile(meta: b, unlocked: isUnlocked);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _BadgeMeta meta;
  final bool unlocked;
  const _BadgeTile({required this.meta, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? Theme.of(context).colorScheme.primary : Colors.grey;
    final bg = unlocked ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade200;

    return Card(
      elevation: unlocked ? 2 : 0,
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(meta.icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              meta.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              meta.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: unlocked ? Colors.black87 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(unlocked ? 'Unlocked' : 'Locked'),
              avatar: Icon(
                unlocked ? Icons.check_circle : Icons.lock_outline,
                size: 18,
                color: unlocked ? Colors.green : Colors.grey,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeMeta {
  final String title;
  final String description;
  final IconData icon;
  const _BadgeMeta({required this.title, required this.description, required this.icon});
}
