import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../localization.dart';
import 'login_screen.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _agreed = false;

  Future<void> _continue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('agreed_terms', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Terms & Agreement'))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Section(
                      title: '1. Escrow Policy',
                      body:
                          'All payments are held in escrow for 3 days from the time of purchase. Funds are released to the seller automatically once the hold period ends without a dispute.',
                    ),
                    _Section(
                      title: '2. Refund Policy',
                      body:
                          'Buyers may raise a dispute within the 3-day escrow window if account credentials are incorrect or access fails. Refund decisions are made by the Admin dispute panel.',
                    ),
                    _Section(
                      title: '3. No Illegal Account Trading',
                      body:
                          'Users agree not to list stolen, hacked, or fraudulently obtained accounts. MYGame Marketplace reserves the right to suspend accounts found violating this rule and is not responsible for third-party game publisher bans resulting from account transfers.',
                    ),
                    _Section(
                      title: '4. Platform Commission',
                      body:
                          'A 15% commission is deducted from every completed account sale before funds are released to the seller wallet.',
                    ),
                    _Section(
                      title: '5. Verified Seller Fee',
                      body:
                          'Sellers may pay a one-time LKR 150 fee for identity verification (NIC + Selfie) to receive the Verified Badge. This fee is non-refundable regardless of approval outcome.',
                    ),
                    _Section(
                      title: '6. Data & Privacy',
                      body:
                          'Account credentials submitted to the Vault are encrypted and only decrypted for the buyer after payment confirmation. Users may request data deletion from Settings.',
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tr('I have read and agree to the Terms, Escrow Policy, and Refund Policy.'),
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _agreed ? _continue : null,
                      child: Text(tr('I Agree & Continue'), style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 13, color: AppColors.hint, height: 1.4)),
        ],
      ),
    );
  }
}
