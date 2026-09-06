import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class AdminChatScreen extends StatefulWidget {
  final int orderId;
  const AdminChatScreen({super.key, required this.orderId});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  int? _conversationId;
  List<dynamic> _messages = [];
  bool _loading = true;
  String? _error;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final convId = await ApiService.getMyAdminConversation(widget.orderId);
      _conversationId = convId;
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_conversationId == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final messages = await ApiService.getMyAdminMessages(_conversationId!);
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
    if (_conversationId == null) return;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService.sendMyAdminMessage(_conversationId!, text);
      _msgCtrl.clear();
      await _loadMessages();
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
      appBar: AppBar(title: Text(tr('Chat with Admin'))),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(child: Text(tr('No messages yet. Ask admin any questions here.'), style: TextStyle(color: AppColors.hint)))
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final m = _messages[i];
                              final isAdmin = m['isAdmin'] == true;
                              final isCredential = m['isCredentialShare'] == true;
                              return Align(
                                alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                                child: Column(
                                  crossAxisAlignment: isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                  children: [
                                    if (isAdmin)
                                      Padding(
                                        padding: EdgeInsets.only(left: 4, bottom: 2),
                                        child: Text(tr('Admin'), style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                      decoration: BoxDecoration(
                                        color: isCredential
                                            ? Colors.greenAccent.withOpacity(0.12)
                                            : (isAdmin ? AppColors.surface : AppColors.primary),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(14),
                                          topRight: const Radius.circular(14),
                                          bottomLeft: Radius.circular(isAdmin ? 2 : 14),
                                          bottomRight: Radius.circular(isAdmin ? 14 : 2),
                                        ),
                                        border: isCredential
                                            ? Border.all(color: Colors.greenAccent.withOpacity(0.5))
                                            : (isAdmin ? Border.all(color: AppColors.border) : null),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (isCredential)
                                            Padding(
                                              padding: EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.verified_user, size: 14, color: Colors.greenAccent),
                                                  SizedBox(width: 4),
                                                  Text(tr('Account Credentials'), style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          Text(
                                            m['content'] ?? '',
                                            style: TextStyle(
                                              color: isCredential ? Colors.white : (isAdmin ? Colors.white : Colors.white),
                                              fontSize: 14,
                                              fontFamily: isCredential ? 'monospace' : null,
                                            ),
                                          ),
                                        ],
                                      ),
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
                      decoration: InputDecoration(hintText: tr('Message admin...')),
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
