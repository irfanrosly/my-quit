import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../state/gamification_provider.dart';
import '../state/onboarding_provider.dart';
import '../screens/badges_screen.dart';
import '../screens/achievement_testing_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with TickerProviderStateMixin {
  int days = 0;
  final int goal = 30;
  late AnimationController _headerController;
  late AnimationController _progressController;
  late AnimationController _cardsController;
  bool _isCravingManaged = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _loadDays();
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _progressController.forward();
        _cardsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _progressController.dispose();
    _cardsController.dispose();
    super.dispose();
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

    final g = context.watch<GamificationProvider>();
    final o = context.watch<OnboardingProvider>();
    final double moneySaved = (o.state.habits.dailyCost) * days;
    g.sync(days: days, saved: moneySaved);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Progress"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Progress',
            onPressed: () {
              HapticFeedback.mediumImpact();
              _shareProgress(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header / Streak with animation
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2FBF71), Color(0xFF7BE495)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2FBF71).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smoke-Free Streak',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$days',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            Text(
                              days == 1 ? 'day' : 'days',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              '${g.totalPoints}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'pts',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Health Progress with animation
          FadeTransition(
            opacity: _progressController,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
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
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.health_and_safety, color: Colors.blue.shade700, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Health Progress',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Goal: $goal days',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: progress * _progressController.value,
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$days days', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text('$goal days', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Savings & Points grid
          FadeTransition(
            opacity: _cardsController,
            child: Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.savings_outlined,
                    label: 'Money Saved',
                    value: 'RM ${moneySaved.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    icon: Icons.whatshot,
                    label: 'Cravings',
                    value: '${g.cravingsManaged}',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick action - Managed craving
          FadeTransition(
            opacity: _cardsController,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isCravingManaged
                      ? [Colors.green.shade400, Colors.green.shade500]
                      : [Colors.purple.shade400, Colors.purple.shade500],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isCravingManaged ? Colors.green : Colors.purple).withOpacity(0.3),
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
                    child: Icon(
                      _isCravingManaged ? Icons.check_circle : Icons.self_improvement_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCravingManaged ? 'Great job!' : 'Feeling a craving?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isCravingManaged
                              ? 'You managed it successfully!'
                              : 'Tap to log your victory',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isCravingManaged)
                    FilledButton(
                      onPressed: () async {
                        HapticFeedback.heavyImpact();
                        await context.read<GamificationProvider>().addCravingManaged();
                        setState(() => _isCravingManaged = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _isCravingManaged = false);
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple.shade700,
                      ),
                      child: const Text('I Did It!'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Achievements
          FadeTransition(
            opacity: _cardsController,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade100, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Achievements',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BadgesScreen()),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (g.badges.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No badges yet — keep going!',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: g.badges.take(4).map((b) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events, size: 18, color: Colors.amber.shade700),
                              const SizedBox(width: 6),
                              Text(
                                b,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Milestones header
          Row(
            children: [
              Icon(Icons.flag, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Health Milestones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Congratulations for every small step!',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Milestones
          FadeTransition(
            opacity: _cardsController,
            child: Column(
              children: [
                _milestoneTile(
                  '24 Hours',
                  days >= 1,
                  'Body starts clearing out leftover dirt and chemicals from smoking in the blood and lungs.',
                ),
                const SizedBox(height: 12),
                _milestoneTile(
                  '3 Days',
                  days >= 3,
                  'Lungs help with easier breathing, and without nicotine, energy levels begin to rise.',
                ),
                const SizedBox(height: 12),
                _milestoneTile(
                  '1 Week',
                  days >= 7,
                  'Lung function and blood circulation are improving.',
                ),
                const SizedBox(height: 12),
                _milestoneTile(
                  '1 Month',
                  days >= 30,
                  'Lungs begin to heal and breathing becomes easier. Appetite improves.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Dashboard'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Testing buttons - always visible
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AchievementTestingScreen()),
                    );
                  },
                  icon: const Icon(Icons.science),
                  label: const Text('Test Achievements'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange.shade300, width: 2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await context.read<GamificationProvider>().resetAll();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Progress reset (testing)')),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _milestoneTile(String label, bool unlocked, String note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF2FBF71).withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? const Color(0xFF2FBF71).withOpacity(0.3) : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: unlocked ? const Color(0xFF2FBF71) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? Icons.check : Icons.lock_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: unlocked ? const Color(0xFF2FBF71) : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? const Color(0xFF2FBF71).withOpacity(0.2)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        unlocked ? 'Unlocked' : 'Locked',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: unlocked ? const Color(0xFF2FBF71) : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
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

// Stat Box Widget
class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ====== Extension on _ProgressScreenState for share helpers ======
extension on _ProgressScreenState {
  Future<void> _shareProgress(BuildContext context) async {
    final g = context.read<GamificationProvider>();

    final msg = _buildShareMessage(
      days: days,
      moneySaved: g.moneySaved,
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
