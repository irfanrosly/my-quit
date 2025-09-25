import '../chatbot/myquitmate_chatbot.dart'; // <-- tambah ini
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Providers
import '../state/gamification_provider.dart';
import '../state/onboarding_provider.dart';

// Screens
import 'progress_screen.dart';
import 'craving_toolkit_screen.dart';
import 'badges_screen.dart';
import 'mood_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _days = 0;

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
    setState(() => _days = d < 0 ? 0 : d);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GamificationProvider>();
    final o = context.watch<OnboardingProvider>();

    // Pastikan ada nilai yang munasabah untuk papar di dashboard:
    // - guna provider jika ada (g.smokeFreeDays), kalau 0, fallback pada bacaan local _days
    final daysToShow = (g.smokeFreeDays > 0) ? g.smokeFreeDays : _days;
    final moneySaved = o.state.habits.dailyCost * daysToShow;

    return Scaffold(
  appBar: AppBar(
    title: const Text('MYQuitMate Dashboard'),
  ),
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // --- Stats ringkas (LIVE) ---
      _StatCard(
        title: 'Days Smoke-Free',
        value: '$daysToShow',
        subtitle: daysToShow > 0 ? 'Keep it up!' : 'Let’s get started',
        icon: Icons.calendar_month,
      ),
      const SizedBox(height: 12),
      _StatCard(
        title: 'Money Saved',
        value: 'RM ${moneySaved.toStringAsFixed(2)}',
        subtitle: moneySaved > 0 ? 'Nice progress' : 'Start your quit plan',
        icon: Icons.savings_outlined,
      ),
      const SizedBox(height: 8),

      // (Opsyen) refresh kecil untuk sync semula nilai kalau perlu
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () async {
            await _loadDays();
            // sync juga ke provider supaya konsisten di skrin lain
            context.read<GamificationProvider>()
              .sync(days: daysToShow, saved: moneySaved);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dashboard refreshed')),
            );
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ),

      const SizedBox(height: 8),
      Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),

      // --- Actions as Grid (ikon besar) ---
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _ActionTile(
            icon: Icons.insights,
            color: Colors.blue,
            label: 'Progress',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProgressScreen()),
              );
            },
          ),
          _ActionTile(
            icon: Icons.health_and_safety_outlined,
            color: Colors.green,
            label: 'Craving Toolkit',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CravingToolkitScreen()),
              );
            },
          ),
          _ActionTile(
            icon: Icons.flag,
            color: Colors.orange,
            label: 'Start Plan',
            onTap: () => Navigator.pushNamed(context, '/onboarding/profile'),
          ),
          _ActionTile(
            icon: Icons.emoji_events,
            color: Colors.purple,
            label: 'Badges',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BadgesScreen()),
              );
            },
          )
        ],
      ),
    ],
  ), // <— PERHATIKAN koma ni, penting!
       // ===== FAB CHATBOT =====
  floatingActionButton: FloatingActionButton.extended(
    heroTag: 'chat_fab',
    onPressed: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MyQuitMateChatBot(
        ctx: ChatContext(
          daysSmokeFree: daysToShow, // <-- nilai dari dashboard awak
          locale: 'ms',              // atau 'en' kalau nak English
        ),
      ),
    ),
  );
},
    icon: const Icon(Icons.chat_bubble_rounded),
    label: const Text('Chat'),
  ),
  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
);
  }
}

// Reusable Stat Card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

// Reusable Action Tile (ikon besar + label) untuk grid
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
