import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/onboarding_provider.dart';
import '../models/onboarding_models.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _formatGender(Gender? gender) {
    if (gender == null) return 'Not set';
    return gender.name[0].toUpperCase() + gender.name.substring(1);
  }

  String _formatEducation(Education? education) {
    if (education == null) return 'Not set';
    return education.name[0].toUpperCase() + education.name.substring(1);
  }

  String _formatTobaccoProducts(List<TobaccoType> products) {
    if (products.isEmpty) return 'Not set';
    return products.map((p) => p.name[0].toUpperCase() + p.name.substring(1)).join(', ');
  }

  String _formatTTFC(TTFC? ttfc) {
    if (ttfc == null) return 'Not set';
    switch (ttfc) {
      case TTFC.within5:
        return 'Within 5 minutes';
      case TTFC.m6to30:
        return '6-30 minutes';
      case TTFC.m31to60:
        return '31-60 minutes';
      case TTFC.over60:
        return 'Over 60 minutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = context.watch<OnboardingProvider>();
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  o.state.profile.name.isNotEmpty ? o.state.profile.name : 'User',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'No email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Personal Information Section
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            icon: Icons.badge_outlined,
            title: 'Name',
            value: o.state.profile.name.isNotEmpty ? o.state.profile.name : 'Not set',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.cake_outlined,
            title: 'Age',
            value: o.state.profile.age?.toString() ?? 'Not set',
            color: Colors.purple,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.wc_outlined,
            title: 'Gender',
            value: _formatGender(o.state.profile.gender),
            color: Colors.pink,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.flag_outlined,
            title: 'Race',
            value: o.state.profile.race ?? 'Not set',
            color: Colors.orange,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.school_outlined,
            title: 'Education',
            value: _formatEducation(o.state.profile.education),
            color: Colors.green,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.work_outline,
            title: 'Occupation',
            value: o.state.profile.occupation ?? 'Not set',
            color: Colors.teal,
          ),

          const SizedBox(height: 24),

          // Smoking Habits Section
          Text(
            'Smoking Habits',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            icon: Icons.smoking_rooms,
            title: 'Tobacco Products',
            value: _formatTobaccoProducts(o.state.habits.products),
            color: Colors.red,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.calendar_today_outlined,
            title: 'Years Smoked',
            value: o.state.habits.yearsSmoked?.toString() ?? 'Not set',
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.numbers,
            title: 'Cigarettes Per Day',
            value: o.state.habits.cigarettesPerDay?.toString() ?? 'Not set',
            color: Colors.red,
          ),
          const SizedBox(height: 8),

          if (o.state.habits.vapeSessionsPerDay != null)
            _InfoCard(
              icon: Icons.cloud_outlined,
              title: 'Vape Sessions Per Day',
              value: o.state.habits.vapeSessionsPerDay.toString(),
              color: Colors.cyan,
            ),
          if (o.state.habits.vapeSessionsPerDay != null) const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.timer_outlined,
            title: 'Time to First Cigarette',
            value: _formatTTFC(o.state.habits.ttfc),
            color: Colors.amber,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.attach_money,
            title: 'Daily Cost',
            value: 'RM ${o.state.habits.dailyCost.toStringAsFixed(2)}',
            color: Colors.green,
          ),

          const SizedBox(height: 24),

          // Quit Plan Section
          Text(
            'Quit Plan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            icon: Icons.event,
            title: 'Quit Date',
            value: o.state.plan.quitDate != null
                ? '${o.state.plan.quitDate!.day}/${o.state.plan.quitDate!.month}/${o.state.plan.quitDate!.year}'
                : 'Not set',
            color: Colors.indigo,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.favorite_outline,
            title: 'Readiness Level',
            value: '${o.state.plan.readiness}/10',
            color: Colors.pink,
          ),
          const SizedBox(height: 8),

          _InfoCard(
            icon: Icons.emoji_events_outlined,
            title: 'Confidence Level',
            value: '${o.state.plan.confidence}/10',
            color: Colors.amber,
          ),
          const SizedBox(height: 8),

          if (o.state.plan.motivations.isNotEmpty)
            _InfoCard(
              icon: Icons.bolt_outlined,
              title: 'Motivations',
              value: o.state.plan.motivations.join(', '),
              color: Colors.blue,
            ),
          if (o.state.plan.motivations.isNotEmpty) const SizedBox(height: 8),

          if (o.state.plan.triggers.isNotEmpty)
            _InfoCard(
              icon: Icons.warning_amber_outlined,
              title: 'Triggers',
              value: o.state.plan.triggers.join(', '),
              color: Colors.orange,
            ),
          if (o.state.plan.triggers.isNotEmpty) const SizedBox(height: 8),

          if (o.state.plan.supports.isNotEmpty)
            _InfoCard(
              icon: Icons.support_agent_outlined,
              title: 'Support Preferences',
              value: o.state.plan.supports.join(', '),
              color: Colors.purple,
            ),

          const SizedBox(height: 32),

          // Edit Profile Button
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile editing coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 12),

          // Logout Button
          OutlinedButton.icon(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Reusable Info Card Widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
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
