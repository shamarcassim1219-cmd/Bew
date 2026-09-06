import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedGame = 'PUBG';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _uidCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final _vaultEmailCtrl = TextEditingController();
  final _vaultPasswordCtrl = TextEditingController();
  final _vaultRecoveryCtrl = TextEditingController();

  final List<File> _screenshots = [];
  bool _submitting = false;
  bool _allowBidding = false;
  String? _error;

  bool _loadingVerification = true;
  String _verifiedStatus = 'not_verified';

  final List<String> _games = ['PUBG', 'Free Fire', 'CODM', 'MLBB'];

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _verifiedStatus = profile['verifiedStatus'] ?? 'not_verified';
        _loadingVerification = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingVerification = false);
    }
  }

  Future<void> _pickScreenshots() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _screenshots.addAll(picked.map((x) => File(x.path)));
        if (_screenshots.length > 6) {
          _screenshots.removeRange(6, _screenshots.length);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Failed to pick images: $e'))),
      );
    }
  }

  Future<List<String>> _uploadScreenshots() async {
    final urls = <String>[];
    for (final file in _screenshots) {
      final url = await ApiService.uploadImage(file);
      urls.add(url);
    }
    return urls;
  }

  Future<void> _resetForm() async {
    _titleCtrl.clear();
    _descCtrl.clear();
    _uidCtrl.clear();
    _priceCtrl.clear();
    _vaultEmailCtrl.clear();
    _vaultPasswordCtrl.clear();
    _vaultRecoveryCtrl.clear();
    if (mounted) {
      setState(() {
        _screenshots.clear();
        _allowBidding = false;
        _selectedGame = 'PUBG';
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_screenshots.isEmpty) {
      setState(() => _error = 'Add at least one screenshot');
      return;
    }
    if (_vaultEmailCtrl.text.trim().isEmpty || _vaultPasswordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Account email & password are required for the vault');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final screenshotUrls = await _uploadScreenshots();

      await ApiService.createListing(
        game: _selectedGame,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        inGameUID: _uidCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        screenshots: screenshotUrls,
        vaultEmail: _vaultEmailCtrl.text.trim(),
        vaultPassword: _vaultPasswordCtrl.text.trim(),
        vaultRecoveryCodes: _vaultRecoveryCtrl.text.trim(),
        allowBidding: _allowBidding,
      );

      if (!mounted) return;

      await _resetForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Listing posted successfully'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingVerification) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_verifiedStatus != 'verified') {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(title: Text(tr('Sell an Account'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_outlined, color: AppColors.hint, size: 64),
                const SizedBox(height: 20),
                Text(tr('Verification Required'), style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  _verifiedStatus == 'pending'
                      ? 'Your verification is under review. You can post listings once approved.'
                      : 'Only verified sellers can post listings. Go to Settings to get verified.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.hint, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Sell an Account'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionLabel('Game'),
              Wrap(
                spacing: 8,
                children: _games.map((g) {
                  final selected = g == _selectedGame;
                  return ChoiceChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedGame = g),
                    backgroundColor: AppColors.fieldFill,
                    selectedColor: AppColors.primary.withOpacity(0.3),
                    labelStyle: TextStyle(color: selected ? Colors.white : AppColors.hint),
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const _SectionLabel('Listing Details'),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('Title'), hintText: tr('e.g. Conqueror Rank Account')),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('Description'), hintText: tr('Rank, skins, level, region...')),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _uidCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('In-Game UID')),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('Price (LKR)'), prefixText: 'LKR '),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              if (_priceCtrl.text.isNotEmpty && double.tryParse(_priceCtrl.text.trim()) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _CommissionPreview(price: double.parse(_priceCtrl.text.trim())),
                ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _allowBidding,
                  onChanged: (v) => setState(() => _allowBidding = v),
                  title: Text(tr('Allow Bidding'), style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    tr('Buyers can bid above your price. Once the first bid comes in, bidding runs for 12 hours.'),
                    style: TextStyle(color: AppColors.hint, fontSize: 11),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const _SectionLabel('Screenshots (max 6)'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
                ),
                itemCount: _screenshots.length + 1,
                itemBuilder: (context, i) {
                  if (i == _screenshots.length) {
                    return InkWell(
                      onTap: _screenshots.length >= 6 ? null : _pickScreenshots,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: AppColors.hint),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_screenshots[i], width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _screenshots.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 10, backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
              const _SectionLabel('Account Vault (Private & Encrypted)'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('These details are stored securely and shown to the buyer immediately after payment.'),
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vaultEmailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('Account Email')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vaultPasswordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('Account Password')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vaultRecoveryCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('Recovery Codes (optional)')),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(tr('Post Listing'), style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
    );
  }
}

class _CommissionPreview extends StatelessWidget {
  final double price;
  const _CommissionPreview({required this.price});

  @override
  Widget build(BuildContext context) {
    final commission = price * 0.15;
    final youGet = price - commission;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Listing Price', 'LKR ${price.toStringAsFixed(2)}'),
          _row('Platform Commission (15%)', '- LKR ${commission.toStringAsFixed(2)}'),
          const Divider(height: 12, color: AppColors.border),
          _row('You Receive', 'LKR ${youGet.toStringAsFixed(2)}', bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85), fontWeight: bold ? FontWeight.bold : null)),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}
