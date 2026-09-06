import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';
import 'otp_verify_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isRegister) {
        await ApiService.register(_emailCtrl.text.trim(), _passCtrl.text.trim());
      } else {
        await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      }

      if (!mounted) return;
      if (_isRegister) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_display_name', _displayNameCtrl.text.trim());
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            email: _emailCtrl.text.trim(),
            purpose: _isRegister ? 'register' : 'login',
            referralCode: _isRegister ? _referralCtrl.text.trim() : null,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '1050625555685-sn2ka7tak117d32k25fh5jstemmdmss3.apps.googleusercontent.com',
      );

      // Sign out first to always show the account picker
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled the picker
        setState(() => _googleLoading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      await ApiService.googleSignIn(idToken);

      // Use the Google profile name as the display name for new/empty profiles.
      try {
        final profile = await ApiService.getProfile();
        final existingName = profile['displayName']?.toString().trim() ?? '';
        final googleName = account.displayName?.trim() ?? '';
        if (existingName.isEmpty && googleName.length >= 2) {
          await ApiService.updateProfile(googleName, profile['phone']?.toString() ?? '');
        }
      } catch (_) {}

      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) await ApiService.saveFcmToken(fcmToken);
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;

      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => seenOnboarding ? const HomeScreen() : const OnboardingScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _selectLanguage(String language) async {
    await AppLanguage.instance.setLanguage(language);
    if (mounted) setState(() {});
  }

  void _comingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('$provider sign-in coming soon'))),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.hint, size: 20),
      suffixIcon: suffixIcon,
    );
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLanguage.instance,
      builder: (context, _) => Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.topRight,
                  child: _LoginLanguageSelector(onSelected: _selectLanguage),
                ),
                const SizedBox(height: 22),
                Text(
                  tr(_isRegister ? 'Create account' : 'Welcome back'),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  tr(_isRegister ? 'Sign up to get started' : 'Login to continue'),
                  style: const TextStyle(color: AppColors.hint, fontSize: 15),
                ),
                const SizedBox(height: 36),

                if (_isRegister) ...[
                  TextFormField(
                    controller: _displayNameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration(hint: tr('Display Name'), icon: Icons.badge_outlined),
                    validator: (v) => (v == null || v.trim().length < 2) ? tr('Enter a display name') : null,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(hint: tr('Email'), icon: Icons.mail_outline),
                  validator: (v) => (v == null || !v.contains('@')) ? tr('Enter a valid email') : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration(
                    hint: tr('Password'),
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.hint, size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? tr('Min 6 characters') : null,
                ),

                if (_isRegister) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _referralCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration(hint: tr('Referral Code (optional)'), icon: Icons.card_giftcard_outlined),
                  ),
                ],

                if (!_isRegister)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                      child: Text(tr('Forgot Password?'), style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(tr(_isRegister ? 'Sign Up' : 'Login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(tr('or continue with'), style: TextStyle(color: AppColors.hint, fontSize: 13)),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _googleLoading ? null : _handleGoogleSignIn,
                        icon: _googleLoading
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(tr('G'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        label: Text(tr('Google'), style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _comingSoon('Apple'),
                        icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                        label: Text(tr('Apple'), style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.hint, fontSize: 14),
                        children: [
                          TextSpan(text: _isRegister ? "Already have an account? " : "Don't have an account? "),
                          TextSpan(
                            text: _isRegister ? 'Login' : 'Sign Up',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}


class _LoginLanguageSelector extends StatelessWidget {
  final Future<void> Function(String) onSelected;
  const _LoginLanguageSelector({required this.onSelected});



  @override
  Widget build(BuildContext context) {
    final current = AppLanguage.instance.language;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _langButton(context, 'Sinhala', 'සිංහල', current == 'Sinhala'),
        const SizedBox(width: 8),
        _langButton(context, 'English', 'English', current == 'English'),
        const SizedBox(width: 8),
        _langButton(context, 'Tamil', 'தமிழ்', current == 'Tamil'),
      ],
    );
  }

  Widget _langButton(BuildContext context, String value, String label, bool selected) {
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFFFF5A1F), Color(0xFFD5006D)])
              : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.transparent : AppColors.primary.withOpacity(0.65)),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.primary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
