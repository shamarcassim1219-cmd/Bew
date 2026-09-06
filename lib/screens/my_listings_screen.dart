import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';
import 'listing_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<dynamic> _listings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final listings = await ApiService.getMyListings();
      setState(() {
        _listings = listings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _confirmRemove(int listingId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('Remove Listing'), style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "$title"? Any active bidders will be refunded automatically.',
          style: const TextStyle(color: AppColors.hint, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.removeListing(listingId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Listing removed'))));
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: Text(tr('Remove'), style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('My Listings'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _listings.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No listings yet.\nTap "Sell" to post your first account.',
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _listings.length,
                        itemBuilder: (context, i) {
                          final l = _listings[i];
                          final status = l['status'] ?? 'active';
                          final screenshots = (l['screenshots'] as List?) ?? [];
                          final allowBidding = l['allowBidding'] == true;
                          final highestBid = l['highestBid'] != null ? (l['highestBid'] as num).toDouble() : null;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: l['id'])),
                                    ).then((_) => _load());
                                  },
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: screenshots.isNotEmpty
                                        ? Image.network(screenshots[0], width: 56, height: 56, fit: BoxFit.cover)
                                        : Container(width: 56, height: 56, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                                  ),
                                  title: Text(l['title'] ?? '', style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(
                                    '${l['game'] ?? ''} · LKR ${(highestBid ?? l['price']).toStringAsFixed(0)}${allowBidding ? ' (bidding)' : ''}',
                                    style: const TextStyle(color: AppColors.hint, fontSize: 12),
                                  ),
                                  trailing: _StatusChip(status: status),
                                ),
                                if (status == 'active')
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _confirmRemove(l['id'], l['title'] ?? ''),
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                        label: Text(tr('Remove Listing'), style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.redAccent),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
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
      'active': ('Active', Colors.greenAccent),
      'pending_escrow': ('Pending', Colors.orangeAccent),
      'sold': ('Sold', AppColors.primary),
      'expired': ('Removed', AppColors.hint),
    };
    final (label, color) = map[status] ?? ('Unknown', AppColors.hint);
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.4)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
