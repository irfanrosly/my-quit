// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Services
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/achievement_tracker_service.dart';
import 'services/achievement_notification_service.dart';

// Providers
import 'state/onboarding_provider.dart';
import 'state/gamification_provider.dart';

// Screens
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/craving_toolkit_screen.dart';
import 'screens/badges_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/onboarding/smoking_habits_screen.dart';
import 'screens/onboarding/quit_plan_screen.dart';
import 'screens/onboarding/summary_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyQuitMateApp());
}

class MyQuitMateApp extends StatefulWidget {
  const MyQuitMateApp({super.key});

  @override
  State<MyQuitMateApp> createState() => _MyQuitMateAppState();
}

class _MyQuitMateAppState extends State<MyQuitMateApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AchievementNotificationService _notificationService = AchievementNotificationService();
  late GamificationProvider _gamificationProvider;

  @override
  void initState() {
    super.initState();
    _gamificationProvider = GamificationProvider();
    _initializeServices();
  }

  void _initializeServices() {
    // Initialize notification service
    _notificationService.initialize(_navigatorKey);

    // Set up achievement tracker callback
    AchievementTrackerService().onAchievementUnlocked = (milestone) {
      debugPrint('Achievement unlocked: ${milestone.title}');
      _notificationService.showAchievementNotification(milestone);
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider.value(value: _gamificationProvider),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'MYQuitMate',
        theme: _buildTheme(),
        home: const AuthWrapper(),
        routes: {
          // Entry
          '/welcome': (_) => const WelcomeScreen(),
          '/login': (_) => const LoginScreen(),

          // Main app
          '/dashboard': (_) => const DashboardScreen(),
          '/progress': (_) => const ProgressScreen(),
          '/badges': (_) => const BadgesScreen(),
          '/craving': (_) => const CravingToolkitScreen(),

          // Onboarding flow
          '/onboarding/profile': (_) => const ProfileSetupScreen(),
          '/onboarding/habits': (_) => const SmokingHabitsScreen(),
          '/onboarding/plan': (_) => const QuitPlanScreen(),
          '/onboarding/summary': (_) => const OnboardingSummaryScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    // Clean, modern Material 3 theme with a green primary accent
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2FBF71),
      brightness: Brightness.light,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 1.6),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      // Ensure icons are visible with proper theming
      iconTheme: base.iconTheme.copyWith(
        size: 24.0,
        color: base.colorScheme.onSurface,
      ),
      // Ensure primary icons (like in action buttons) are visible
      primaryIconTheme: base.primaryIconTheme.copyWith(
        size: 24.0,
        color: base.colorScheme.onPrimary,
      ),
    );
  }
}

// AuthWrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<bool>(
            future: _checkOnboardingStatus(user.uid),
            builder: (context, onboardingSnapshot) {
              // Show loading while checking onboarding status
              if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Check if user has completed onboarding
              final hasCompletedOnboarding = onboardingSnapshot.data ?? false;

              if (hasCompletedOnboarding) {
                // User has completed onboarding, go to dashboard
                return const DashboardScreen();
              } else {
                // First-time user, redirect to profile setup
                return const ProfileSetupScreen();
              }
            },
          );
        }

        // User is not logged in
        return const LoginScreen();
      },
    );
  }

  Future<bool> _checkOnboardingStatus(String userId) async {
    final firestoreService = FirestoreService();
    return await firestoreService.hasCompletedOnboarding(userId);
  }
}