import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';
import 'my_purchases_screen.dart';
import 'my_sales_screen.dart';
import 'offers_screen.dart';
import 'wallet_screen.dart';
import 'verification_screen.dart';
import 'chat_conversation_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notifications = await ApiService.getNotifications();
      await ApiService.markAllNotificationsRead();
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'offer_received':
        return Icons.local_offer_outlined;
      case 'offer_accepted':
        return Icons.check_circle_outline;
      case 'offer_rejected':
        return Icons.cancel_outlined;
      case 'order_completed':
        return Icons.shopping_bag_outlined;
      case 'sale_paid':
        return Icons.attach_money;
      case 'topup_confirmed':
        return Icons.add_circle_outline;
      case 'topup_rejected':
        return Icons.remove_circle_outline;
      case 'withdrawal_confirmed':
        return Icons.arrow_circle_up_outlined;
      case 'withdrawal_rejected':
        return Icons.arrow_circle_down_outlined;
      case 'verification_approved':
        return Icons.verified_outlined;
      case 'verification_rejected':
        return Icons.error_outline;
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'dispute_resolved':
      case 'dispute_raised':
        return Icons.gavel_outlined;
      case 'account_banned':
        return Icons.block;
      case 'account_unbanned':
        return Icons.check_circle_outline;
      case 'wallet_adjusted':
        return Icons.account_balance_wallet_outlined;
      case 'referral_bonus':
        return Icons.card_giftcard;
      case 'promotion':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _handleTap(Map<String, dynamic> n) {
    final type = n['type'] ?? '';
    final relatedId = n['relatedId'];

    switch (type) {
      case 'offer_received':
      case 'offer_accepted':
      case 'offer_rejected':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
        break;

      case 'order_completed':
      case 'dispute_resolved':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPurchasesScreen()));
        break;

      case 'sale_paid':
      case 'dispute_raised':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MySalesScreen()));
        break;

      case 'topup_confirmed':
      case 'topup_rejected':
      case 'withdrawal_confirmed':
      case 'withdrawal_rejected':
      case 'wallet_adjusted':
      case 'referral_bonus':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        break;

      case 'verification_approved':
      case 'verification_rejected':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen()));
        break;

      case 'new_message':
        if (relatedId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatConversationScreen(
                conversationId: relatedId,
                otherPartyEmail: '',
                listingTitle: '',
              ),
            ),
          );
        }
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Notifications'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _notifications.isEmpty
                  ? Center(child: Text(tr('No notifications yet'), style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, i) {
                          final n = _notifications[i];
                          return ListTile(
                            onTap: () => _handleTap(n),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Icon(_iconFor(n['type'] ?? ''), color: AppColors.primary, size: 20),
                            ),
                            title: Text(tr(n['title']?.toString() ?? ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(tr(n['body']?.toString() ?? ''), style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                            trailing: Text(_timeAgo(n['createdAt']), style: const TextStyle(color: AppColors.hint, fontSize: 10)),
                          );
                        },
                      ),
                    ),
    );
  }
}
