import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0;
  List<dynamic> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final balance = await ApiService.getWalletBalance();
      final transactions = await ApiService.getTransactions();
      setState(() {
        _balance = balance;
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('My Wallet'))),
      body: Container(
        color: AppColors.bg,
        width: double.infinity,
        height: double.infinity,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(onPressed: _load, child: Text(tr('Retry'))),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF4A2FD6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('Available Balance'), style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                              const SizedBox(height: 6),
                              Text('LKR ${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showTopUpSheet(context),
                                icon: const Icon(Icons.add_circle_outline),
                                label: Text(tr('Top Up')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showWithdrawSheet(context, _balance),
                                icon: const Icon(Icons.arrow_circle_up_outlined),
                                label: Text(tr('Withdraw')),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(tr('Transaction History'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                        const SizedBox(height: 8),
                        if (_transactions.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(child: Text(tr('No transactions yet'), style: TextStyle(color: AppColors.hint))),
                          )
                        else
                          ..._transactions.map((tx) => _TransactionTile(
                                type: tx['type'] ?? 'unknown',
                                amount: (tx['amount'] as num?)?.toDouble() ?? 0,
                                status: tx['status'] ?? 'pending',
                              )),
                      ],
                    ),
                  ),
      ),
    );
  }

  void _showTopUpSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    File? slipFile;
    bool submitting = false;
    bool loadingBankDetails = true;
    Map<String, dynamic>? bankDetails;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (loadingBankDetails) {
            ApiService.getAdminBankDetails().then((data) {
              setModalState(() {
                bankDetails = data;
                loadingBankDetails = false;
              });
            }).catchError((e) {
              setModalState(() {
                sheetError = e.toString().replaceFirst('Exception: ', '');
                loadingBankDetails = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Top Up Wallet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  if (loadingBankDetails)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.primary)))
                  else if (bankDetails != null) ...[
                    Text(tr('Deposit to this account'), style: TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bank: ${bankDetails!['bankName']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Account Name: ${bankDetails!['accountName']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Account Number: ${bankDetails!['accountNumber']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Branch: ${bankDetails!['branch']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: tr('Amount (LKR)')),
                  ),
                  const SizedBox(height: 12),
                  Text(tr('Upload Bank Slip'), style: TextStyle(color: AppColors.hint, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        setModalState(() => slipFile = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.fieldFill, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                      child: slipFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(slipFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_outlined, color: AppColors.hint, size: 28),
                                SizedBox(height: 6),
                                Text(tr('Tap to upload slip'), style: TextStyle(color: AppColors.hint, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  if (sheetError != null) ...[
                    const SizedBox(height: 10),
                    Text(sheetError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: submitting ? null : () async {
                        final amount = double.tryParse(amountCtrl.text.trim());
                        if (amount == null || amount <= 0) {
                          setModalState(() => sheetError = 'Enter a valid amount');
                          return;
                        }
                        if (slipFile == null) {
                          setModalState(() => sheetError = 'Please upload your bank slip');
                          return;
                        }
                        setModalState(() {
                          submitting = true;
                          sheetError = null;
                        });
                        try {
                          final slipUrl = await ApiService.uploadImage(slipFile!);
                          await ApiService.requestTopUp(amount, slipUrl);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Top-up request submitted'))));
                          _load();
                        } catch (e) {
                          setModalState(() {
                            submitting = false;
                            sheetError = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      },
                      child: submitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(tr('Submit Top-Up')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, double balance) {
    final amountCtrl = TextEditingController();
    bool submitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Withdraw to Bank'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Available: LKR ${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.hint)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('Amount (LKR)')),
              ),
              const SizedBox(height: 12),
              Text(
                '${tr('Make sure your bank details are saved in Settings → Wallet & Bank Details before withdrawing. ')}'
                '${tr('The amount will be deducted from your wallet immediately and refunded if the request is rejected.')}',
                style: TextStyle(fontSize: 12, color: AppColors.hint),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) return;
                    setModalState(() => submitting = true);
                    try {
                      await ApiService.requestWithdrawal(amount);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Withdrawal request submitted'))));
                      _load();
                    } catch (e) {
                      setModalState(() => submitting = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                    }
                  },
                  child: submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(tr('Request Withdrawal')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String type;
  final double amount;
  final String status;

  const _TransactionTile({required this.type, required this.amount, required this.status});

  Map<String, dynamic> get _display {
    switch (type) {
      case 'topup': return {'label': 'Wallet Top-Up', 'icon': Icons.add_circle_outline};
      case 'withdrawal': return {'label': 'Withdrawal', 'icon': Icons.arrow_circle_up_outlined};
      case 'sale_release': return {'label': 'Account Sale', 'icon': Icons.sell_outlined};
      case 'commission': return {'label': 'Platform Commission', 'icon': Icons.percent};
      case 'referral_bonus': return {'label': 'Referral Bonus', 'icon': Icons.card_giftcard};
      case 'purchase_hold': return {'label': 'Purchase (Escrow)', 'icon': Icons.lock_clock_outlined};
      default: return {'label': type, 'icon': Icons.receipt_long};
    }
  }

  Color _statusColor() {
    switch (status) {
      case 'completed': return Colors.greenAccent;
      case 'failed': return Colors.redAccent;
      default: return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _display;
    final positive = amount >= 0;
    final color = positive ? Colors.greenAccent : Colors.redAccent;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(d['icon'] as IconData, color: color, size: 20),
      ),
      title: Text(d['label'] as String, style: const TextStyle(color: Colors.white)),
      subtitle: Text(status, style: TextStyle(color: _statusColor(), fontSize: 12)),
      trailing: Text('${positive ? '+' : ''} LKR ${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    );
  }
}
