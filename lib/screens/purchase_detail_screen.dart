import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';
import 'vault_reveal_screen.dart';
import 'admin_chat_screen.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const PurchaseDetailScreen({super.key, required this.order});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  late Map<String, dynamic> _order;
  Timer? _timer;
  bool _deadlinePassed = false;
  bool _notifying = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _checkDeadline();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkDeadline());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkDeadline() {
    final deadlineStr = _order['adminReviewDeadline'];
    if (deadlineStr == null || _order['adminReviewed'] == true) return;
    final deadline = DateTime.parse(deadlineStr).toLocal();
    final passed = DateTime.now().isAfter(deadline);
    if (mounted && passed != _deadlinePassed) {
      setState(() => _deadlinePassed = passed);
    }
  }

  Future<void> _notifyAdmin() async {
    setState(() => _notifying = true);
    try {
      await ApiService.notifyAdminOverdue(_order['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Admin has been notified'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _notifying = false);
    }
  }

  void _showDisputeDialog() {
    final reasonCtrl = TextEditingController();
    bool sending = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(tr('Raise a Dispute'), style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: reasonCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: tr('Describe the issue with this account...')),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'))),
            ElevatedButton(
              onPressed: sending ? null : () async {
                if (reasonCtrl.text.trim().isEmpty) return;
                setDialogState(() => sending = true);
                try {
                  await ApiService.raiseDispute(_order['id'], reasonCtrl.text.trim());
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Dispute raised — admin will review'))));
                  setState(() => _order['status'] = 'disputed');
                } catch (e) {
                  setDialogState(() => sending = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                }
              },
              child: sending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(tr('Submit')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenshots = (_order['screenshots'] as List?) ?? [];
    final status = _order['status'];
    final adminReviewed = _order['adminReviewed'] == true;
    final canViewVault = status != 'disputed' && adminReviewed;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Purchase Details'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (screenshots.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView(
                children: screenshots.map<Widget>((url) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
                    )).toList(),
              ),
            ),
          const SizedBox(height: 16),
          Text(_order['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Chip(
            label: Text(_order['game'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                _row('Order ID', '#${_order['id']}'),
                _row('Amount Paid', 'LKR ${(_order['price'] as num).toStringAsFixed(2)}'),
                _row('Status', _statusLabel(status)),
                if (_order['createdAt'] != null)
                  _row('Purchased On', DateTime.parse(_order['createdAt']).toLocal().toString().substring(0, 16)),
              ],
            ),
          ),

          if (!adminReviewed && status != 'disputed') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.hourglass_top_outlined, color: Colors.orangeAccent, size: 20),
                      SizedBox(width: 8),
                      Text(tr('Admin is verifying this account'), style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    tr('You will be notified once credentials are shared. Usually within 1 hour.'),
                    style: TextStyle(color: AppColors.hint, fontSize: 12),
                  ),
                  if (_deadlinePassed) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _notifying ? null : _notifyAdmin,
                        icon: _notifying
                            ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.notifications_active_outlined, size: 16, color: Colors.orangeAccent),
                        label: Text(tr('Notify Admin — Review Overdue'), style: TextStyle(color: Colors.orangeAccent)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(orderId: _order['id'])));
              },
              icon: const Icon(Icons.support_agent_outlined),
              label: Text(tr('Chat with Admin')),
            ),
          ),

          if (canViewVault) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VaultRevealScreen(orderId: _order['id'])));
                },
                icon: const Icon(Icons.lock_open_outlined),
                label: Text(tr('View Account Credentials')),
              ),
            ),
          ],

          if (status == 'escrow_held') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _showDisputeDialog,
                icon: const Icon(Icons.report_problem_outlined, color: Colors.orangeAccent),
                label: Text(tr('Raise a Dispute'), style: TextStyle(color: Colors.orangeAccent)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
              ),
            ),
          ] else if (status == 'disputed')
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.4))),
              child: Text(tr('This order is under dispute review by admin.'), style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    final map = {
      'escrow_held': 'In Escrow',
      'completed': 'Completed',
      'disputed': 'Disputed',
      'refunded': 'Refunded',
    };
    return map[status] ?? status;
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
