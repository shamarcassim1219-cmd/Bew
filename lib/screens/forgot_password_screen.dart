import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String? _error;
  String? _success;

  Future<void> _sendCode() async {
    if (!_emailCtrl.text.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.forgotPassword(_emailCtrl.text.trim());
      setState(() {
        _codeSent = true;
        _success = 'If this email is registered, a code has been sent.';
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiService.resetPassword(_emailCtrl.text.trim(), _codeCtrl.text.trim(), _newPassCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Password reset successfully. Please login.'))),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Reset Password'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _codeSent ? 'Enter the code and your new password' : 'Enter your account email to receive a reset code',
                style: const TextStyle(color: AppColors.hint, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailCtrl,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('Email')),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white, letterSpacing: 4),
                  decoration: InputDecoration(labelText: tr('Verification Code'), counterText: ''),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPassCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: tr('New Password')),
                ),
              ],
              if (_success != null && !_codeSent) ...[
                const SizedBox(height: 12),
                Text(_success!, style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_codeSent ? _resetPassword : _sendCode),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(_codeSent ? 'Reset Password' : 'Send Code', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _sendCode,
                    child: Text(tr('Resend Code')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
