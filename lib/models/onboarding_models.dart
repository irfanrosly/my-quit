// lib/models/onboarding_models.dart

// lib/models/onboarding_models.dart

// --- Enums asas (boleh tambah kemudian)
enum Gender { male, female }
enum Education { secondary, diploma, bachelor, master, phd }
enum TobaccoType { cigarette, handRolled, vape, cigar, shisha, other }
enum TTFC { within5, m6to30, m31to60, over60 }
enum LongestSmokeFree { lt1day, d1to3, d4to7, w1to4, over1m }

// --- Data classes
class ProfileData {
  String name = '';
  int? age;
  Gender? gender;
  String? race;
  Education? education;
  String? occupation;
}

class HabitsData {
  int? yearsSmoked;
  List<TobaccoType> products = [];
  int? cigarettesPerDay;
  int? vapeSessionsPerDay;
  TTFC? ttfc;

  // Pricing data
  double? pricePerPack;         // Price per cigarette pack
  int cigsPerPack = 20;          // Cigarettes per pack (default 20)
  double? vapeSpendPerDay;       // Daily vape spending (RM)

  // Calculate daily cigarette cost
  double get dailyCigCost {
    if (products.contains(TobaccoType.cigarette) &&
        cigarettesPerDay != null &&
        pricePerPack != null &&
        cigsPerPack > 0) {
      return (cigarettesPerDay! / cigsPerPack) * pricePerPack!;
    }
    return 0.0;
  }

  // Calculate daily vape cost
  double get dailyVapeCost {
    if (products.contains(TobaccoType.vape) && vapeSpendPerDay != null) {
      return vapeSpendPerDay!;
    }
    return 0.0;
  }

  // Total daily cost (cigarettes + vape)
  double get dailyCost => dailyCigCost + dailyVapeCost;

  // Monthly and annual costs
  double get monthlyCost => dailyCost * 30;
  double get annualCost => dailyCost * 365;

  // Breakdown for UI display
  Map<String, double> get costBreakdown => {
    'cigarettes': dailyCigCost,
    'vape': dailyVapeCost,
    'total': dailyCost,
  };
}

class QuitPlanData {
  DateTime? quitDate;
  int pastAttempts = 0;
  LongestSmokeFree? longestSmokeFree;
  int readiness = 5;  // 0-10
  int confidence = 5; // 0-10
  List<String> motivations = [];
  List<String> triggers = [];
  List<String> supports = [];
}

// --- INI PENTING: digunakan oleh provider
class OnboardingState {
  final profile = ProfileData();
  final habits = HabitsData();
  final plan = QuitPlanData();
}

