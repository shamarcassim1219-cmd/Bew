import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import 'login_screen.dart';

class BannedScreen extends StatelessWidget {
  final String reason;
  const BannedScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, color: Colors.redAccent, size: 64),
              const SizedBox(height: 20),
              Text(tr('Account Suspended'), style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(tr('Reason: $reason'), textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint, fontSize: 14)),
              const SizedBox(height: 20),
              const Text(
                tr('If you believe this is a mistake, please contact support.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.hint, fontSize: 13),
              ),
              const SizedBox(height: 30),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text(tr('Back to Login')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
