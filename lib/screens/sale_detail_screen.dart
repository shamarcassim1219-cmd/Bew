import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import 'admin_chat_screen.dart';

class SaleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const SaleDetailScreen({super.key, required this.order});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final releaseAtStr = widget.order['escrowReleaseAt'];
    if (releaseAtStr == null || widget.order['status'] != 'escrow_held') return;

    final releaseAt = DateTime.parse(releaseAtStr).toLocal();
    void tick() {
      final diff = releaseAt.difference(DateTime.now());
      if (mounted) setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
    tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return 'Releasing soon';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m until payout';
    }
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} until payout';
  }

  String _statusLabel(String status) {
    final map = {
      'escrow_held': 'In Escrow',
      'completed': 'Paid Out',
      'disputed': 'Disputed',
      'refunded': 'Refunded',
    };
    return map[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final status = o['status'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Sale Details'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(o['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Chip(
            label: Text(o['game'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: AppColors.fieldFill,
            side: const BorderSide(color: AppColors.border),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Order ID', '#${o['id']}'),
                _row('Sale Price', 'LKR ${(o['price'] as num).toStringAsFixed(2)}'),
                _row('You Receive', 'LKR ${(o['sellerPayout'] as num).toStringAsFixed(2)}'),
                _row('Status', _statusLabel(status)),
                if (o['createdAt'] != null)
                  _row('Sold On', DateTime.parse(o['createdAt']).toLocal().toString().substring(0, 16)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(orderId: o['id'])));
              },
              icon: const Icon(Icons.support_agent_outlined),
              label: Text(tr('Chat with Admin')),
            ),
          ),

          if (status == 'escrow_held') ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 32),
                  const SizedBox(height: 10),
                  Text(_formatDuration(_remaining),
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(tr('Funds will be added to your wallet automatically once escrow releases.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.hint, fontSize: 12),
                  ),
                ],
              ),
            ),
          ] else if (status == 'completed')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.greenAccent.withOpacity(0.4))),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                  SizedBox(width: 10),
                  Expanded(child: Text(tr('Payment has been released to your wallet.'), style: TextStyle(color: Colors.greenAccent, fontSize: 13))),
                ],
              ),
            )
          else if (status == 'disputed')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withOpacity(0.4))),
              child: Text(tr('This sale is under dispute review by admin.'), style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.hint, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
