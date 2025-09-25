// lib/main.dart
import 'package:flutter/material.dart';
import 'chatbot/myquitmate_chatbot.dart'; // <— chatBOT
import 'package:provider/provider.dart';

// Providers
import 'state/onboarding_provider.dart';
import 'state/gamification_provider.dart';

// Screens
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/craving_toolkit_screen.dart';
import 'screens/badges_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/onboarding/smoking_habits_screen.dart';
import 'screens/onboarding/quit_plan_screen.dart';
import 'screens/onboarding/summary_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyQuitMateApp());
}

class MyQuitMateApp extends StatelessWidget {
  const MyQuitMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MYQuitMate',
        theme: _buildTheme(),
        initialRoute: '/welcome',
        routes: {
          // Entry
          '/welcome': (_) => const WelcomeScreen(),

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
    );
  }
}