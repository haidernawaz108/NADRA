import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class ApplyCnicScreen extends StatefulWidget {
  const ApplyCnicScreen({super.key});

  @override
  State<ApplyCnicScreen> createState() => _ApplyCnicScreenState();
}

class _ApplyCnicScreenState extends State<ApplyCnicScreen> {
  final _formKey  = GlobalKey<FormState>();
  int  _step      = 0;
  bool _submitting = false;
  String? _trackingId;
  String? _errorMsg;

  final _nameCtrl    = TextEditingController();
  final _fatherCtrl  = TextEditingController();
  final _dobCtrl     = TextEditingController();
  final _mobileCtrl  = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _profCtrl    = TextEditingController();

  String _gender     = 'Male';
  String _bloodGroup = 'O+';
  String _province   = 'Punjab';
  String _religion   = 'Islam';

  @override
  void dispose() {
    _nameCtrl.dispose();    _fatherCtrl.dispose();
    _dobCtrl.dispose();     _mobileCtrl.dispose();
    _emailCtrl.dispose();   _addressCtrl.dispose();
    _cityCtrl.dispose();    _profCtrl.dispose();
    super.dispose();
  }

  bool _validateStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty)   { _showErr('Full Name is required');     return false; }
      if (_fatherCtrl.text.trim().isEmpty) { _showErr("Father's Name is required"); return false; }
      if (_dobCtrl.text.trim().isEmpty)    { _showErr('Date of Birth is required'); return false; }
    } else if (_step == 1) {
      if (_mobileCtrl.text.trim().isEmpty) { _showErr('Mobile Number is required'); return false; }
      if (_addressCtrl.text.trim().isEmpty){ _showErr('Address is required');       return false; }
      if (_cityCtrl.text.trim().isEmpty)   { _showErr('City is required');          return false; }
    }
    return true;
  }

  void _showErr(String msg) => setState(() => _errorMsg = msg);

  Future<void> _submit() async {
    setState(() { _submitting = true; _errorMsg = null; });

    final tracking = 'TRK-${DateTime.now().year}-'
        '${(DateTime.now().millisecondsSinceEpoch % 9999).toString().padLeft(4, '0')}';

    final payload = {
      'name':            _nameCtrl.text.trim(),
      'father_name':     _fatherCtrl.text.trim(),
      'dob':             _dobCtrl.text.trim(),
      'gender':          _gender,
      'blood_group':     _bloodGroup,
      'address':         _addressCtrl.text.trim(),
      'city':            _cityCtrl.text.trim(),
      'province':        _province,
      'mobile':          _mobileCtrl.text.trim(),
      'email':           _emailCtrl.text.trim(),
      'religion':        _religion,
      'profession':      _profCtrl.text.trim(),
      'status':          'Active',
      'cnic_expiry':     '2034-01-01',
      'app_status':      'Submitted',
      'tracking_id':     tracking,
      'registered_date': DateTime.now().toString().substring(0, 10),
    };

    final result = await ApiService().createUser(payload);

    if (!mounted) return;
    setState(() { _submitting = false; });

    if (result != null) {
      setState(() { _trackingId = result.trackingId; _step = 3; });
    } else {
      setState(() => _errorMsg =
          'Submission failed. Please check your connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for New CNIC')),
      body: _step == 3 ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildStepper(),
        if (_errorMsg != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppTheme.error, fontSize: 12))),
            ]),
          ),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                if (_step == 0) _buildPersonalStep(),
                if (_step == 1) _buildContactStep(),
                if (_step == 2) _buildReviewStep(),
              ]),
            ),
          ),
        ),
        _buildButtons(),
      ],
    );
  }

  Widget _buildStepper() {
    const steps = ['Personal', 'Contact', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: steps.asMap().entries.map((e) {
          final idx = e.key; final label = e.value;
          final isActive = idx == _step; final isDone = idx < _step;
          return Expanded(
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isDone ? AppTheme.success : isActive ? AppTheme.primary : AppTheme.divider,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text('${idx + 1}', style: TextStyle(
                              color: isActive ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppTheme.primary : AppTheme.textSecondary)),
                ]),
              ),
              if (idx < steps.length - 1)
                Container(height: 2, width: 20,
                    color: isDone ? AppTheme.success : AppTheme.divider),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPersonalStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
      const SizedBox(height: 16),
      _field('Full Name', _nameCtrl, Icons.person, required: true),
      _field("Father's Name", _fatherCtrl, Icons.family_restroom, required: true),
      _field('Date of Birth (YYYY-MM-DD)', _dobCtrl, Icons.cake, required: true, hint: 'e.g. 1990-05-15'),
      _dropdownField('Gender', _gender, ['Male', 'Female'], (v) => setState(() => _gender = v!)),
      _dropdownField('Blood Group', _bloodGroup, AppConstants.bloodGroups, (v) => setState(() => _bloodGroup = v!)),
      _dropdownField('Religion', _religion, AppConstants.religions, (v) => setState(() => _religion = v!)),
      _field('Profession', _profCtrl, Icons.work),
    ]);
  }

  Widget _buildContactStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Contact & Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
      const SizedBox(height: 16),
      _field('Mobile Number', _mobileCtrl, Icons.phone, keyboardType: TextInputType.phone, required: true, hint: 'e.g. 0300-1234567'),
      _field('Email Address', _emailCtrl, Icons.email, keyboardType: TextInputType.emailAddress, hint: 'optional'),
      _field('Full Address', _addressCtrl, Icons.home, maxLines: 2, required: true),
      _field('City', _cityCtrl, Icons.location_city, required: true),
      _dropdownField('Province', _province, AppConstants.provinces, (v) => setState(() => _province = v!)),
    ]);
  }

  Widget _buildReviewStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Review & Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
      const SizedBox(height: 16),
      _reviewCard('Personal', {
        'Name': _nameCtrl.text, "Father's Name": _fatherCtrl.text,
        'DOB': _dobCtrl.text, 'Gender': _gender,
        'Blood Group': _bloodGroup, 'Profession': _profCtrl.text,
      }),
      const SizedBox(height: 12),
      _reviewCard('Contact', {
        'Mobile': _mobileCtrl.text, 'Email': _emailCtrl.text,
        'City': _cityCtrl.text, 'Province': _province,
      }),
      const SizedBox(height: 12),
      _reviewCard('Address', {'Full Address': _addressCtrl.text}),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(
            'You will be required to visit the nearest NADRA center for biometric verification.',
            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
          )),
        ]),
      ),
    ]);
  }

  Widget _reviewCard(String title, Map<String, String> data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
        const Divider(height: 12),
        ...data.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 100, child: Text(e.key, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
            Expanded(child: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
        )),
      ]),
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(children: [
        if (_step > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() { _step--; _errorMsg = null; }),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: _submitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: () {
                    setState(() => _errorMsg = null);
                    if (_step < 2) {
                      if (_validateStep()) setState(() => _step++);
                    } else {
                      _submit();
                    }
                  },
                  child: Text(_step == 2 ? 'Submit Application' : 'Next'),
                ),
        ),
      ]),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('Application Submitted!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          const Text(
            'Your CNIC application has been submitted successfully. Please visit the nearest NADRA center for biometric verification.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Column(children: [
              const Text('Your Tracking ID', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(_trackingId ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1)),
              const SizedBox(height: 6),
              const Text('Save this ID to track your application status',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, bool required = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Required field' : null : null,
      ),
    );
  }

  Widget _dropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20),
        ),
      ),
    );
  }
}
