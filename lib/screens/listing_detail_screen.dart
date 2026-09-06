import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class ListingDetailScreen extends StatefulWidget {
  final int listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Map<String, dynamic>? _listing;
  List<dynamic> _bids = [];
  bool _loading = true;
  String? _error;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  final _bidCtrl = TextEditingController();
  bool _placingBid = false;
  String? _bidError;
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getListingDetail(widget.listingId);
      setState(() {
        _listing = data['listing'];
        _bids = data['bids'];
        _loading = false;
      });
      _startCountdownIfNeeded();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _startCountdownIfNeeded() {
    _countdownTimer?.cancel();
    final endsAtStr = _listing?['biddingEndsAt'];
    if (endsAtStr == null) return;

    final endsAt = DateTime.parse(endsAtStr).toLocal();
    void tick() {
      final now = DateTime.now();
      final diff = endsAt.difference(now);
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return 'Bidding ended';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} left';
  }

  Future<void> _placeBid() async {
    final amount = double.tryParse(_bidCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _bidError = 'Enter a valid amount');
      return;
    }
    setState(() {
      _placingBid = true;
      _bidError = null;
    });
    try {
      await ApiService.placeBid(widget.listingId, amount);
      _bidCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Bid placed!'))));
      await _load();
    } catch (e) {
      setState(() => _bidError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _placingBid = false);
    }
  }

  Future<void> _confirmAndBuy(double price) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('Confirm Purchase'), style: TextStyle(color: Colors.white)),
        content: Text(
          'LKR ${price.toStringAsFixed(2)} will be deducted from your wallet. Account credentials will be available immediately.',
          style: const TextStyle(color: AppColors.hint, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Confirm & Pay'))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _buying = true);
    try {
      await ApiService.createOrder(widget.listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Purchase successful! View credentials in My Purchases.'))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  void _showMakeOfferSheet(double currentPrice) {
    final offerCtrl = TextEditingController();
    bool sending = false;
    String? sheetError;
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
              Text(tr('Make an Offer'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Listing price: LKR ${currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: offerCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: tr('Your Offer (LKR)')),
              ),
              if (sheetError != null) ...[
                const SizedBox(height: 8),
                Text(sheetError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: sending ? null : () async {
                    final amount = double.tryParse(offerCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      setModalState(() => sheetError = 'Enter a valid amount');
                      return;
                    }
                    setModalState(() {
                      sending = true;
                      sheetError = null;
                    });
                    try {
                      await ApiService.sendOffer(widget.listingId, amount);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Offer sent to seller'))));
                    } catch (e) {
                      setModalState(() {
                        sending = false;
                        sheetError = e.toString().replaceFirst('Exception: ', '');
                      });
                    }
                  },
                  child: sending
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(tr('Send Offer')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Listing Details'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final l = _listing!;
    final screenshots = (l['screenshots'] as List?) ?? [];
    final allowBidding = l['allowBidding'] == true;
    final highestBid = l['highestBid'] != null ? (l['highestBid'] as num).toDouble() : null;
    final basePrice = (l['price'] as num).toDouble();
    final currentPrice = highestBid ?? basePrice;
    final biddingActive = allowBidding && l['biddingEndsAt'] != null && _remaining.inSeconds > 0;
    final biddingNotStarted = allowBidding && l['biddingEndsAt'] == null;
    final biddingEnded = allowBidding && l['biddingEndsAt'] != null && _remaining.inSeconds <= 0;
    final canBuyNow = l['status'] == 'active' && (!allowBidding || biddingEnded || biddingNotStarted);
    final canMakeOffer = l['status'] == 'active';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (screenshots.isNotEmpty)
          SizedBox(
            height: 220,
            child: PageView(
              children: screenshots.map<Widget>((url) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
                  )).toList(),
            ),
          ),
        const SizedBox(height: 16),
        Text(l['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Chip(
          label: Text(l['game'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: AppColors.fieldFill,
          side: const BorderSide(color: AppColors.border),
        ),
        const SizedBox(height: 12),
        Text(l['description'] ?? '', style: const TextStyle(color: AppColors.hint, fontSize: 14, height: 1.4)),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                allowBidding ? (highestBid != null ? 'Current Highest Bid' : 'Starting Price') : 'Price',
                style: const TextStyle(color: AppColors.hint, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text('LKR ${currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              if (allowBidding) ...[
                const SizedBox(height: 8),
                if (biddingActive)
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text(_formatDuration(_remaining), style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  )
                else if (biddingNotStarted)
                  Text(tr('Bidding opens with the first bid — 12 hours to win'), style: TextStyle(color: AppColors.hint, fontSize: 12))
                else
                  Text(tr('Bidding has ended — you can buy at the final price'), style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),

        if (l['status'] != 'active') ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Text(
              l['status'] == 'sold' ? 'This account has been sold.' : 'This listing is no longer available.',
              style: const TextStyle(color: AppColors.hint, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        if (allowBidding && (biddingActive || biddingNotStarted)) ...[
          const SizedBox(height: 20),
          Text(tr('Place a Bid'), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bidCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: tr('More than LKR ${currentPrice.toStringAsFixed(0)}'),
                    prefixText: 'LKR ',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _placingBid ? null : _placeBid,
                child: _placingBid
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(tr('Bid')),
              ),
            ],
          ),
          if (_bidError != null) ...[
            const SizedBox(height: 8),
            Text(_bidError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],

        if (canBuyNow) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _buying ? null : () => _confirmAndBuy(currentPrice),
              child: _buying
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text('Buy Now — LKR ${currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],

        if (canMakeOffer) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _showMakeOfferSheet(currentPrice),
              icon: const Icon(Icons.local_offer_outlined, size: 18),
              label: Text(tr('Make an Offer')),
            ),
          ),
        ],

        if (_bids.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(tr('Bid History'), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ..._bids.map((b) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.gavel_outlined, color: AppColors.hint, size: 20),
                title: Text(b['bidderDisplayName']?.toString().trim().isNotEmpty == true ? b['bidderDisplayName'].toString() : tr('User'), style: const TextStyle(color: Colors.white, fontSize: 13)),
                trailing: Text('LKR ${(b['amount'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              )),
        ],

        const SizedBox(height: 30),
      ],
    );
  }
}
