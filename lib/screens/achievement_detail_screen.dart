// lib/screens/achievement_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/achievement_tracker_service.dart';
import '../state/gamification_provider.dart';

/// Screen showing all achievements with progress tracking
class AchievementDetailScreen extends StatefulWidget {
  const AchievementDetailScreen({super.key});

  @override
  State<AchievementDetailScreen> createState() => _AchievementDetailScreenState();
}

class _AchievementDetailScreenState extends State<AchievementDetailScreen> {
  List<AchievementMilestoneStatus> _statuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    final statuses = await context.read<GamificationProvider>().getAchievementStatuses();
    if (mounted) {
      setState(() {
        _statuses = statuses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadAchievements();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
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
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_statuses.where((s) => s.isUnlocked).length} / ${_statuses.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Achievements Unlocked',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Achievement List
                ..._statuses.map((status) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _AchievementCard(status: status),
                    )),
              ],
            ),
    );
  }
}

/// Individual achievement card with progress
class _AchievementCard extends StatelessWidget {
  final AchievementMilestoneStatus status;

  const _AchievementCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final milestone = status.milestone;
    final isUnlocked = status.isUnlocked;
    final progress = status.progressPercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? Colors.green.shade200 : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUnlocked
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnlocked ? Icons.check_circle : Icons.lock_outline,
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
                      milestone.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.green.shade900 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      milestone.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnlocked ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Unlocked',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 16),
            // Progress bar
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(5),
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
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${status.hoursRemaining}h remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
