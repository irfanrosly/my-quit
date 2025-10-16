import '../chatbot/myquitmate_chatbot.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Services
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/achievement_tracker_service.dart';

// Providers
import '../state/gamification_provider.dart';
import '../state/onboarding_provider.dart';

// Screens
import 'progress_screen.dart';
import 'craving_toolkit_screen.dart';
import 'badges_screen.dart';
import 'achievement_detail_screen.dart';
import 'achievement_testing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _days = 0;
  int _relapseCount = 0;
  late AnimationController _headerController;
  late AnimationController _statsController;
  late List<AnimationController> _actionControllers;
  AchievementMilestone? _nextMilestone;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _actionControllers = List.generate(
      4,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    _loadDays();
    _loadRelapseCount();
    _loadNextMilestone();
    _headerController.forward();
    _statsController.forward();

    // Staggered animation for action tiles
    Future.delayed(const Duration(milliseconds: 300), () {
      for (int i = 0; i < _actionControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (mounted) _actionControllers[i].forward();
        });
      }
    });

    // Start achievement tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().startActiveTracking();
    });
  }

  Future<void> _loadNextMilestone() async {
    final milestone = await context.read<GamificationProvider>().getNextMilestone();
    if (mounted) {
      setState(() => _nextMilestone = milestone);
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    for (var controller in _actionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDays() async {
    final p = await SharedPreferences.getInstance();
    final start = p.getInt('startDate') ?? DateTime.now().millisecondsSinceEpoch;
    final sd = DateTime.fromMillisecondsSinceEpoch(start);
    final d = DateTime.now().difference(DateTime(sd.year, sd.month, sd.day)).inDays;
    if (!mounted) return;
    setState(() => _days = d < 0 ? 0 : d);
  }

  Future<void> _loadRelapseCount() async {
    final authService = AuthService();
    final user = authService.currentUser;
    int count = 0;

    if (user != null) {
      try {
        // Always load from Firestore first (user-specific data)
        final firestoreService = FirestoreService();
        final data = await firestoreService.getUserProfile(user.uid);
        if (data != null && data['relapseCount'] != null) {
          count = data['relapseCount'] as int;
          // Update local cache for this user
          final p = await SharedPreferences.getInstance();
          await p.setInt('relapseCount_${user.uid}', count);
        }
      } catch (e) {
        debugPrint('Error loading relapse count from Firestore: $e');
        // Fallback to local cache if Firestore fails
        final p = await SharedPreferences.getInstance();
        count = p.getInt('relapseCount_${user.uid}') ?? 0;
      }
    }

    if (!mounted) return;
    setState(() => _relapseCount = count);
  }

  Future<void> _incrementRelapseCount() async {
    final amountController = TextEditingController(text: '1');

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track Slip-Up'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Did you smoke? It\'s okay, we\'ll track it and keep moving forward.'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'How many cigarettes?',
                hintText: 'Enter amount',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(amountController.text) ?? 1;
              Navigator.pop(context, {'confirmed': true, 'amount': amount});
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Yes, I smoked'),
          ),
        ],
      ),
    );

    amountController.dispose();

    if (result != null && result['confirmed'] == true) {
      final amount = result['amount'] as int;
      final authService = AuthService();
      final user = authService.currentUser;

      if (user == null) return;

      final newCount = _relapseCount + 1;

      // Get today's date as key
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Get existing daily amounts map from Firestore
      Map<String, dynamic> dailyAmounts = {};
      try {
        final firestoreService = FirestoreService();
        final data = await firestoreService.getUserProfile(user.uid);
        if (data != null && data['dailyRelapseAmounts'] != null) {
          dailyAmounts = Map<String, dynamic>.from(data['dailyRelapseAmounts']);
        }
      } catch (e) {
        debugPrint('Error loading daily amounts: $e');
      }

      // Add today's amount to existing amount (if any)
      final currentAmount = dailyAmounts[dateKey] ?? 0;
      dailyAmounts[dateKey] = currentAmount + amount;

      // Save to Firestore (primary storage)
      try {
        final firestoreService = FirestoreService();
        await firestoreService.saveUserProfile(
          userId: user.uid,
          data: {
            'relapseCount': newCount,
            'lastRelapseDate': today.toIso8601String(),
            'dailyRelapseAmounts': dailyAmounts,
          },
        );

        // Update local cache for this user
        final p = await SharedPreferences.getInstance();
        await p.setInt('relapseCount_${user.uid}', newCount);
        await p.setString('dailyRelapseAmounts_${user.uid}', json.encode(dailyAmounts));
      } catch (e) {
        debugPrint('Error saving relapse to Firestore: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _relapseCount = newCount);

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tracked $amount cigarette${amount > 1 ? 's' : ''}. Remember, progress isn\'t perfect!'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GamificationProvider>();
    final o = context.watch<OnboardingProvider>();

    final daysToShow = (g.smokeFreeDays > 0) ? g.smokeFreeDays : _days;
    final moneySaved = o.state.habits.dailyCost * daysToShow;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MYQuitMate'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final authService = AuthService();
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await _loadDays();
          await context.read<GamificationProvider>().checkAchievementsNow();
          context.read<GamificationProvider>().sync(days: daysToShow, saved: moneySaved);
          await _loadNextMilestone();
          await Future.delayed(const Duration(milliseconds: 500));
          HapticFeedback.lightImpact();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome header with animation
            FadeTransition(
              opacity: _headerController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _headerController,
                  curve: Curves.easeOutCubic,
                )),
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.waving_hand,
                            color: Colors.orange.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pushNamed(context, '/profile');
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: o.state.profile.name.isNotEmpty
                                    ? Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Welcome Back, ',
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            TextSpan(
                                              text: '${o.state.profile.name}',
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue.shade700,
                                                  ),
                                            ),
                                            TextSpan(
                                              text: '!',
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Text(
                                        'Welcome Back!',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'re doing great on your journey',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats cards with animation
            FadeTransition(
              opacity: _statsController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.5, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _statsController,
                  curve: Curves.easeOutCubic,
                )),
                child: _StatCard(
                  title: 'Days Smoke-Free',
                  value: '$daysToShow',
                  subtitle: daysToShow > 0 ? 'Keep it up!' : 'Let\'s get started',
                  icon: Icons.calendar_month,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _statsController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.5, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _statsController,
                  curve: Curves.easeOutCubic,
                )),
                child: _StatCard(
                  title: 'Money Saved',
                  value: 'RM ${moneySaved.toStringAsFixed(2)}',
                  subtitle: moneySaved > 0 ? 'Nice progress' : 'Start your quit plan',
                  icon: Icons.savings_outlined,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cigarettes Not Smoked card
            FadeTransition(
              opacity: _statsController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.5, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _statsController,
                  curve: Curves.easeOutCubic,
                )),
                child: _StatCard(
                  title: 'Cigarettes Not Smoked',
                  value: '${(o.state.habits.cigarettesPerDay ?? 0) * daysToShow}',
                  subtitle: daysToShow > 0 ? 'Your lungs thank you!' : 'Start your journey',
                  icon: Icons.smoke_free,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Points card
            FadeTransition(
              opacity: _statsController,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade300, Colors.amber.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Points',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Keep earning rewards!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${g.totalPoints}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Relapse Tracking Section
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Track Slip-Up Button Card
                  Expanded(
                    child: GestureDetector(
                      onTap: _incrementRelapseCount,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.smoking_rooms, color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'I Smoked',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to track',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Slip-Up Counter Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.numbers, color: Colors.orange.shade700, size: 28),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_relapseCount',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _relapseCount == 1 ? 'Slip-up' : 'Slip-ups',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Next Milestone Tracker
            if (_nextMilestone != null)
              FadeTransition(
                opacity: _statsController,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AchievementDetailScreen()),
                    );
                  },
                  child: _NextMilestoneCard(
                    milestone: _nextMilestone!,
                    currentDays: daysToShow,
                  ),
                ),
              ),
            if (_nextMilestone != null) const SizedBox(height: 24),

            Row(
              children: [
                Icon(Icons.touch_app, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action tiles grid with staggered animation
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildAnimatedAction(
                  0,
                  Icons.insights,
                  Colors.blue,
                  'Progress',
                  () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProgressScreen()),
                    );
                  },
                ),
                _buildAnimatedAction(
                  1,
                  Icons.health_and_safety_outlined,
                  Colors.green,
                  'Craving Toolkit',
                  () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CravingToolkitScreen()),
                    );
                  },
                ),
                _buildAnimatedAction(
                  2,
                  Icons.emoji_events,
                  Colors.purple,
                  'Badges',
                  () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BadgesScreen()),
                    );
                  },
                ),
                _buildAnimatedAction(
                  3,
                  Icons.science,
                  Colors.orange,
                  'Test Tool',
                  () async {
                    HapticFeedback.lightImpact();
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AchievementTestingScreen()),
                    );
                    // Refresh data when returning from test tool
                    if (mounted) {
                      await _loadDays();
                      final g = context.read<GamificationProvider>();
                      final o = context.read<OnboardingProvider>();
                      final updatedDays = (g.smokeFreeDays > 0) ? g.smokeFreeDays : _days;
                      final updatedMoneySaved = o.state.habits.dailyCost * updatedDays;
                      await g.checkAchievementsNow();
                      g.sync(days: updatedDays, saved: updatedMoneySaved);
                      await _loadNextMilestone();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'chat_fab',
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyQuitMateChatBot(
                ctx: ChatContext(
                  daysSmokeFree: daysToShow,
                  locale: 'ms',
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_rounded),
        label: const Text('Chat'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAnimatedAction(int index, IconData icon, Color color, String label, VoidCallback onTap) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _actionControllers[index],
          curve: Curves.elasticOut,
        ),
      ),
      child: _ActionTile(
        icon: icon,
        label: label,
        color: color,
        onTap: onTap,
      ),
    );
  }
}

// Reusable Stat Card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

// Reusable Action Tile (ikon besar + label) untuk grid
class _ActionTile extends StatefulWidget {
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
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.color.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isPressed ? 0.2 : 0.15),
              blurRadius: _isPressed ? 8 : 12,
              offset: Offset(0, _isPressed ? 2 : 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(0.8),
                    widget.color,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Next Milestone Card widget
class _NextMilestoneCard extends StatelessWidget {
  final AchievementMilestone milestone;
  final int currentDays;

  const _NextMilestoneCard({
    required this.milestone,
    required this.currentDays,
  });

  @override
  Widget build(BuildContext context) {
    final currentHours = currentDays * 24;
    final progress = (currentHours / milestone.requiredHours).clamp(0.0, 1.0);
    final hoursRemaining = milestone.requiredHours - currentHours;
    final daysRemaining = (hoursRemaining / 24).ceil();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade400,
            Colors.deepPurple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Achievement',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      milestone.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${daysRemaining}d left',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% complete',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
              Text(
                '${milestone.requiredDays} days goal',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
