import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';
import '../state/onboarding_provider.dart';
import '../screens/badges_screen.dart'; // sesuaikan laluan jika perlu
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; // Clipboard fallback

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int days = 0;
  final int goal = 30;

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  Future<void> _loadDays() async {
    final p = await SharedPreferences.getInstance();
    final start = p.getInt('startDate') ?? DateTime.now().millisecondsSinceEpoch;
    final sd = DateTime.fromMillisecondsSinceEpoch(start);
    final d = DateTime.now().difference(DateTime(sd.year, sd.month, sd.day)).inDays;
    if (!mounted) return;
    setState(() => days = d < 0 ? 0 : d);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (days / goal).clamp(0.0, 1.0);

    // Sync dengan providers
    final g = context.watch<GamificationProvider>();
    final o = context.watch<OnboardingProvider>();
    final double moneySaved = (o.state.habits.dailyCost) * days;
    g.sync(days: days, saved: moneySaved);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Progress"),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          

          // Header / Streak
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2FBF71), Color(0xFF7BE495)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Smoke-free Streak', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('$days day(s)',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700,
                        )),
                  ]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Health Progress
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.health_and_safety),
                  SizedBox(width: 8),
                  Text('Health Progress'),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: progress, minHeight: 12),
                ),
                const SizedBox(height: 8),
                Text('Goal: $goal days • Current: $days'),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // Savings & Points
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.savings_outlined),
                  SizedBox(width: 8),
                  Text('Savings & Points'),
                ]),
                const SizedBox(height: 12),
                Text('Money Saved: RM ${moneySaved.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                Text('Base Points (days+RM): ${g.basePoints}'),
                Text('Extra Points: ${g.extraPoints}'),
                Text('Cravings Managed: ${g.cravingsManaged}'),
                Text(
                  'Total Points: ${g.totalPoints}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ]),
            ),
          ),

          // Weekly Recap
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.calendar_view_week),
                  SizedBox(width: 8),
                  Text('This Week'),
                ]),
                const SizedBox(height: 12),
                Text('Smoke-Free Days (this week est.): '
                    '${DateTime.now().weekday < g.smokeFreeDays ? DateTime.now().weekday : g.smokeFreeDays} / 7'),
                Text('Money Saved (this week): RM ${g.weeklyMoneySaved.toStringAsFixed(2)}'),
                Text('Extra Points (this week): ${g.weeklyExtraPoints}'),
                Text(
                  'Weekly Total Points: ${g.weeklyTotalPoints}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // Achievements + "I managed a craving"
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.emoji_events_outlined),
                  SizedBox(width: 8),
                  Text('Achievements'),
                ]),
                const SizedBox(height: 12),
                if (g.badges.isEmpty)
                  const Text('No badges yet — keep going!')
                else
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: g.badges
                        .map((b) => Chip(
                              avatar: const Icon(Icons.emoji_events, size: 18),
                              label: Text(b),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.read<GamificationProvider>().addCravingManaged(),
                  icon: const Icon(Icons.self_improvement_outlined),
                  label: const Text('I managed a craving'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BadgesScreen()),
                    );
                  },
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('View All Badges'),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // Milestones
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const ListTile(
                leading: Icon(Icons.emoji_events),
                title: Text('Milestones'),
                subtitle: Text('Congratulations for every small step!'),
              ),
              const Divider(height: 1),
              _milestoneTile('24 hours', days >= 1,  'Body starts clearing out leftover dirt and chemicals from smoking in the blood and lungs.'),
              _milestoneTile('3 days', days >= 3,  'Lungs help with easier breathing, and without nicotine, energy levels begin to rise.'),
              _milestoneTile('1 week', days >= 7,'Lung function and blood circulation are improving.'),
              _milestoneTile('1 month', days >= 30,'Lungs begin to heal and breathing becomes easier. Appetite improves.'),
              const SizedBox(height: 8),
            ]),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<GamificationProvider>().resetAll();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress reset (testing)')),
                  );
                },
                icon: const Icon(Icons.restore),
                label: const Text('Reset Progress (testing)'),
              ),
              // Share Progress
              FilledButton.icon(
                onPressed: () => _shareProgress(context),
                icon: const Icon(Icons.share),
                label: const Text('Share Progress'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.dashboard),
                label: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ListTile _milestoneTile(String label, bool unlocked, String note) {
    return ListTile(
      leading: Icon(
        unlocked ? Icons.check_circle : Icons.radio_button_unchecked,
        color: unlocked ? const Color(0xFF2FBF71) : null,
      ),
      title: Text(label),
      subtitle: Text(note),
      trailing: Text(
        unlocked ? 'Unlocked' : 'Locked',
        style: TextStyle(
          color: unlocked ? const Color(0xFF2FBF71) : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ====== SHARE HELPERS ======
  Future<void> _shareProgress(BuildContext context) async {
    final g = context.read<GamificationProvider>();

    final msg = _buildShareMessage(
      days: days,
      moneySaved: g.moneySaved, // guna total; tukar ke g.weeklyMoneySaved jika mahu
      totalPoints: g.totalPoints,
      badges: g.badges,
    );

    try {
      await Share.share(msg);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: msg));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message copied to clipboard')),
      );
    }
  }

  String _buildShareMessage({
    required int days,
    required double moneySaved,
    required int totalPoints,
    required List<String> badges,
  }) {
    final topBadges = (badges.isEmpty)
        ? '—'
        : (badges.length <= 3 ? badges : badges.take(3)).join(' • ');

    return [
      'Saya dah $days hari bebas rokok! 💪',
      'Jimat: RM ${moneySaved.toStringAsFixed(2)}',
      'Mata Terkumpul: $totalPoints',
      if (topBadges != '—') 'Badges: $topBadges',
      '#MyQuitMate #QuitSmoking #HealthJourney'
    ].join('\n');
  }
}
