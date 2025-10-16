import 'package:flutter/foundation.dart';
import '../models/onboarding_models.dart';
import '../services/firestore_service.dart';

class OnboardingProvider extends ChangeNotifier {
  // Gunakan ctor kosong model anda (error sebelum ini tunjuk OnboardingState ada ctor kosong)
  final OnboardingState _state = OnboardingState();
  OnboardingState get state => _state;

  // Load user data from Firestore
  Future<void> loadUserData(String userId) async {
    try {
      final firestoreService = FirestoreService();
      final data = await firestoreService.getUserProfile(userId);

      if (data != null) {
        // Load profile data
        _state.profile.name = data['name'] ?? '';
        _state.profile.age = data['age'];

        // Parse gender
        if (data['gender'] != null) {
          try {
            _state.profile.gender = Gender.values.firstWhere(
              (e) => e.name == data['gender'],
            );
          } catch (_) {}
        }

        _state.profile.race = data['race'];

        // Parse education
        if (data['education'] != null) {
          try {
            _state.profile.education = Education.values.firstWhere(
              (e) => e.name == data['education'],
            );
          } catch (_) {}
        }

        _state.profile.occupation = data['occupation'];

        // Load habits data
        _state.habits.yearsSmoked = data['yearsSmoked'];
        _state.habits.cigarettesPerDay = data['cigarettesPerDay'];
        _state.habits.vapeSessionsPerDay = data['vapeSessionsPerDay'];
        _state.habits.pricePerPack = data['pricePerPack'];
        _state.habits.vapeSpendPerDay = data['vapeSpendPerDay'];

        // Parse tobacco products
        if (data['tobaccoProducts'] != null) {
          final products = data['tobaccoProducts'] as List;
          _state.habits.products = products
              .map((p) {
                try {
                  return TobaccoType.values.firstWhere((e) => e.name == p);
                } catch (_) {
                  return null;
                }
              })
              .whereType<TobaccoType>()
              .toList();
        }

        // Parse TTFC
        if (data['ttfc'] != null) {
          try {
            _state.habits.ttfc = TTFC.values.firstWhere(
              (e) => e.name == data['ttfc'],
            );
          } catch (_) {}
        }

        // Load quit plan data
        if (data['quitDate'] != null) {
          try {
            _state.plan.quitDate = DateTime.parse(data['quitDate']);
          } catch (_) {}
        }

        _state.plan.readiness = data['readiness'] ?? 5;
        _state.plan.confidence = data['confidence'] ?? 5;

        if (data['motivations'] != null) {
          _state.plan.motivations = List<String>.from(data['motivations']);
        }

        if (data['triggers'] != null) {
          _state.plan.triggers = List<String>.from(data['triggers']);
        }

        if (data['supports'] != null) {
          _state.plan.supports = List<String>.from(data['supports']);
        }

        notifyListeners();
        debugPrint('User data loaded from Firestore for user: $userId');
      }
    } catch (e) {
      debugPrint('Error loading user data from Firestore: $e');
    }
  }

  // Dipanggil dari ProfileSetupScreen selepas ubah state.profile
  void notifyProfileUpdated() {
    // TODO: (opsyen) persist ke SharedPreferences jika mahu
    notifyListeners();
  }

  // Dipanggil dari SmokingHabitsScreen selepas ubah state.habits
  void notifyHabitsUpdated() {
    // TODO: (opsyen) persist
    notifyListeners();
  }

  // Dipanggil dari QuitPlanScreen selepas ubah state.plan
  void notifyPlanUpdated() {
    // TODO: (opsyen) persist
    notifyListeners();
  }
}
