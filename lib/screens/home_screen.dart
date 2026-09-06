import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';
import 'add_listing_screen.dart';
import 'wallet_screen.dart';
import 'listing_detail_screen.dart';
import 'chat_conversation_screen.dart';
import 'notifications_screen.dart';
import 'banned_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final List<Widget> _pages = const [
    _HomeTab(),
    WalletScreen(),
    AddListingScreen(),
    _ChatsTab(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: tr('Home')),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: tr('Wallet')),
          NavigationDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: tr('Sell')),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: tr('Chats')),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: tr('Settings')),
        ],
      ),
    );
  }
}

/// Checks for the special "BANNED:<reason>" exception thrown by ApiService,
/// and if found, clears the session and navigates to the BannedScreen.
/// Returns true if the error was a ban (caller should stop further handling).
Future<bool> handleBannedError(BuildContext context, Object error) async {
  final errorStr = error.toString();
  if (errorStr.contains('BANNED:')) {
    final reason = errorStr.split('BANNED:').last.replaceFirst('Exception: ', '');
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => BannedScreen(reason: reason)),
        (route) => false,
      );
    }
    return true;
  }
  return false;
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final categories = ['PUBG', 'Free Fire', 'CODM', 'MLBB'];
  String? _selectedGame;
  List<dynamic> _listings = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadUnreadCount();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) await handleBannedError(context, e);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await ApiService.getListings(game: _selectedGame);
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final wasBanned = await handleBannedError(context, e);
      if (wasBanned) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: _profile?['profilePhotoUrl'] != null ? NetworkImage(_profile!['profilePhotoUrl']) : null,
                  child: _profile?['profilePhotoUrl'] == null
                      ? const Icon(Icons.person, size: 18, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(tr('MYGame Marketplace'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                        _loadUnreadCount();
                      },
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: tr('Search accounts...'),
                prefixIcon: const Icon(Icons.search, color: AppColors.hint),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: categories.map((c) {
                final selected = c == _selectedGame;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c, style: TextStyle(color: selected ? Colors.white : AppColors.hint)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedGame = selected ? null : c);
                      _loadListings();
                    },
                    backgroundColor: AppColors.fieldFill,
                    selectedColor: AppColors.primary.withOpacity(0.3),
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _listings.isEmpty
                        ? Center(child: Text(tr('No listings yet'), style: TextStyle(color: AppColors.hint)))
                        : RefreshIndicator(
                            onRefresh: () async {
                              await _loadListings();
                              await _loadUnreadCount();
                            },
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _listings.length,
                              itemBuilder: (context, i) {
                                final l = _listings[i];
                                final screenshots = (l['screenshots'] as List?) ?? [];
                                final allowBidding = l['allowBidding'] == true;
                                final highestBid = l['highestBid'] != null ? (l['highestBid'] as num).toDouble() : null;
                                final displayPrice = highestBid ?? (l['price'] as num).toDouble();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(10),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: l['id'])),
                                      );
                                    },
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: screenshots.isNotEmpty
                                          ? Image.network(screenshots[0], width: 56, height: 56, fit: BoxFit.cover)
                                          : Container(
                                              width: 56, height: 56, color: AppColors.fieldFill,
                                              child: const Icon(Icons.image_outlined, color: AppColors.hint),
                                            ),
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(child: Text(l['title'] ?? '', style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
                                        if (l['sellerVerified'] == true) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, size: 14, color: AppColors.primary),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text('${l['game'] ?? ''} · LKR ${displayPrice.toStringAsFixed(0)}${allowBidding ? ' (bidding)' : ''}',
                                        style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                    trailing: allowBidding
                                        ? const Icon(Icons.gavel_outlined, color: AppColors.primary, size: 18)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ChatsTab extends StatefulWidget {
  const _ChatsTab();

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final conversations = await ApiService.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final wasBanned = await handleBannedError(context, e);
      if (wasBanned) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.parse(isoString).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(tr('Chats'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _conversations.isEmpty
                        ? const Center(child: Text('No conversations yet.\nChats appear after you buy or sell an account.',
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint)))
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.primary,
                            child: ListView.builder(
                              itemCount: _conversations.length,
                              itemBuilder: (context, i) {
                                final c = _conversations[i];
                                final unread = (c['unreadCount'] as num?)?.toInt() ?? 0;
                                return ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatConversationScreen(
                                          conversationId: c['id'],
                                          otherPartyEmail: c['otherPartyEmail'] ?? '',
                                          listingTitle: c['listingTitle'] ?? '',
                                        ),
                                      ),
                                    ).then((_) => _load());
                                  },
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: c['listingImage'] != null
                                        ? Image.network(c['listingImage'], width: 48, height: 48, fit: BoxFit.cover)
                                        : Container(width: 48, height: 48, color: AppColors.fieldFill, child: const Icon(Icons.image_outlined, color: AppColors.hint)),
                                  ),
                                  title: Text(c['otherPartyEmail'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(
                                    c['lastMessage'] ?? c['listingTitle'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: unread > 0 ? Colors.white : AppColors.hint, fontSize: 12),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(_timeAgo(c['lastMessageAt']), style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                                      if (unread > 0) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                          child: Text(tr('$unread'), style: TextStyle(color: Colors.white, fontSize: 10)),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
