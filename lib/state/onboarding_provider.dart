import 'package:flutter/foundation.dart';
import '../models/onboarding_models.dart';

class OnboardingProvider extends ChangeNotifier {
  // Gunakan ctor kosong model anda (error sebelum ini tunjuk OnboardingState ada ctor kosong)
  final OnboardingState _state = OnboardingState();
  OnboardingState get state => _state;

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
