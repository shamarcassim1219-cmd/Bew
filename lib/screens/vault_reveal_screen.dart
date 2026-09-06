import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class VaultRevealScreen extends StatefulWidget {
  final int orderId;
  const VaultRevealScreen({super.key, required this.orderId});

  @override
  State<VaultRevealScreen> createState() => _VaultRevealScreenState();
}

class _VaultRevealScreenState extends State<VaultRevealScreen> {
  Map<String, dynamic>? _vault;
  bool _loading = true;
  String? _error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getOrderVault(widget.orderId);
      setState(() {
        _vault = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('$label copied'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Account Credentials'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                  ),
                )
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tr('Change these credentials immediately after login for your own security.'),
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _CredentialTile(
                        label: tr('Account Email'),
                        value: _vault!['email'] ?? '',
                        onCopy: () => _copy('Email', _vault!['email'] ?? ''),
                      ),
                      const SizedBox(height: 12),
                      _CredentialTile(
                        label: tr('Account Password'),
                        value: _obscurePassword ? '••••••••' : (_vault!['password'] ?? ''),
                        onCopy: () => _copy('Password', _vault!['password'] ?? ''),
                        trailing: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.hint, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      if (_vault!['recoveryCodes'] != null && (_vault!['recoveryCodes'] as String).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _CredentialTile(
                          label: tr('Recovery Codes'),
                          value: _vault!['recoveryCodes'],
                          onCopy: () => _copy('Recovery codes', _vault!['recoveryCodes']),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _CredentialTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final Widget? trailing;

  const _CredentialTile({required this.label, required this.value, required this.onCopy, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15))),
              if (trailing != null) trailing!,
              IconButton(icon: const Icon(Icons.copy, color: AppColors.hint, size: 18), onPressed: onCopy),
            ],
          ),
        ],
      ),
    );
  }
}
