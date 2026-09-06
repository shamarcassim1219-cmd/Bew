import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../localization.dart';
import '../services/api_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _loadingStatus = true;
  String _verifiedStatus = 'not_verified';
  String? _documentType;

  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _nicNumberCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _selectedProvince;
  String? _selectedDistrict;

  String _selectedDocType = 'nic';
  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  bool _submitting = false;
  String? _error;

  static const Map<String, List<String>> _provinceDistricts = {
    'Western': ['Colombo', 'Gampaha', 'Kalutara'],
    'Central': ['Kandy', 'Matale', 'Nuwara Eliya'],
    'Southern': ['Galle', 'Matara', 'Hambantota'],
    'Northern': ['Jaffna', 'Kilinochchi', 'Mannar', 'Vavuniya', 'Mullaitivu'],
    'Eastern': ['Trincomalee', 'Batticaloa', 'Ampara'],
    'North Western': ['Kurunegala', 'Puttalam'],
    'North Central': ['Anuradhapura', 'Polonnaruwa'],
    'Uva': ['Badulla', 'Monaragala'],
    'Sabaragamuwa': ['Ratnapura', 'Kegalle'],
  };

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await ApiService.getVerificationStatusFull();
      setState(() {
        _verifiedStatus = data['verifiedStatus'] ?? 'not_verified';
        _documentType = data['documentType'];
        _loadingStatus = false;
      });
    } catch (e) {
      setState(() => _loadingStatus = false);
    }
  }

  Future<void> _pickImage(String slot) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: slot == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      if (slot == 'front') _frontImage = File(picked.path);
      if (slot == 'back') _backImage = File(picked.path);
      if (slot == 'selfie') _selfieImage = File(picked.path);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvince == null || _selectedDistrict == null) {
      setState(() => _error = 'Please select province and district');
      return;
    }
    if (_frontImage == null || _selfieImage == null) {
      setState(() => _error = 'Please upload the required document photo and a selfie');
      return;
    }
    if (_selectedDocType == 'driving_license' && _backImage == null) {
      setState(() => _error = 'Please upload the back of your driving license');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final frontUrl = await ApiService.uploadImage(_frontImage!);
      String? backUrl;
      if (_backImage != null) {
        backUrl = await ApiService.uploadImage(_backImage!);
      }
      final selfieUrl = await ApiService.uploadImage(_selfieImage!);

      await ApiService.submitVerification(
        fullName: _fullNameCtrl.text.trim(),
        nicNumber: _nicNumberCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        province: _selectedProvince!,
        district: _selectedDistrict!,
        documentType: _selectedDocType,
        frontImageUrl: frontUrl,
        backImageUrl: backUrl,
        selfieImageUrl: selfieUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Verification submitted — pending admin review'))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(tr('Get Verified'))),
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_verifiedStatus == 'pending') {
      return _StatusMessage(
        icon: Icons.hourglass_top_outlined,
        color: Colors.orangeAccent,
        title: 'Verification Pending',
        message: 'Your ${_documentType == 'driving_license' ? 'driving license' : 'NIC'} verification is under review. '
            'This usually takes 1-2 business days.',
      );
    }

    if (_verifiedStatus == 'verified') {
      return _StatusMessage(
        icon: Icons.verified,
        color: AppColors.primary,
        title: 'Verified Seller',
        message: 'Your account is verified. You now have the blue checkmark badge.',
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_verifiedStatus == 'rejected')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('Your previous verification was rejected. Please review your details and submit again.'),
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: AppColors.primary, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(tr('Get the Blue Checkmark'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const _StepLabel('Personal Details'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fullNameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: tr('Full Name (as on document)')),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nicNumberCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: tr('NIC Number')),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: tr('Address')),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedProvince,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: tr('Province')),
            items: _provinceDistricts.keys
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedProvince = v;
              _selectedDistrict = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(labelText: tr('District')),
            items: (_selectedProvince != null ? _provinceDistricts[_selectedProvince]! : <String>[])
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: _selectedProvince == null ? null : (v) => setState(() => _selectedDistrict = v),
          ),

          const SizedBox(height: 24),
          const _StepLabel('Select Document Type'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DocTypeOption(
                  label: tr('NIC'),
                  selected: _selectedDocType == 'nic',
                  onTap: () => setState(() {
                    _selectedDocType = 'nic';
                    _backImage = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DocTypeOption(
                  label: tr('Driving License'),
                  selected: _selectedDocType == 'driving_license',
                  onTap: () => setState(() => _selectedDocType = 'driving_license'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _StepLabel(_selectedDocType == 'nic' ? 'Upload NIC (front)' : 'Upload License (front)'),
          const SizedBox(height: 8),
          _UploadBox(
            image: _frontImage,
            icon: Icons.badge_outlined,
            label: tr('Tap to upload front photo'),
            onTap: () => _pickImage('front'),
          ),

          if (_selectedDocType == 'driving_license') ...[
            const SizedBox(height: 24),
            const _StepLabel('Upload License (back)'),
            const SizedBox(height: 8),
            _UploadBox(
              image: _backImage,
              icon: Icons.badge_outlined,
              label: tr('Tap to upload back photo'),
              onTap: () => _pickImage('back'),
            ),
          ],

          const SizedBox(height: 24),
          const _StepLabel('Take a Selfie'),
          const SizedBox(height: 8),
          _UploadBox(
            image: _selfieImage,
            icon: Icons.camera_alt_outlined,
            label: tr('Tap to take a selfie'),
            onTap: () => _pickImage('selfie'),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(tr('Submit for Review'), style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _StatusMessage({required this.icon, required this.color, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 64),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.hint, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _DocTypeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DocTypeOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.hint, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String text;
  const _StepLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white));
  }
}

class _UploadBox extends StatelessWidget {
  final File? image;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadBox({required this.image, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.fieldFill, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: AppColors.hint),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: AppColors.hint, fontSize: 13)),
                ],
              ),
      ),
    );
  }
}
