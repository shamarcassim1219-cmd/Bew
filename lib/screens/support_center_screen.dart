import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key, this.openContact = false});
  final bool openContact;

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  List<dynamic> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
    if (widget.openContact) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _newReport(contactAdmin: true);
      });
    }
  }

  Future<void> _loadReports() async {
    try {
      final reports = await ApiService.getMyReports();
      if (mounted) setState(() { _reports = reports; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _title(dynamic r) => '${r is Map ? (r['subject'] ?? r['title'] ?? tr('Support Request')) : tr('Support Request')}';
  String _status(dynamic r) => '${r is Map ? (r['status'] ?? 'open') : 'open'}';

  String _prettyStatus(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress': return tr('In Progress');
      case 'resolved': return tr('Resolved');
      case 'rejected': return tr('Rejected');
      case 'open': return tr('Pending');
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.greenAccent;
      case 'rejected': return Colors.redAccent;
      case 'in_progress': return Colors.orangeAccent;
      default: return Colors.amberAccent;
    }
  }

  Future<void> _newReport({bool contactAdmin = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportFormScreen(contactAdmin: contactAdmin)),
    );
    if (result is int && result > 0) {
      await _loadReports();
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailsScreen(reportId: result)));
    } else if (result == true) {
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Support'))),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _SupportAction(
                    icon: Icons.report_problem_outlined,
                    title: tr('Report a Problem'),
                    subtitle: tr('Tell us about an issue and track the response'),
                    onTap: () => _newReport(),
                  ),
                  const SizedBox(height: 12),
                  _SupportAction(
                    icon: Icons.support_agent_outlined,
                    title: tr('Contact Admin'),
                    subtitle: tr('Chat with our support team'),
                    onTap: () => _newReport(contactAdmin: true),
                  ),
                  const SizedBox(height: 24),
                  Text(tr('My Reports'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_reports.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Icon(Icons.inbox_outlined, size: 42, color: AppColors.hint),
                          const SizedBox(height: 10),
                          Text(tr('No reports yet'), style: const TextStyle(color: AppColors.hint)),
                        ],
                      ),
                    )
                  else
                    ..._reports.map((r) => Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(.15),
                          child: const Icon(Icons.support_outlined, color: AppColors.primary),
                        ),
                        title: Text(_title(r), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${_prettyStatus(_status(r))}${r is Map && r['createdAt'] != null ? ' • ${r['createdAt']}' : ''}',
                          style: TextStyle(color: _statusColor(_status(r)), fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
                        onTap: () {
                          final id = int.tryParse('${r['id'] ?? r['reportId'] ?? 0}') ?? 0;
                          if (id > 0) Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailsScreen(reportId: id)));
                        },
                      ),
                    )),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _newReport(),
        icon: const Icon(Icons.add),
        label: Text(tr('New Report')),
      ),
    );
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Ink(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        CircleAvatar(radius: 24, backgroundColor: AppColors.primary.withOpacity(.14), child: Icon(icon, color: AppColors.primary)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.hint, fontSize: 13)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.hint),
      ]),
    ),
  );
}

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.contactAdmin = false});
  final bool contactAdmin;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  XFile? _image;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.contactAdmin) _subject.text = 'General Support';
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Please complete all required fields'))));
      return;
    }
    setState(() => _saving = true);
    try {
      String? screenshotUrl;
      if (_image != null) screenshotUrl = await ApiService.uploadImage(File(_image!.path));
      final id = await ApiService.createReport(_subject.text.trim(), _message.text.trim(), screenshotUrl: screenshotUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Report submitted successfully'))));
      Navigator.pop(context, id > 0 ? id : true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (mounted && image != null) setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(widget.contactAdmin ? tr('Contact Admin') : tr('Report a Problem'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.contactAdmin ? tr('Contact Admin') : tr('Report a Problem'),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.contactAdmin ? tr('Start a support conversation. You can continue replying here.') : tr('Describe the problem clearly so our team can help you faster.'),
              style: const TextStyle(color: AppColors.hint)),
          const SizedBox(height: 22),
          _field(tr('Subject'), _subject, maxLines: 1),
          const SizedBox(height: 14),
          _field(tr('Description'), _message, maxLines: 7),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: _saving ? null : _pickImage, icon: const Icon(Icons.image_outlined), label: Text(_image == null ? tr('Add Screenshot (Optional)') : tr('Screenshot Selected'))),
          if (_image != null) ...[
            const SizedBox(height: 8),
            Text(_image!.name, style: const TextStyle(color: AppColors.hint)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(tr('Submit')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(labelText: label, alignLabelWithHint: maxLines > 1, border: const OutlineInputBorder()),
  );
}

class ReportDetailsScreen extends StatefulWidget {
  const ReportDetailsScreen({super.key, required this.reportId});
  final int reportId;

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  Map<String, dynamic>? _report;
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;
  final _reply = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final report = await ApiService.getMyReport(widget.reportId);
      if (mounted) setState(() { _report = report; _loading = false; });
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _reply.dispose();
    super.dispose();
  }

  String _status() => '${_report?['status'] ?? 'open'}';
  String _prettyStatus() {
    switch (_status().toLowerCase()) {
      case 'in_progress': return tr('In Progress');
      case 'resolved': return tr('Resolved');
      case 'rejected': return tr('Rejected');
      default: return tr('Pending');
    }
  }

  List<dynamic> _messages() {
    final m = _report?['messages'];
    return m is List ? m : [];
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiService.replyToReport(widget.reportId, text);
      _reply.clear();
      await _load(silent: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Support Chat'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (_report != null) _header(),
              Expanded(
                child: _messages().isEmpty
                    ? Center(child: Text(tr('No messages yet'), style: const TextStyle(color: AppColors.hint)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages().length,
                        itemBuilder: (_, i) {
                          final m = _messages()[i];
                          final mine = !(m is Map && (m['isAdmin'] == true || m['is_admin'] == true));
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: mine ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(mine ? tr('You') : tr('Admin'), style: TextStyle(color: mine ? Colors.white70 : AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${m['content'] ?? m['message'] ?? ''}', style: const TextStyle(color: Colors.white)),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Row(children: [
                    Expanded(child: TextField(
                      controller: _reply,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(hintText: tr('Type a message...'), border: const OutlineInputBorder()),
                      onSubmitted: (_) => _send(),
                    )),
                    const SizedBox(width: 8),
                    IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send, color: AppColors.primary)),
                  ]),
                ),
              ),
            ]),
    );
  }

  Widget _header() {
    final s = _status();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      color: AppColors.surface,
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_report!['subject'] ?? _report!['title'] ?? tr('Support Request')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text('${tr('Status')}: ${_prettyStatus()}', style: TextStyle(color: s == 'resolved' ? Colors.greenAccent : AppColors.hint, fontSize: 12)),
        ])),
        const Icon(Icons.support_agent, color: AppColors.primary),
      ]),
    );
  }
}
