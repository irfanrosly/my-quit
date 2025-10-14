// lib/screens/achievement_testing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/firebase_achievement_service.dart';
import '../state/gamification_provider.dart';

/// Testing screen to manipulate quit date for achievement testing
/// This allows you to simulate different durations (24h, 3 days, 1 week, etc.)
class AchievementTestingScreen extends StatefulWidget {
  const AchievementTestingScreen({super.key});

  @override
  State<AchievementTestingScreen> createState() => _AchievementTestingScreenState();
}

class _AchievementTestingScreenState extends State<AchievementTestingScreen> {
  DateTime? _currentQuitDate;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentQuitDate();
  }

  Future<void> _loadCurrentQuitDate() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final startDateMs = prefs.getInt('startDate');

      if (startDateMs != null) {
        setState(() {
          _currentQuitDate = DateTime.fromMillisecondsSinceEpoch(startDateMs);
        });
      }
    } catch (e) {
      debugPrint('Error loading quit date: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setQuitDate(DateTime quitDate) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final midnight = DateTime(quitDate.year, quitDate.month, quitDate.day);

      // Save to local storage
      await prefs.setInt('startDate', midnight.millisecondsSinceEpoch);

      // Save to Firebase if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firebaseService = FirebaseAchievementService();
        await firebaseService.saveQuitDate(
          userId: user.uid,
          quitDate: midnight,
        );
      }

      // Trigger achievement check
      await context.read<GamificationProvider>().checkAchievementsNow();

      setState(() {
        _currentQuitDate = midnight;
        _statusMessage = 'Quit date updated successfully!';
      });

      HapticFeedback.mediumImpact();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quit date set to ${_formatDate(midnight)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setDaysAgo(int days) async {
    final quitDate = DateTime.now().subtract(Duration(days: days));
    await _setQuitDate(quitDate);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDurationText() {
    if (_currentQuitDate == null) return 'No quit date set';

    final now = DateTime.now();
    final difference = now.difference(_currentQuitDate!);

    final days = difference.inDays;
    final hours = difference.inHours;
    final minutes = difference.inMinutes;

    if (days > 0) {
      return '$days days, ${hours % 24} hours ago';
    } else if (hours > 0) {
      return '$hours hours, ${minutes % 60} minutes ago';
    } else {
      return '$minutes minutes ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement Testing'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Warning Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Testing Tool',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This screen allows you to manipulate the quit date for testing achievements.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Current Status Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'Current Quit Date',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_currentQuitDate != null) ...[
                          Text(
                            _formatDate(_currentQuitDate!),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDurationText(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'No quit date set',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Test Buttons
                const Text(
                  'Quick Test Milestones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a button to set quit date to that duration ago',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),

                // Achievement milestones
                _buildTestButton(
                  icon: Icons.looks_one,
                  label: '24 Hours Ago',
                  description: 'Test "Day 1: Fresh Start" badge',
                  color: Colors.green,
                  onPressed: () => _setDaysAgo(1),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  icon: Icons.filter_3,
                  label: '3 Days Ago (72 Hours)',
                  description: 'Test "72 Hours: Detox Hero" badge',
                  color: Colors.blue,
                  onPressed: () => _setDaysAgo(3),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  icon: Icons.calendar_view_day,
                  label: '1 Week Ago (7 Days)',
                  description: 'Test "1 Week Streak" badge',
                  color: Colors.purple,
                  onPressed: () => _setDaysAgo(7),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  icon: Icons.calendar_view_week,
                  label: '2 Weeks Ago (14 Days)',
                  description: 'Test "2 Weeks Strong" badge',
                  color: Colors.orange,
                  onPressed: () => _setDaysAgo(14),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  icon: Icons.calendar_month,
                  label: '1 Month Ago (30 Days)',
                  description: 'Test "1 Month Milestone" badge',
                  color: Colors.teal,
                  onPressed: () => _setDaysAgo(30),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  icon: Icons.event,
                  label: '2 Months Ago (60 Days)',
                  description: 'Test "2 Months Momentum" badge',
                  color: Colors.indigo,
                  onPressed: () => _setDaysAgo(60),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  icon: Icons.emoji_events,
                  label: '3 Months Ago (90 Days)',
                  description: 'Test "3 Months Champion" badge',
                  color: Colors.pink,
                  onPressed: () => _setDaysAgo(90),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  icon: Icons.stars,
                  label: '6 Months Ago (180 Days)',
                  description: 'Test "6 Months Warrior" badge',
                  color: Colors.deepOrange,
                  onPressed: () => _setDaysAgo(180),
                ),
                const SizedBox(height: 12),
                _buildTestButton(
                  icon: Icons.workspace_premium,
                  label: '1 Year Ago (365 Days)',
                  description: 'Test "1 Year Legend" badge',
                  color: Colors.amber,
                  onPressed: () => _setDaysAgo(365),
                ),

                const SizedBox(height: 24),

                // Custom Date Picker
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _currentQuitDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      await _setQuitDate(picked);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: const Text('Pick Custom Date'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 16),

                // Reset Button
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset Quit Date'),
                        content: const Text(
                          'This will set your quit date to now and clear all achievements. Are you sure?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      await context.read<GamificationProvider>().resetAll();
                      await _setQuitDate(DateTime.now());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reset complete! Quit date set to now.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to Now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                if (_statusMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('Error') ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'How This Works',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Changes both local storage and Firebase\n'
                        '• Automatically checks for new achievements\n'
                        '• Triggers celebration notifications\n'
                        '• Pull down on dashboard to see changes\n'
                        '• Use "Reset to Now" to start fresh',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
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
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
