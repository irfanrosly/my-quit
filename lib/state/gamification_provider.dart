import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/achievement_tracker_service.dart';
import '../services/firebase_achievement_service.dart';

class GamificationProvider extends ChangeNotifier {
  // ---- Live state (di-sync dari UI) ----
  int smokeFreeDays = 0;    // dari ProgressScreen.sync()
  double moneySaved = 0.0;  // dari ProgressScreen.sync()

  // ---- Accumulated (persist) ----
  int cravingsManaged = 0;   // naik bila breathing/mini-task/mood log
  int extraPoints = 0;       // +5 breathing, +3 mini-task, +2 mood log
  final List<String> badges = [];

  // ---- Weekly snapshot (persist) ----
  int? _weekStartEpoch;             // Monday 00:00 of current week (ms)
  int _weekBaselineExtra = 0;
  double _weekBaselineMoney = 0.0;
  int _weekBaselineCravings = 0;

  // ---- Mood & Craving logs (persist) ----
  final List<MoodLog> _logs = []; // terbaru di depan
  List<MoodLog> get recent7 =>
      _logs.length <= 7 ? List.unmodifiable(_logs) : List.unmodifiable(_logs.take(7));
  MoodLog? todayLog() {
    final now = DateTime.now();
    for (final e in _logs) {
      if (e.date.year == now.year && e.date.month == now.month && e.date.day == now.day) {
        return e;
      }
    }
    return null;
  }

  // ---- Keys ----
  static const _kCravings        = 'g_cravings';
  static const _kExtraPoints     = 'g_extraPoints';
  static const _kBadges          = 'g_badges';
  static const _kWeekStart       = 'g_weekStart';
  static const _kWeekBaseExtra   = 'g_weekBaseExtra';
  static const _kWeekBaseMoney   = 'g_weekBaseMoney';
  static const _kWeekBaseCraving = 'g_weekBaseCrav';
  static const _kLogsJson        = 'g_mood_logs';

  // Hydration guard
  bool _hydrated = false;
  late final Future<void> _init = _loadFromStorage();

  // Achievement tracker
  final AchievementTrackerService _achievementTracker = AchievementTrackerService();
  final FirebaseAchievementService _firebaseAchievementService = FirebaseAchievementService();

  GamificationProvider() {
    _init; // kick off async load
    _initializeAchievementTracker();
  }

  /// Initialize the achievement tracker
  void _initializeAchievementTracker() {
    _achievementTracker.initialize();
  }

  /// Start active tracking of achievements
  Future<void> startActiveTracking() async {
    await _achievementTracker.startTracking();
  }

  /// Stop active tracking
  void stopActiveTracking() {
    _achievementTracker.stopTracking();
  }

  // ---------- Load & Save ----------
  Future<void> _loadFromStorage() async {
    final p = await SharedPreferences.getInstance();
    cravingsManaged        = p.getInt(_kCravings) ?? 0;
    extraPoints            = p.getInt(_kExtraPoints) ?? 0;
    _weekStartEpoch        = p.getInt(_kWeekStart);
    _weekBaselineExtra     = p.getInt(_kWeekBaseExtra) ?? 0;
    _weekBaselineMoney     = p.getDouble(_kWeekBaseMoney) ?? 0.0;
    _weekBaselineCravings  = p.getInt(_kWeekBaseCraving) ?? 0;

    final listBadges       = p.getStringList(_kBadges) ?? <String>[];
    badges
      ..clear()
      ..addAll(listBadges);

    // Logs
    final logsRaw = p.getStringList(_kLogsJson) ?? <String>[];
    _logs
      ..clear()
      ..addAll(logsRaw.map((s) => MoodLog.fromJson(jsonDecode(s) as Map<String, dynamic>)));

    _hydrated = true;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    if (!_hydrated) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kCravings, cravingsManaged);
    await p.setInt(_kExtraPoints, extraPoints);
    await p.setStringList(_kBadges, badges);
    await p.setStringList(
      _kLogsJson,
      _logs.map((e) => jsonEncode(e.toJson())).toList(),
    );
    if (_weekStartEpoch != null) {
      await p.setInt(_kWeekStart, _weekStartEpoch!);
      await p.setInt(_kWeekBaseExtra, _weekBaselineExtra);
      await p.setDouble(_kWeekBaseMoney, _weekBaselineMoney);
      await p.setInt(_kWeekBaseCraving, _weekBaselineCravings);
    }
  }

  // Paksa reload (untuk butang Refresh)
  Future<void> reloadFromStorage() async {
    _hydrated = false;
    await _loadFromStorage();
  }

  // ---------- Helpers ----------
  DateTime _mondayStart(DateTime d) {
    final daysToSubtract = d.weekday - DateTime.monday; // 0..6
    final base = DateTime(d.year, d.month, d.day).subtract(Duration(days: daysToSubtract));
    return DateTime(base.year, base.month, base.day); // 00:00
  }

  Future<void> _ensureWeekBaseline() async {
    if (!_hydrated) await _init;
    final now = DateTime.now();
    final currentWeekStart = _mondayStart(now).millisecondsSinceEpoch;
    if (_weekStartEpoch != currentWeekStart) {
      _weekStartEpoch        = currentWeekStart;
      _weekBaselineExtra     = extraPoints;
      _weekBaselineMoney     = moneySaved;
      _weekBaselineCravings  = cravingsManaged;
      await _saveToStorage();
    }
  }

  // ---------- Points ----------
  // Base points mingguan = (hari dalam minggu ini * 10) + 5 pts/ RM100 minggu ini
  int get basePoints {
    final dow = DateTime.now().weekday; // 1..7
    final weeklyDays = smokeFreeDays > 0 ? (smokeFreeDays < dow ? smokeFreeDays : dow) : 0;
    final baseFromDays  = weeklyDays * 10;
    final baseFromMoney = (weeklyMoneySaved / 100).floor() * 5;
    return baseFromDays + baseFromMoney;
  }

  int get totalPoints => basePoints + extraPoints;

  // ---------- Weekly deltas ----------
  double get weeklyMoneySaved {
    final delta = moneySaved - _weekBaselineMoney;
    return delta.isNegative ? 0.0 : delta;
  }

  int get weeklyExtraPoints {
    final delta = extraPoints - _weekBaselineExtra;
    return delta < 0 ? 0 : delta;
  }

  int get weeklyCravings {
    final delta = cravingsManaged - _weekBaselineCravings;
    return delta < 0 ? 0 : delta;
  }

  int get weeklyTotalPoints => basePoints + weeklyExtraPoints;
// === A) Kira bilangan hari unik yang dilog ===
int get uniqueDaysLogged {
  final s = <String>{};
  for (final e in _logs) {
    s.add('${e.date.year}-${e.date.month}-${e.date.day}');
  }
  return s.length;
}
  // ---------- Sync from UI ----------
  Future<void> sync({required int days, required double saved}) async {
    if (!_hydrated) await _init;
    final prevDays = smokeFreeDays;
    smokeFreeDays  = days;
    moneySaved     = saved;
    await _ensureWeekBaseline();
    await _syncTimeBasedBadges(); // Check time-based achievements
    _checkBadges(prevDays: prevDays);
    await _saveToStorage();
    notifyListeners();
  }

  /// Sync time-based badges from achievement tracker
  /// HYBRID: Checks both Firebase and local storage
  Future<void> _syncTimeBasedBadges() async {
    try {
      // Get user
      final user = FirebaseAuth.instance.currentUser;
      List<String> unlockedIds = [];

      // Try Firebase first if user is logged in
      if (user != null) {
        try {
          unlockedIds = await _firebaseAchievementService.getUnlockedAchievements(user.uid);
          debugPrint('Synced ${unlockedIds.length} badges from Firebase');
        } catch (e) {
          debugPrint('Firebase sync failed, falling back to local: $e');
        }
      }

      // Fallback to local storage if Firebase failed or no user
      if (unlockedIds.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        unlockedIds = prefs.getStringList('unlocked_achievements') ?? <String>[];
        debugPrint('Using ${unlockedIds.length} badges from local storage');
      }

      // Map achievement IDs to badge titles
      final achievementToBadge = {
        'day_1': '🌱 Day 1: Fresh Start',
        '72_hours': '⏳ 72 Hours: Detox Hero',
        '1_week': '🗓️ 1 Week Streak',
        '2_weeks': '💪 2 Weeks Strong',
        '1_month': '🌟 1 Month Milestone',
        '2_months': '🔥 2 Months Momentum',
        '3_months': '🏆 3 Months Champion',
        '6_months': '🎯 6 Months Warrior',
        '1_year': '👑 1 Year Smoke-Free Legend',
      };

      // Add unlocked achievement badges
      for (final achievementId in unlockedIds) {
        final badgeTitle = achievementToBadge[achievementId];
        if (badgeTitle != null && !badges.contains(badgeTitle)) {
          badges.add(badgeTitle);
        }
      }
    } catch (e) {
      debugPrint('Error syncing time-based badges: $e');
    }
  }

  // ---------- Actions ----------
  Future<void> addCravingManaged() async {
    if (!_hydrated) await _init;
    await _ensureWeekBaseline();
    cravingsManaged++;
    extraPoints += 3;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> completeBreathingExercise() async {
    if (!_hydrated) await _init;
    await _ensureWeekBaseline();
    cravingsManaged++;
    extraPoints += 5;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> addMoodLog({required int mood, required int craving, String? note}) async {
  if (!_hydrated) await _init;
  await _ensureWeekBaseline();

  // Replace jika hari ini sudah ada log
  final now = DateTime.now();
  _logs.removeWhere((e) =>
    e.date.year == now.year && e.date.month == now.month && e.date.day == now.day);

  _logs.insert(0, MoodLog(date: now, mood: mood, craving: craving, note: note ?? ''));

  // Reward +2 points untuk log harian
  extraPoints += 2;

  // === B) Semak badges (termasuk badge konsisten log) ===
  _checkBadges(prevDays: smokeFreeDays);

  await _saveToStorage();
  notifyListeners();
}


  // ---------- Badges ----------
  void _checkBadges({required int prevDays}) {
  bool has(String b) => badges.contains(b);
  void add(String b) { if (!has(b)) badges.add(b); }

  // --- Streak Badges ---
  if (smokeFreeDays >= 1   && prevDays < 1)   { add("🌱 Day 1: Fresh Start"); }
  if (smokeFreeDays >= 3   && prevDays < 3)   { add("⏳ 72 Hours: Detox Hero"); }
  if (smokeFreeDays >= 7   && prevDays < 7)   { add("🗓️ 1 Week Streak"); }
  if (smokeFreeDays >= 14  && prevDays < 14)  { add("💪 2 Weeks Strong"); }
  if (smokeFreeDays >= 30  && prevDays < 30)  { add("🌟 1 Month Milestone"); }
  if (smokeFreeDays >= 60  && prevDays < 60)  { add("🔥 2 Months Momentum"); }
  if (smokeFreeDays >= 90  && prevDays < 90)  { add("🏆 3 Months Champion"); }
  if (smokeFreeDays >= 180 && prevDays < 180) { add("🎯 6 Months Warrior"); }
  if (smokeFreeDays >= 365 && prevDays < 365) { add("👑 1 Year Smoke-Free Legend"); }

  // --- Savings Badges ---
  if (moneySaved >= 100   && !has("💵 RM100 Saved"))   { add("💵 RM100 Saved"); }
  if (moneySaved >= 500   && !has("💰 RM500 Saved"))   { add("💰 RM500 Saved"); }
  if (moneySaved >= 1000  && !has("💎 RM1000 Saved"))  { add("💎 RM1000 Saved"); }

  // --- Mini-tasks / Cravings ---
  if (cravingsManaged >= 5   && !has("✅ 5 Cravings Managed"))   { add("✅ 5 Cravings Managed"); }
  if (cravingsManaged >= 10  && !has("✅ 10 Cravings Managed"))  { add("✅ 10 Cravings Managed"); }
  if (cravingsManaged >= 20  && !has("✅ 20 Cravings Managed"))  { add("✅ 20 Cravings Managed"); }

    // === C) Consistent logging (unique days) ===
    if (uniqueDaysLogged >= 7  && !has("7 Days Logged"))  { add("7 Days Logged"); }
    if (uniqueDaysLogged >= 30 && !has("30 Days Logged")) { add("30 Days Logged"); }
  }

  // ---------- Get achievement tracker status ----------
  Future<List<AchievementMilestoneStatus>> getAchievementStatuses() async {
    return await _achievementTracker.getMilestonesStatus();
  }

  Future<AchievementMilestone?> getNextMilestone() async {
    return await _achievementTracker.getNextMilestone();
  }

  /// Manually check for new achievements (useful for testing)
  Future<void> checkAchievementsNow() async {
    await _achievementTracker.checkNow();
    await _syncTimeBasedBadges();
    notifyListeners();
  }

  // ---------- Reset for testing ----------
  Future<void> resetAll() async {
    if (!_hydrated) await _init;
    smokeFreeDays = 0;
    moneySaved = 0.0;
    cravingsManaged = 0;
    extraPoints = 0;
    badges.clear();
    _weekStartEpoch = null;
    _weekBaselineExtra = 0;
    _weekBaselineMoney = 0.0;
    _weekBaselineCravings = 0;
    _logs.clear();

    // Clear achievement tracker data (local)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('unlocked_achievements');

    // Clear achievement data from Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firebaseAchievementService.resetAllAchievements(user.uid);
        debugPrint('Reset Firebase achievements for user ${user.uid}');
      } catch (e) {
        debugPrint('Error resetting Firebase achievements: $e');
      }
    }

    await _saveToStorage();
    notifyListeners();
  }

  @override
  void dispose() {
    _achievementTracker.dispose();
    super.dispose();
  }
}

// ---- Model: Mood Log ----
class MoodLog {
  final DateTime date;
  final int mood;      // 1..5 (😞..😄)
  final int craving;   // 1..5
  final String? note;

  MoodLog({
    required this.date,
    required this.mood,
    required this.craving,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'ts': date.millisecondsSinceEpoch,
    'mood': mood,
    'craving': craving,
    'note': note,
  };

  factory MoodLog.fromJson(Map<String, dynamic> m) => MoodLog(
    date: DateTime.fromMillisecondsSinceEpoch(m['ts'] as int),
    mood: m['mood'] as int,
    craving: m['craving'] as int,
    note: (m['note'] as String?) ?? '',
  );
}
