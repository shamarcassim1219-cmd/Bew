import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'register' or 'login'
  final String? referralCode;

  const OtpVerifyScreen({super.key, required this.email, required this.purpose, this.referralCode});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _codeCtrl = TextEditingController();
  bool _verifying = false;
  String? _error;

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      if (widget.purpose == 'register') {
        await ApiService.verifyRegistration(widget.email, code, referralCode: widget.referralCode);
      } else {
        await ApiService.verifyLogin(widget.email, code);
      }

      // Save FCM token now that we have a valid auth token
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) await ApiService.saveFcmToken(fcmToken);
      } catch (_) {
        // Non-critical — push notifications just won't work if this fails
      }

      final prefs = await SharedPreferences.getInstance();
      if (widget.purpose == 'register') {
        final pendingName = prefs.getString('pending_display_name')?.trim() ?? '';
        if (pendingName.isNotEmpty) {
          try {
            final profile = await ApiService.getProfile();
            final phone = profile['phone']?.toString() ?? '';
            await ApiService.updateProfile(pendingName, phone);
            await prefs.remove('pending_display_name');
          } catch (_) {
            // Profile can be completed later from Profile Management.
          }
        }
      }
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;

      if (widget.purpose == 'register') {
        final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => seenOnboarding ? const HomeScreen() : const OnboardingScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(tr('Verify Your Email'), style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n${widget.email}',
                style: const TextStyle(color: AppColors.hint, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(counterText: '', hintText: tr('000000')),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  child: _verifying
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(tr('Verify'), style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
