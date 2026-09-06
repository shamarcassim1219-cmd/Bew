import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class ChatConversationScreen extends StatefulWidget {
  final int conversationId;
  final String otherPartyEmail; // legacy/internal only; never displayed
  final String? otherPartyDisplayName;
  final String listingTitle;

  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherPartyEmail,
    this.otherPartyDisplayName,
    required this.listingTitle,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;
  String? _error;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  Timer? _pollTimer;

  String _headerDisplayName = '';
  String _headerTitle = '';

  @override
  void initState() {
    super.initState();
    _loadHeaderIfNeeded().then((_) {
      if (mounted) setState(() {});
    });
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHeaderIfNeeded() async {
    if (widget.otherPartyDisplayName?.trim().isNotEmpty == true) {
      _headerDisplayName = widget.otherPartyDisplayName!.trim();
      _headerTitle = widget.listingTitle;
      return;
    }
    if (widget.otherPartyEmail.isNotEmpty) {
      // Do not expose email addresses to other users.
      _headerDisplayName = tr('User');
      _headerTitle = widget.listingTitle;
      return;
    }
    try {
      final conversations = await ApiService.getConversations();
      final match = conversations.firstWhere(
        (c) => c['id'] == widget.conversationId,
        orElse: () => null,
      );
      if (match != null) {
        _headerDisplayName = (match['otherPartyDisplayName']?.toString().trim().isNotEmpty == true)
            ? match['otherPartyDisplayName'].toString()
            : tr('User');
        _headerTitle = match['listingTitle'] ?? '';
      }
    } catch (_) {
      // Leave header blank if it fails — not critical
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final messages = await ApiService.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService.sendMessage(widget.conversationId, text);
      _msgCtrl.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_headerDisplayName.isNotEmpty ? _headerDisplayName : tr('Chat'), style: const TextStyle(fontSize: 15)),
            if (_headerTitle.isNotEmpty)
              Text(_headerTitle, style: const TextStyle(fontSize: 11, color: AppColors.hint)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _messages.isEmpty
                        ? Center(child: Text(tr('No messages yet — say hello!'), style: TextStyle(color: AppColors.hint)))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final m = _messages[i];
                              final isMine = m['isMine'] == true;
                              return Align(
                                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMine)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4, bottom: 2),
                                        child: Text(
                                          m['senderDisplayName']?.toString().trim().isNotEmpty == true ? m['senderDisplayName'].toString() : tr('User'),
                                          style: const TextStyle(color: AppColors.hint, fontSize: 10),
                                        ),
                                      ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                      decoration: BoxDecoration(
                                        color: isMine ? AppColors.primary : AppColors.surface,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(14),
                                          topRight: const Radius.circular(14),
                                          bottomLeft: Radius.circular(isMine ? 14 : 2),
                                          bottomRight: Radius.circular(isMine ? 2 : 14),
                                        ),
                                        border: isMine ? null : Border.all(color: AppColors.border),
                                      ),
                                      child: Text(m['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(hintText: tr('Type a message...')),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
