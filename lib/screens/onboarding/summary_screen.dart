import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/onboarding_provider.dart';
import '../../models/onboarding_models.dart';
import '../../services/firebase_achievement_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
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
        tips.add('Use daily breathing + buddy check-ins.');
        tips.add('Schedule notifications around usual trigger times.');
        tips.add('Prepare “no thanks, I’m quitting” scripts. *');
        tips.add('Use distraction tools like a walk or mini-games.');
        tips.add('Track smoke-free days with fun milestones.');
        break;
      case 'Moderate':
        tips.add('Combine breathing with a craving tracker.');
        tips.add('Start NRT (patch or gum) as prescribed.');
        tips.add('Practice “urge surfing” when cravings hit.');
        tips.add('Weekly reflection journal: wins & struggles.');
        tips.add('Set “trigger alerts” (post-meal, social outings).');
        break;
      case 'High':
        tips.add('Use combo NRT (patch + gum/lozenge) daily.');
        tips.add('Talk to your quit coach or counselor 2x/week.');
        tips.add('Schedule medication reminders & log side effects.');
        tips.add('Emergency “urge SOS” button with coping tools.');
        tips.add('Roleplay tough situations using refusal scripts.');
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.savings_outlined, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Estimated Savings When You Quit',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (h.dailyCigCost > 0)
                      _SavingsRow(
                        label: 'Cigarettes',
                        daily: h.dailyCigCost,
                        monthly: h.dailyCigCost * 30,
                        annual: h.dailyCigCost * 365,
                      ),
                    if (h.dailyCigCost > 0 && h.dailyVapeCost > 0) const SizedBox(height: 8),
                    if (h.dailyVapeCost > 0)
                      _SavingsRow(
                        label: 'Vape',
                        daily: h.dailyVapeCost,
                        monthly: h.dailyVapeCost * 30,
                        annual: h.dailyVapeCost * 365,
                      ),
                    if ((h.dailyCigCost > 0 && h.dailyVapeCost > 0) || h.dailyCost > 0) ...[
                      const Divider(height: 24),
                      _SavingsRow(
                        label: 'Total',
                        daily: h.dailyCost,
                        monthly: h.monthlyCost,
                        annual: h.annualCost,
                        isTotal: true,
                      ),
                    ],
                  ],
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
    final provider = context.read<OnboardingProvider>();
    final prof = provider.state.profile;
    final habits = provider.state.habits;
    final plan = provider.state.plan;

    final chosen = plan.quitDate ?? DateTime.now();
    final midnight = DateTime(chosen.year, chosen.month, chosen.day);

    // Show loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Save to local storage (offline-first)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('startDate', midnight.millisecondsSinceEpoch);

      // Save to Firebase (cloud sync)
      final authService = AuthService();
      final user = authService.currentUser;

      if (user != null) {
        final firestoreService = FirestoreService();

        // Build complete onboarding data map
        final Map<String, dynamic> data = {
          'email': user.email,
          'name': prof.name,
          'onboardingComplete': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          // Profile data
          'age': prof.age,
          'gender': prof.gender?.name,
          'race': prof.race,
          'education': prof.education?.name,
          'occupation': prof.occupation,
          // Smoking habits data
          'tobaccoProducts': habits.products.map((p) => p.name).toList(),
          'cigarettesPerDay': habits.cigarettesPerDay,
          'vapeSessionsPerDay': habits.vapeSessionsPerDay,
          'ttfc': habits.ttfc?.name,
          // Pricing data for accurate cost calculations
          'pricePerPack': habits.pricePerPack,
          'vapeSpendPerDay': habits.vapeSpendPerDay,
          'dailyCost': habits.dailyCost,
          'monthlyCost': habits.monthlyCost,
          'annualCost': habits.annualCost,
          // Quit plan data
          'quitDate': midnight.toIso8601String(),
          'readiness': plan.readiness,
          'confidence': plan.confidence,
          'motivations': plan.motivations,
          'triggers': plan.triggers,
          'supports': plan.supports,
        };

        // Remove null values
        data.removeWhere((key, value) => value == null);

        // Save all data to Firestore
        await firestoreService.saveUserProfile(
          userId: user.uid,
          data: data,
        );

        // Also save quit date to achievement service
        final firebaseAchievementService = FirebaseAchievementService();
        await firebaseAchievementService.saveQuitDate(
          userId: user.uid,
          quitDate: midnight,
        );

        debugPrint('Complete onboarding data saved to Firebase');
      }

      // Close loading dialog
      if (!context.mounted) return;
      Navigator.of(context).pop();

      // Navigate to Dashboard
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    } catch (e) {
      // Close loading dialog
      if (!context.mounted) return;
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving onboarding data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  icon: const Icon(Icons.check),
  label: const Text('Finish & Go to Dashboard'),
),
        ],
      ),
    );
  }
}

// Savings Row Widget for displaying cost breakdown
class _SavingsRow extends StatelessWidget {
  final String label;
  final double daily;
  final double monthly;
  final double annual;
  final bool isTotal;

  const _SavingsRow({
    required this.label,
    required this.daily,
    required this.monthly,
    required this.annual,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.green.shade700 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CostLabel('Daily:', daily, isTotal),
            _CostLabel('Monthly:', monthly, isTotal),
            _CostLabel('Annual:', annual, isTotal),
          ],
        ),
      ],
    );
  }
}

class _CostLabel extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _CostLabel(this.label, this.amount, this.isTotal);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 14 : 13,
            color: isTotal ? Colors.green.shade800 : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
