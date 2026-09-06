import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../localization.dart';
import 'onboarding_screen.dart';
import 'agreement_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();

    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final agreedTerms = prefs.getBool('agreed_terms') ?? false;
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!mounted) return;

    Widget next;
    if (!seenOnboarding) {
      next = const OnboardingScreen();
    } else if (!agreedTerms) {
      next = const AgreementScreen();
    } else if (!isLoggedIn) {
      next = const LoginScreen();
    } else {
      next = const HomeScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_esports_rounded, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(tr('MYGame Marketplace'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(tr('Buy & Sell Game Accounts Safely'),
                style: TextStyle(fontSize: 14, color: AppColors.hint)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
