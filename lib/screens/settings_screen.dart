import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'verification_screen.dart';
import 'profile_management_screen.dart';
import 'change_password_screen.dart';
import 'wallet_bank_details_screen.dart';
import 'my_listings_screen.dart';
import 'my_purchases_screen.dart';
import 'my_sales_screen.dart';
import 'referral_code_screen.dart';
import 'blocked_users_screen.dart';
import 'offers_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricLock = false;
  bool _notifyOrders = true;
  bool _notifyOffers = true;
  bool _notifyPromos = false;
  String _language = AppLanguage.instance.language;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      setState(() => _profile = profile);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('Delete Account'), style: TextStyle(color: Colors.white)),
        content: Text(tr('This permanently deletes your profile, listings, and wallet history. This cannot be undone. Continue?'),
          style: TextStyle(color: AppColors.hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Delete'), style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('$feature coming soon'))));
  }

  @override
  Widget build(BuildContext context) {
    final user = _profile;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Settings'))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: user?['profilePhotoUrl'] != null ? NetworkImage(user!['profilePhotoUrl']) : null,
                  child: user?['profilePhotoUrl'] == null
                      ? const Icon(Icons.person, size: 32, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?['email'] ?? 'Guest User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 4),
                      _VerifiedBadgeChip(status: user?['verifiedStatus'] ?? 'not_verified'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.hint),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileManagementScreen()));
                    _loadProfile();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          _SectionHeader('Account'),
          _tile(Icons.person_outline, 'Profile Management', 'Name, photo, phone/email', () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileManagementScreen()));
            _loadProfile();
          }),
          _tile(Icons.lock_reset, 'Change Password / PIN', null, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
          }),
          _tile(
            Icons.verified_outlined,
            'Verified Badge Status',
            'Pending / Approved',
            () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen()));
              _loadProfile();
            },
          ),
          _tile(Icons.list_alt_outlined, 'My Listings', 'Active, Sold, Expired', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()));
          }),
          _tile(Icons.shopping_bag_outlined, 'My Purchases', 'Accounts you bought', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPurchasesScreen()));
          }),
          _tile(Icons.storefront_outlined, 'My Sales', 'Accounts you sold', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MySalesScreen()));
          }),
          _tile(Icons.local_offer_outlined, 'Offers', 'Sent and received offers', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
          }),
          _tile(Icons.bookmark_border, 'Saved / Wishlist Accounts', null, () => _comingSoon('Wishlist')),
          _tile(Icons.account_balance_outlined, 'Wallet & Bank Details', 'Withdrawal accounts', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletBankDetailsScreen()));
          }),
          _tile(Icons.card_giftcard_outlined, 'Referral Code', 'Share & earn LKR 100 per user', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralCodeScreen()));
          }),

          _SectionHeader('Security'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: AppColors.hint),
            title: Text(tr('Biometric Lock'), style: TextStyle(color: Colors.white)),
            subtitle: Text(tr('Fingerprint / Face ID to open app'), style: TextStyle(color: AppColors.hint)),
            value: _biometricLock,
            onChanged: (v) => setState(() => _biometricLock = v),
          ),
          _tile(Icons.block_outlined, 'Blocked Users', null, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
          }),

          _SectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.receipt_long_outlined, color: AppColors.hint),
            title: Text(tr('Order Updates'), style: TextStyle(color: Colors.white)),
            value: _notifyOrders,
            onChanged: (v) => setState(() => _notifyOrders = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.local_offer_outlined, color: AppColors.hint),
            title: Text(tr('Offers & Bids'), style: TextStyle(color: Colors.white)),
            value: _notifyOffers,
            onChanged: (v) => setState(() => _notifyOffers = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined, color: AppColors.hint),
            title: Text(tr('Promotions'), style: TextStyle(color: Colors.white)),
            value: _notifyPromos,
            onChanged: (v) => setState(() => _notifyPromos = v),
          ),

          _SectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.language_outlined, color: AppColors.hint),
            title: Text(tr('Language'), style: TextStyle(color: Colors.white)),
            subtitle: Text(tr(_language), style: TextStyle(color: AppColors.hint)),
            onTap: () async {
              final choice = await showModalBottomSheet<String>(
                context: context,
                backgroundColor: AppColors.surface,
                builder: (ctx) => SafeArea(
                  child: Wrap(
                    children: ['Sinhala', 'English', 'Tamil']
                        .map((l) => ListTile(
                              title: Text(tr(l), style: TextStyle(color: Colors.white)),
                              onTap: () => Navigator.pop(ctx, l),
                            ))
                        .toList(),
                  ),
                ),
              );
              if (choice != null) {
                await AppLanguage.instance.setLanguage(choice);
                if (mounted) setState(() => _language = choice);
              }
            },
          ),

          _SectionHeader('Privacy & Data'),
          _tile(Icons.download_outlined, 'Download My Data', null, () => _comingSoon('Data export')),
          _tile(Icons.privacy_tip_outlined, 'Privacy & Data Deletion Request', null, () => _comingSoon('Deletion request')),
          _tile(Icons.description_outlined, 'Terms & Conditions', null, () => _comingSoon('Terms viewer')),
          _tile(Icons.policy_outlined, 'Privacy Policy', null, () => _comingSoon('Privacy Policy viewer')),

          _SectionHeader('Support'),
          _tile(Icons.help_outline, 'Help & FAQ', null, () => _comingSoon('Help & FAQ')),
          _tile(Icons.report_gmailerrorred_outlined, 'Report a Problem / Contact Admin', null, () => _comingSoon('Report a problem')),

          _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.hint),
            title: Text(tr('App Version'), style: TextStyle(color: Colors.white)),
            subtitle: const Text('1.0.0', style: TextStyle(color: AppColors.hint)),
          ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(onPressed: _logout, icon: Icon(Icons.logout), label: Text(tr('Logout'))),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                label: Text(tr('Delete Account'), style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.hint),
      title: Text(tr(title), style: TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(tr(subtitle), style: TextStyle(color: AppColors.hint)) : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(tr(text),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
    );
  }
}

class _VerifiedBadgeChip extends StatelessWidget {
  final String status;
  const _VerifiedBadgeChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'not_verified': ('Not Verified', AppColors.hint),
      'pending': ('Verification Pending', Colors.orange),
      'verified': ('Verified Seller', AppColors.primary),
      'rejected': ('Verification Rejected', Colors.redAccent),
    };
    final (label, color) = map[status] ?? ('Not Verified', AppColors.hint);
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      avatar: Icon(Icons.verified, size: 14, color: color),
      backgroundColor: AppColors.fieldFill,
      side: BorderSide(color: color.withOpacity(0.4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
