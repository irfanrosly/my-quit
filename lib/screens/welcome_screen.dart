import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/onboarding_provider.dart';
import '../models/onboarding_models.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String appName = 'MYQuitMate';
  static const String tagline = 'Your pocket buddy to quit smoking';

  void _previewSummary(BuildContext context) {
    final prov = context.read<OnboardingProvider>();
    final s = prov.state;

    // --- Seed minimal, SAFE demo data ---
    // (Don’t assume specific enum cases — pick first if available)
    final Gender? demoGender =
        Gender.values.isNotEmpty ? Gender.values.first : null;
    final Education? demoEducation =
        Education.values.isNotEmpty ? Education.values.first : null;

    s.profile
      ..name = 'Guest'
      ..age = 30
      ..gender = demoGender
      ..race = '—'
      ..education = demoEducation
      ..occupation = '—';

    // Set products on the **collection**, not the parent object
    s.habits.products
      ..clear()
      ..add(TobaccoType.cigarette);
    s.habits
      ..cigarettesPerDay = 10
      ..vapeSessionsPerDay = 0
      ..ttfc = TTFC.m31to60; // adjust if your enum differs

    // Plan lists: operate on the list fields themselves
    s.plan
      ..quitDate = DateTime.now()
      ..readiness = 7
      ..confidence = 7;
    s.plan.motivations
      ..clear()
      ..addAll(['Health', 'Financial']);
    s.plan.triggers
      ..clear()
      ..addAll(['After meals', 'Stress/Anger']);
    s.plan.supports
      ..clear()
      ..addAll(['Buddy check-ins']);

    // Persist & notify
    prov
      ..notifyProfileUpdated()
      ..notifyHabitsUpdated()
      ..notifyPlanUpdated();

    // Go to Summary
    Navigator.pushNamed(context, '/onboarding/summary');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2FBF71), Color(0xFF7BE495)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Image.asset(
                    'assets/MYQuitMate.png',
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Start plan
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E824C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/onboarding/profile'),
                      icon: const Icon(Icons.flag),
                      label: const Text(
                        'Start Quit Plan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Go to dashboard
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Go to Dashboard'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Preview summary with demo data
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => _previewSummary(context),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Preview Plan Summary'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
