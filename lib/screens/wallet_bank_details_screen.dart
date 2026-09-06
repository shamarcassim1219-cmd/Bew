import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class WalletBankDetailsScreen extends StatefulWidget {
  const WalletBankDetailsScreen({super.key});

  @override
  State<WalletBankDetailsScreen> createState() => _WalletBankDetailsScreenState();
}

class _WalletBankDetailsScreenState extends State<WalletBankDetailsScreen> {
  final _bankNameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  bool _loading = true;
  bool _sendingCode = false;
  String? _error;
  String? _currentBankName;
  String? _currentAccountNumber;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ApiService.getProfile();
      _bankNameCtrl.text = profile['bankName'] ?? '';
      _accountNameCtrl.text = profile['bankAccountName'] ?? '';
      _accountNumberCtrl.text = profile['bankAccountNumber'] ?? '';
      _branchCtrl.text = profile['bankBranch'] ?? '';
      _currentBankName = profile['bankName'];
      _currentAccountNumber = profile['bankAccountNumber'];
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    setState(() => _loading = false);
  }

  Future<void> _requestChange() async {
    if (_bankNameCtrl.text.trim().isEmpty ||
        _accountNameCtrl.text.trim().isEmpty ||
        _accountNumberCtrl.text.trim().isEmpty ||
        _branchCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all bank detail fields');
      return;
    }

    setState(() {
      _sendingCode = true;
      _error = null;
    });

    try {
      await ApiService.requestBankDetailsChange(
        _bankNameCtrl.text.trim(),
        _accountNameCtrl.text.trim(),
        _accountNumberCtrl.text.trim(),
        _branchCtrl.text.trim(),
      );
      if (!mounted) return;
      _showOtpDialog();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  void _showOtpDialog() {
    final codeCtrl = TextEditingController();
    bool confirming = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(tr('Enter Verification Code'), style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('We sent a 6-digit code to your email. Enter it below to confirm the bank details change.'),
                style: TextStyle(color: AppColors.hint, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 4),
                textAlign: TextAlign.center,
                decoration: InputDecoration(counterText: '', hintText: tr('000000')),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(dialogError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'))),
            ElevatedButton(
              onPressed: confirming ? null : () async {
                final code = codeCtrl.text.trim();
                if (code.length != 6) {
                  setDialogState(() => dialogError = 'Enter the 6-digit code');
                  return;
                }
                setDialogState(() {
                  confirming = true;
                  dialogError = null;
                });
                try {
                  await ApiService.confirmBankDetailsChange(code);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('Bank details updated successfully'))),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  setDialogState(() {
                    confirming = false;
                    dialogError = e.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              child: confirming
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(tr('Confirm')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Wallet & Bank Details'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr('Changing your bank details requires email verification for security.'),
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: _bankNameCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: tr('Bank Name'))),
                  const SizedBox(height: 14),
                  TextField(controller: _accountNameCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: tr('Account Holder Name'))),
                  const SizedBox(height: 14),
                  TextField(controller: _accountNumberCtrl, keyboardType: TextInputType.number, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: tr('Account Number'))),
                  const SizedBox(height: 14),
                  TextField(controller: _branchCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: tr('Branch'))),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _sendingCode ? null : _requestChange,
                      child: _sendingCode
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(tr('Send Verification Code'), style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
