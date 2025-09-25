import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/onboarding_provider.dart';
import '../../models/onboarding_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingSummaryScreen extends StatelessWidget {
  const OnboardingSummaryScreen({super.key});

  String dependenceLabel(int? cpd, TTFC? ttfc) {
    int level = 0;
    if (cpd != null) {
      if (cpd <= 10) level = 0;
      else if (cpd <= 20) level = 1;
      else level = 2;
    }
    if (ttfc == TTFC.within5 || ttfc == TTFC.m6to30) {
      level = (level + 1).clamp(0, 2);
    }
    return ['Low', 'Moderate', 'High'][level];
  }

  List<String> starterQuests({
    required int readiness,
    required int confidence,
    required List<String> triggers,
  }) {
    final quests = <String>[
      'Log every craving for 3 days',
      'Use a breathing exercise 5× this week',
      'Replace after-meal cigarette 5×',
    ];
    if (readiness < 5) {
      quests.add('Do a 7-day “prepare to quit” micro-lessons');
    }
    if (confidence < 5) {
      quests.add('Set 3 “if-then” coping plans for top triggers');
    }
    if (triggers.contains('Stress/Anger')) {
      quests.add('Try 4-7-8 breathing daily for 7 days');
    }
    return quests;
  }

  List<Widget> personalizedTips({
    required String depLabel,
    required int readiness,
    required int confidence,
    required List<String> motivations,
    required List<String> triggers,
  }) {
    final tips = <String>[];

    switch (depLabel) {
      case 'Low':
        tips.add('Focus on behavior strategies and light reminders.');
        break;
      case 'Moderate':
        tips.add('Use daily breathing + buddy check-ins.');
        tips.add('Schedule notifications around usual trigger times.');
        break;
      case 'High':
        tips.add('Intensive urge timers and strong distractions.');
        tips.add('Consider professional/clinic support if available.');
        break;
    }

    if (readiness < 5) tips.add('Spend 1–2 weeks preparing: trigger diary & micro-goals.');
    if (confidence < 5) tips.add('Boost self-efficacy with small wins and “if-then” plans.');

    if (motivations.contains('Financial')) tips.add('Highlight money saved—set rewards at RM100 / RM500.');
    if (motivations.contains('Health')) tips.add('Show health milestones (e.g., breathing improves in weeks).');
    if (motivations.contains('Family')) tips.add('Use lock-screen affirmations tied to family.');

    if (triggers.contains('After meals')) tips.add('Walk 3 minutes + sugar-free gum after meals.');
    if (triggers.contains('Coffee/Tea')) tips.add('Swap first cup with water; keep hands busy.');
    if (triggers.contains('Stress/Anger')) tips.add('4-7-8 breathing or 2-minute body scan.');
    if (triggers.contains('Socializing')) tips.add('Prepare “no thanks, I’m quitting” scripts.');
    if (triggers.contains('Driving')) tips.add('Keep sunflower seeds/fidget; set audio goals.');
    if (triggers.contains('Boredom')) tips.add('90-sec mini-game or quick to-do micro-task.');

    return tips
        .map((t) => ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: Text(t),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    final prof = p.state.profile;
    final h = p.state.habits;
    final q = p.state.plan;

    final dep = dependenceLabel(h.cigarettesPerDay, h.ttfc);
    final quests = starterQuests(
      readiness: q.readiness,
      confidence: q.confidence,
      triggers: q.triggers,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Your Personalized Quit Plan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hi ${prof.name.isEmpty ? 'there' : prof.name}, here is your plan:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('Quit Date'),
              subtitle: Text(
                q.quitDate == null
                    ? 'Not set'
                    : '${q.quitDate!.day}/${q.quitDate!.month}/${q.quitDate!.year}',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.favorite_outline, color: Colors.red),
              title: const Text('Readiness & Confidence'),
              subtitle: Text('Readiness: ${q.readiness}/10 • Confidence: ${q.confidence}/10'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined, color: Colors.deepOrange),
              title: const Text('Dependence Level'),
              subtitle: Text(dep),
            ),
          ),
          if (h.dailyCost > 0) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.savings_outlined, color: Colors.green),
                title: const Text('Estimated Savings'),
                subtitle: Text(
                  'Daily: RM ${h.dailyCost.toStringAsFixed(2)} • '
                  'Monthly: RM ${h.monthlyCost.toStringAsFixed(2)} • '
                  'Annual: RM ${h.annualCost.toStringAsFixed(2)}',
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (q.motivations.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.bolt_outlined, color: Colors.blue),
                title: const Text('Your Motivations'),
                subtitle: Text(q.motivations.join(', ')),
              ),
            ),
          if (q.triggers.isNotEmpty) const SizedBox(height: 8),
          if (q.triggers.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber_outlined, color: Colors.amber),
                title: const Text('Top Triggers'),
                subtitle: Text(q.triggers.join(', ')),
              ),
            ),
          if (q.supports.isNotEmpty) const SizedBox(height: 8),
          if (q.supports.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent_outlined, color: Colors.purple),
                title: const Text('Preferred Support'),
                subtitle: Text(q.supports.join(', ')),
              ),
            ),

          const SizedBox(height: 16),

          Text('Recommended Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: personalizedTips(
                depLabel: dep,
                readiness: q.readiness,
                confidence: q.confidence,
                motivations: q.motivations,
                triggers: q.triggers,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text('Starter Quests (next 7 days)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: quests
                  .map((t) => ListTile(
                        leading: const Icon(Icons.task_alt_outlined, color: Colors.teal),
                        title: Text(t),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    final plan = context.read<OnboardingProvider>().state.plan;

    final chosen = plan.quitDate ?? DateTime.now();
    final midnight = DateTime(chosen.year, chosen.month, chosen.day);
    await prefs.setInt('startDate', midnight.millisecondsSinceEpoch);

    if (!context.mounted) return;

    // Always go to Dashboard even if you came from Welcome/Preview
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
  },
  icon: const Icon(Icons.check),
  label: const Text('Finish & Go to Dashboard'),
),
        ],
      ),
    );
  }
}
