// lib/services/achievement_tracker_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_achievement_service.dart';

/// Service that actively monitors user's smoke-free progress
/// and triggers achievements/badges at specific milestones
///
/// HYBRID APPROACH:
/// - Primary: Firebase Firestore (source of truth, syncs across devices)
/// - Fallback: SharedPreferences (offline support, faster access)
/// - Saves to both simultaneously for reliability
class AchievementTrackerService {
  static final AchievementTrackerService _instance = AchievementTrackerService._internal();
  factory AchievementTrackerService() => _instance;
  AchievementTrackerService._internal();

  Timer? _timer;
  final List<AchievementMilestone> _milestones = [];
  Function(AchievementMilestone)? onAchievementUnlocked;

  // Track last checked achievement to avoid duplicates
  String? _lastUnlockedAchievement;

  // Firebase service
  final FirebaseAchievementService _firebaseService = FirebaseAchievementService();

  // Track if we've done initial sync
  bool _hasInitialSynced = false;

  /// Initialize the tracker with standard milestones
  void initialize() {
    _milestones.clear();
    _milestones.addAll([
      // Time-based milestones
      AchievementMilestone(
        id: 'day_1',
        title: '🌱 Day 1: Fresh Start',
        description: 'You\'ve been smoke-free for 24 hours!',
        requiredHours: 24,
        category: AchievementCategory.streak,
      ),
      AchievementMilestone(
        id: '72_hours',
        title: '⏳ 72 Hours: Detox Hero',
        description: 'You\'ve been smoke-free for 3 days!',
        requiredHours: 72,
        category: AchievementCategory.streak,
      ),
      AchievementMilestone(
        id: '1_week',
        title: '🗓️ 1 Week Streak',
        description: 'You\'ve been smoke-free for 1 week!',
        requiredHours: 168, // 7 days
        category: AchievementCategory.streak,
      ),
      AchievementMilestone(
        id: '2_weeks',
        title: '💪 2 Weeks Strong',
        description: 'You\'ve been smoke-free for 2 weeks!',
        requiredHours: 336, // 14 days
        category: AchievementCategory.streak,
      ),
      AchievementMilestone(
        id: '1_month',
        title: '🌟 1 Month Milestone',
        description: 'You\'ve been smoke-free for 30 days!',
        requiredHours: 720, // 30 days
        category: AchievementCategory.streak,
      ),
      AchievementMilestone(
        id: '2_months',
        title: '🔥 2 Months Momentum',
        description: 'You\'ve been smoke-free for 60 days!',
        requiredHours: 1440, // 60 days
        category: AchievementCategory.streak,
      ),
      AchievementMilestone(
        id: '3_months',
        title: '🏆 3 Months Champion',
        description: 'You\'ve been smoke-free for 90 days!',
        requiredHours: 2160, // 90 days
        category: AchievementCategory.streak,
      ),
      AchievementMilestone(
        id: '6_months',
        title: '🎯 6 Months Warrior',
        description: 'You\'ve been smoke-free for 6 months!',
        requiredHours: 4320, // 180 days
        category: AchievementCategory.streak,
      ),
      AchievementMilestone(
        id: '1_year',
        title: '👑 1 Year Smoke-Free Legend',
        description: 'You\'ve been smoke-free for 1 year!',
        requiredHours: 8760, // 365 days
        category: AchievementCategory.streak,
      ),
    ]);
  }

  /// Start monitoring the user's progress
  Future<void> startTracking() async {
    debugPrint('AchievementTracker: Starting tracking...');

    // Sync from Firebase on first start
    if (!_hasInitialSynced) {
      await _syncFromFirebase();
      _hasInitialSynced = true;
    }

    // Check immediately on start
    await _checkMilestones();

    // Then check every hour
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkMilestones();
    });
  }

  /// Sync achievements from Firebase to local storage
  Future<void> _syncFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('AchievementTracker: No user logged in, skipping Firebase sync');
        return;
      }

      debugPrint('AchievementTracker: Syncing from Firebase...');

      // Get achievements from Firebase
      final firebaseAchievements = await _firebaseService.getUnlockedAchievements(user.uid);

      if (firebaseAchievements.isEmpty) {
        debugPrint('AchievementTracker: No Firebase achievements, checking for local data to migrate');
        // No Firebase data, check if we have local data to push up
        final prefs = await SharedPreferences.getInstance();
        final localAchievements = prefs.getStringList('unlocked_achievements') ?? <String>[];

        if (localAchievements.isNotEmpty) {
          debugPrint('AchievementTracker: Migrating ${localAchievements.length} local achievements to Firebase');
          await _migrateLocalToFirebase(user.uid, localAchievements);
        }
        return;
      }

      // Update local storage with Firebase data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('unlocked_achievements', firebaseAchievements);
      debugPrint('AchievementTracker: Synced ${firebaseAchievements.length} achievements from Firebase');
    } catch (e) {
      debugPrint('AchievementTracker: Error syncing from Firebase: $e');
      // Continue with local data
    }
  }

  /// Migrate local achievements to Firebase
  Future<void> _migrateLocalToFirebase(String userId, List<String> localAchievementIds) async {
    try {
      // Build title and description maps
      final titles = <String, String>{};
      final descriptions = <String, String>{};

      for (final milestone in _milestones) {
        titles[milestone.id] = milestone.title;
        descriptions[milestone.id] = milestone.description;
      }

      await _firebaseService.syncLocalToFirebase(
        userId: userId,
        localAchievementIds: localAchievementIds,
        achievementTitles: titles,
        achievementDescriptions: descriptions,
      );
    } catch (e) {
      debugPrint('AchievementTracker: Error migrating to Firebase: $e');
    }
  }

  /// Stop the tracking timer
  void stopTracking() {
    debugPrint('AchievementTracker: Stopping tracking...');
    _timer?.cancel();
    _timer = null;
  }

  /// Check if any milestones have been reached
  /// HYBRID: Saves to both local storage AND Firebase
  Future<void> _checkMilestones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startDateMs = prefs.getInt('startDate');

      if (startDateMs == null) {
        debugPrint('AchievementTracker: No start date found');
        return;
      }

      final startDate = DateTime.fromMillisecondsSinceEpoch(startDateMs);
      final now = DateTime.now();
      final hoursSinceQuit = now.difference(startDate).inHours;

      debugPrint('AchievementTracker: Hours since quit: $hoursSinceQuit');

      // Get already unlocked achievements (local)
      final unlockedIds = prefs.getStringList('unlocked_achievements') ?? <String>[];

      // Get current user
      final user = FirebaseAuth.instance.currentUser;

      // Check each milestone
      for (final milestone in _milestones) {
        if (hoursSinceQuit >= milestone.requiredHours && !unlockedIds.contains(milestone.id)) {
          // New achievement unlocked!
          debugPrint('AchievementTracker: Unlocking ${milestone.title}');

          // Save to local storage (fast, offline-first)
          unlockedIds.add(milestone.id);
          await prefs.setStringList('unlocked_achievements', unlockedIds);

          // Save to Firebase (cloud backup, cross-device sync)
          if (user != null) {
            await _firebaseService.unlockAchievement(
              userId: user.uid,
              achievementId: milestone.id,
              title: milestone.title,
              description: milestone.description,
            );
            debugPrint('AchievementTracker: Synced ${milestone.id} to Firebase');
          } else {
            debugPrint('AchievementTracker: User not logged in, saved locally only');
          }

          // Track last unlocked to avoid duplicate notifications
          if (_lastUnlockedAchievement != milestone.id) {
            _lastUnlockedAchievement = milestone.id;
            onAchievementUnlocked?.call(milestone);
          }
        }
      }
    } catch (e) {
      debugPrint('AchievementTracker: Error checking milestones: $e');
    }
  }

  /// Get all milestones with their unlock status
  Future<List<AchievementMilestoneStatus>> getMilestonesStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startDateMs = prefs.getInt('startDate');
      final unlockedIds = prefs.getStringList('unlocked_achievements') ?? <String>[];

      if (startDateMs == null) {
        return _milestones.map((m) => AchievementMilestoneStatus(
          milestone: m,
          isUnlocked: false,
          progressHours: 0,
        )).toList();
      }

      final startDate = DateTime.fromMillisecondsSinceEpoch(startDateMs);
      final now = DateTime.now();
      final hoursSinceQuit = now.difference(startDate).inHours;

      return _milestones.map((m) => AchievementMilestoneStatus(
        milestone: m,
        isUnlocked: unlockedIds.contains(m.id),
        progressHours: hoursSinceQuit,
      )).toList();
    } catch (e) {
      debugPrint('AchievementTracker: Error getting status: $e');
      return [];
    }
  }

  /// Get next upcoming milestone
  Future<AchievementMilestone?> getNextMilestone() async {
    final statuses = await getMilestonesStatus();
    final locked = statuses.where((s) => !s.isUnlocked).toList()
      ..sort((a, b) => a.milestone.requiredHours.compareTo(b.milestone.requiredHours));

    return locked.isNotEmpty ? locked.first.milestone : null;
  }

  /// Manually trigger milestone check (useful for testing or refresh)
  Future<void> checkNow() async {
    await _checkMilestones();
  }

  void dispose() {
    stopTracking();
  }
}

/// Represents a specific achievement milestone
class AchievementMilestone {
  final String id;
  final String title;
  final String description;
  final int requiredHours;
  final AchievementCategory category;

  AchievementMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredHours,
    required this.category,
  });

  int get requiredDays => (requiredHours / 24).ceil();
}

/// Category of achievement
enum AchievementCategory {
  streak,
  savings,
  cravings,
  logging,
  health,
}

/// Status of a milestone including progress
class AchievementMilestoneStatus {
  final AchievementMilestone milestone;
  final bool isUnlocked;
  final int progressHours;

  AchievementMilestoneStatus({
    required this.milestone,
    required this.isUnlocked,
    required this.progressHours,
  });

  double get progressPercentage {
    if (isUnlocked) return 1.0;
    return (progressHours / milestone.requiredHours).clamp(0.0, 1.0);
  }

  int get hoursRemaining {
    if (isUnlocked) return 0;
    final remaining = milestone.requiredHours - progressHours;
    return remaining > 0 ? remaining : 0;
  }
}
