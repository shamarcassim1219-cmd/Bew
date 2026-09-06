import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _sent = [];
  List<dynamic> _received = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sent = await ApiService.getOffersSent();
      final received = await ApiService.getOffersReceived();
      setState(() {
        _sent = sent;
        _received = received;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _accept(int offerId) async {
    try {
      await ApiService.acceptOffer(offerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Offer accepted — order created'))));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _reject(int offerId) async {
    try {
      await ApiService.rejectOffer(offerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Offer rejected'))));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(tr('Offers')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.hint,
          tabs: const [Tab(text: 'Received'), Tab(text: 'Sent')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _receivedList(),
                    _sentList(),
                  ],
                ),
    );
  }

  Widget _receivedList() {
    if (_received.isEmpty) {
      return Center(child: Text(tr('No offers received yet'), style: TextStyle(color: AppColors.hint)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _received.length,
        itemBuilder: (context, i) {
          final o = _received[i];
          final status = o['status'];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('From ${o['buyerEmail']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('LKR ${(o['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (status == 'pending') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(onPressed: () => _reject(o['id']), child: Text(tr('Reject'))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(onPressed: () => _accept(o['id']), child: Text(tr('Accept'))),
                      ),
                    ],
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _StatusChip(status: status),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sentList() {
    if (_sent.isEmpty) {
      return Center(child: Text(tr('No offers sent yet'), style: TextStyle(color: AppColors.hint)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _sent.length,
        itemBuilder: (context, i) {
          final o = _sent[i];
          final screenshots = (o['screenshots'] as List?) ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: screenshots.isNotEmpty
                      ? Image.network(screenshots[0], width: 48, height: 48, fit: BoxFit.cover)
                      : Container(width: 48, height: 48, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Your offer: LKR ${(o['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                    ],
                  ),
                ),
                _StatusChip(status: o['status']),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final map = {
      'pending': ('Pending', Colors.orangeAccent),
      'accepted': ('Accepted', Colors.greenAccent),
      'rejected': ('Rejected', Colors.redAccent),
      'expired': ('Expired', AppColors.hint),
    };
    final (label, color) = map[status] ?? (status, AppColors.hint);
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 10, color: color)),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
