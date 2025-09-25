import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

Future<void> _initDefaults() async {
  final p = await SharedPreferences.getInstance();

  // Kalau belum ada startDate, simpan sekarang
  if (!p.containsKey('startDate')) {
  await p.setInt('startDate', DateTime.now().millisecondsSinceEpoch);
}


  // Kalau belum ada cigsPerDay, set default 10
  if (!p.containsKey('cigsPerDay')) {
    await p.setInt('cigsPerDay', 10);
  }

  // Kalau belum ada pricePerStick, set default RM0.80
  if (!p.containsKey('pricePerStick')) {
    await p.setDouble('pricePerStick', 0.80);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await _initDefaults();
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => DashboardScreen()),
              );
            }
          },
          child: const Text("Login"),
        ),
      ),
    );
  }
}
