import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _email = '';
  String? _photoUrl;
  File? _pickedPhoto;
  bool _profileLocked = false;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getProfile();
      _nameCtrl.text = profile['displayName'] ?? '';
      _phoneCtrl.text = profile['phone'] ?? '';
      _email = profile['email'] ?? '';
      _photoUrl = profile['profilePhotoUrl'];
      _profileLocked = profile['profileLocked'] ?? false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    setState(() => _loading = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _pickedPhoto = File(picked.path);
      _uploadingPhoto = true;
    });

    try {
      final url = await ApiService.uploadImage(_pickedPhoto!);
      await ApiService.updateProfilePhoto(url);
      setState(() => _photoUrl = url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Photo updated'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.updateProfile(_nameCtrl.text.trim(), _phoneCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Profile saved. Name and phone are now locked.'))),
      );
      setState(() => _profileLocked = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSupportRequestDialog() {
    final messageCtrl = TextEditingController();
    bool sending = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(tr('Request Profile Change'), style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                tr('Your name and phone number are locked after the first save. ')
                'Describe the change you need and our support team will update it for you.',
                style: TextStyle(color: AppColors.hint, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: tr('e.g. Please change my name to John Silva and phone to 0771234567'),
                  hintStyle: TextStyle(color: AppColors.hint, fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'))),
            ElevatedButton(
              onPressed: sending ? null : () async {
                if (messageCtrl.text.trim().isEmpty) return;
                setDialogState(() => sending = true);
                try {
                  await ApiService.submitSupportRequest('Profile change request', messageCtrl.text.trim());
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('Support request submitted'))),
                  );
                } catch (e) {
                  setDialogState(() => sending = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  );
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Profile Management'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null
                              ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: _uploadingPhoto
                                  ? const SizedBox(
                                      height: 16, width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _nameCtrl,
                    enabled: !_profileLocked,
                    style: TextStyle(color: _profileLocked ? AppColors.hint : Colors.white),
                    decoration: InputDecoration(
                      labelText: tr('Display Name'),
                      suffixIcon: _profileLocked ? const Icon(Icons.lock_outline, color: AppColors.hint, size: 18) : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    enabled: false,
                    style: const TextStyle(color: AppColors.hint),
                    decoration: InputDecoration(labelText: tr('Email'), hintText: _email),
                    controller: TextEditingController(text: _email),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _phoneCtrl,
                    enabled: !_profileLocked,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: _profileLocked ? AppColors.hint : Colors.white),
                    decoration: InputDecoration(
                      labelText: tr('Phone Number'),
                      suffixIcon: _profileLocked ? const Icon(Icons.lock_outline, color: AppColors.hint, size: 18) : null,
                    ),
                  ),

                  if (_profileLocked) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr('Name and phone are locked. Need a change?'),
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                            ),
                          ),
                          TextButton(
                            onPressed: _showSupportRequestDialog,
                            child: Text(tr('Request Change'), style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],

                  if (!_profileLocked) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Text(tr('Save Changes'), style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
