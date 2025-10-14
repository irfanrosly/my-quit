// lib/services/firebase_achievement_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service for syncing achievements with Firebase Firestore
/// Implements hybrid approach: Firebase (primary) + Local storage (fallback)
class FirebaseAchievementService {
  static final FirebaseAchievementService _instance = FirebaseAchievementService._internal();
  factory FirebaseAchievementService() => _instance;
  FirebaseAchievementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save achievement unlock to Firebase
  Future<bool> unlockAchievement({
    required String userId,
    required String achievementId,
    required String title,
    required String description,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .set({
        'title': title,
        'description': description,
        'unlockedAt': FieldValue.serverTimestamp(),
        'achievementId': achievementId,
      }, SetOptions(merge: true));

      debugPrint('FirebaseAchievement: Saved $achievementId for user $userId');
      return true;
    } catch (e) {
      debugPrint('FirebaseAchievement: Error saving $achievementId: $e');
      return false;
    }
  }

  /// Get all unlocked achievements for a user from Firebase
  Future<List<String>> getUnlockedAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      final achievementIds = snapshot.docs
          .map((doc) => doc.id)
          .toList();

      debugPrint('FirebaseAchievement: Loaded ${achievementIds.length} achievements for user $userId');
      return achievementIds;
    } catch (e) {
      debugPrint('FirebaseAchievement: Error loading achievements: $e');
      return [];
    }
  }

  /// Get achievements with full details
  Future<List<Map<String, dynamic>>> getAchievementDetails(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .orderBy('unlockedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'unlockedAt': data['unlockedAt'] as Timestamp?,
        };
      }).toList();
    } catch (e) {
      debugPrint('FirebaseAchievement: Error loading achievement details: $e');
      return [];
    }
  }

  /// Save quit date to Firebase (for cross-device sync)
  Future<bool> saveQuitDate({
    required String userId,
    required DateTime quitDate,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'quitDate': Timestamp.fromDate(quitDate),
        'quitDateMillis': quitDate.millisecondsSinceEpoch,
      });

      debugPrint('FirebaseAchievement: Saved quit date for user $userId');
      return true;
    } catch (e) {
      debugPrint('FirebaseAchievement: Error saving quit date: $e');
      return false;
    }
  }

  /// Get quit date from Firebase
  Future<DateTime?> getQuitDate(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Try to get from Timestamp first
      if (data['quitDate'] != null) {
        final timestamp = data['quitDate'] as Timestamp;
        return timestamp.toDate();
      }

      // Fallback to millis
      if (data['quitDateMillis'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(data['quitDateMillis'] as int);
      }

      return null;
    } catch (e) {
      debugPrint('FirebaseAchievement: Error loading quit date: $e');
      return null;
    }
  }

  /// Stream of achievements for real-time updates
  Stream<List<String>> watchAchievements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Sync local achievements to Firebase (for migration)
  Future<bool> syncLocalToFirebase({
    required String userId,
    required List<String> localAchievementIds,
    required Map<String, String> achievementTitles,
    required Map<String, String> achievementDescriptions,
  }) async {
    try {
      final batch = _firestore.batch();
      final userAchievementsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements');

      for (final achievementId in localAchievementIds) {
        final docRef = userAchievementsRef.doc(achievementId);
        batch.set(docRef, {
          'title': achievementTitles[achievementId] ?? '',
          'description': achievementDescriptions[achievementId] ?? '',
          'unlockedAt': FieldValue.serverTimestamp(),
          'achievementId': achievementId,
          'migratedFromLocal': true,
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('FirebaseAchievement: Synced ${localAchievementIds.length} local achievements to Firebase');
      return true;
    } catch (e) {
      debugPrint('FirebaseAchievement: Error syncing to Firebase: $e');
      return false;
    }
  }

  /// Check if achievement exists in Firebase
  Future<bool> hasAchievement({
    required String userId,
    required String achievementId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('FirebaseAchievement: Error checking achievement: $e');
      return false;
    }
  }

  /// Delete achievement (for testing/admin purposes)
  Future<bool> deleteAchievement({
    required String userId,
    required String achievementId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .delete();

      debugPrint('FirebaseAchievement: Deleted $achievementId for user $userId');
      return true;
    } catch (e) {
      debugPrint('FirebaseAchievement: Error deleting achievement: $e');
      return false;
    }
  }

  /// Reset all achievements (for testing)
  Future<bool> resetAllAchievements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('FirebaseAchievement: Reset all achievements for user $userId');
      return true;
    } catch (e) {
      debugPrint('FirebaseAchievement: Error resetting achievements: $e');
      return false;
    }
  }

  /// Get achievement statistics
  Future<Map<String, dynamic>> getAchievementStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      final achievements = snapshot.docs;
      final unlockDates = achievements
          .map((doc) => doc.data()['unlockedAt'] as Timestamp?)
          .where((timestamp) => timestamp != null)
          .map((timestamp) => timestamp!.toDate())
          .toList();

      unlockDates.sort();

      return {
        'totalUnlocked': achievements.length,
        'firstUnlocked': unlockDates.isNotEmpty ? unlockDates.first : null,
        'lastUnlocked': unlockDates.isNotEmpty ? unlockDates.last : null,
        'achievementIds': achievements.map((doc) => doc.id).toList(),
      };
    } catch (e) {
      debugPrint('FirebaseAchievement: Error getting stats: $e');
      return {
        'totalUnlocked': 0,
        'firstUnlocked': null,
        'lastUnlocked': null,
        'achievementIds': <String>[],
      };
    }
  }
}
