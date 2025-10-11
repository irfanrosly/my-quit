// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user profile
  Future<void> saveUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        data,
        SetOptions(merge: true), // Merge with existing data
      );
    } catch (e) {
      throw 'Failed to save user profile: $e';
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw 'Failed to get user profile: $e';
    }
  }

  // Stream user profile (real-time updates)
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Save quit plan data
  Future<void> saveQuitPlan({
    required String userId,
    required DateTime quitDate,
    required int cigarettesPerDay,
    required double pricePerStick,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final data = {
        'quitDate': Timestamp.fromDate(quitDate),
        'cigarettesPerDay': cigarettesPerDay,
        'pricePerStick': pricePerStick,
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      await _firestore.collection('users').doc(userId).update({
        'quitPlan': data,
      });
    } catch (e) {
      throw 'Failed to save quit plan: $e';
    }
  }

  // Save mood log
  Future<void> saveMoodLog({
    required String userId,
    required String mood,
    String? notes,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('moodLogs').add({
        'mood': mood,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to save mood log: $e';
    }
  }

  // Get mood logs
  Future<List<Map<String, dynamic>>> getMoodLogs(String userId, {int limit = 30}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('moodLogs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Failed to get mood logs: $e';
    }
  }

  // Save badge achievement
  Future<void> saveBadge({
    required String userId,
    required String badgeId,
    required String badgeName,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('badges').doc(badgeId).set({
        'name': badgeName,
        'earnedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to save badge: $e';
    }
  }

  // Get user badges
  Future<List<Map<String, dynamic>>> getBadges(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Failed to get badges: $e';
    }
  }
}
