import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';

/// Staff (receptionist/officer) registers a new citizen.
/// Fills personal details, assigns/generates a CNIC, prints the bay-form slip.
class StaffRegisterCitizenScreen extends StatefulWidget {
  const StaffRegisterCitizenScreen({super.key});
  @override
  State<StaffRegisterCitizenScreen> createState() => _StaffRegisterCitizenScreenState();
}

class _StaffRegisterCitizenScreenState extends State<StaffRegisterCitizenScreen> {
  int  _step      = 0;
  bool _submitting = false;
  bool _done      = false;
  String? _error;

  final _nameCtrl    = TextEditingController();
  final _fatherCtrl  = TextEditingController();
  final _dobCtrl     = TextEditingController();
  final _mobileCtrl  = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _profCtrl    = TextEditingController();
  final _cnicCtrl    = TextEditingController(); // staff can enter or keep auto

  String _gender     = 'Male';
  String _bloodGroup = 'O+';
  String _province   = 'Punjab';
  String _religion   = 'Islam';

  late String _generatedCnic;
  late String _trackingId;
  String _savedName    = '';
  String _savedCnic    = '';
  String _savedTracking = '';

  @override
  void initState() {
    super.initState();
    _regenerateCnic();
  }

  void _regenerateCnic() {
    _generatedCnic = UserModel.generateCnic();
    _cnicCtrl.text = _generatedCnic;
    _trackingId    = 'TRK-${DateTime.now().year}-'
        '${(DateTime.now().millisecondsSinceEpoch % 9999).toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _fatherCtrl.dispose(); _dobCtrl.dispose();
    _mobileCtrl.dispose(); _emailCtrl.dispose(); _addressCtrl.dispose();
    _cityCtrl.dispose(); _profCtrl.dispose(); _cnicCtrl.dispose();
    super.dispose();
  }

  bool _validateStep() {
    setState(() => _error = null);
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty)   { setState(() => _error = 'Full Name is required');     return false; }
      if (_fatherCtrl.text.trim().isEmpty) { setState(() => _error = "Father's Name is required"); return false; }
      if (_dobCtrl.text.trim().isEmpty)    { setState(() => _error = 'Date of Birth is required'); return false; }
      if (_cnicCtrl.text.trim().isEmpty)   { setState(() => _error = 'CNIC Number is required');   return false; }
    } else if (_step == 1) {
      if (_mobileCtrl.text.trim().isEmpty) { setState(() => _error = 'Mobile Number is required'); return false; }
      if (_addressCtrl.text.trim().isEmpty){ setState(() => _error = 'Address is required');       return false; }
      if (_cityCtrl.text.trim().isEmpty)   { setState(() => _error = 'City is required');          return false; }
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });
    final newUser = UserModel(
      id:             'new_${DateTime.now().millisecondsSinceEpoch}',
      cnic:           _cnicCtrl.text.trim(),
      name:           _nameCtrl.text.trim(),
      fatherName:     _fatherCtrl.text.trim(),
      dob:            _dobCtrl.text.trim(),
      gender:         _gender,
      bloodGroup:     _bloodGroup,
      address:        _addressCtrl.text.trim(),
      city:           _cityCtrl.text.trim(),
      province:       _province,
      mobile:         _mobileCtrl.text.trim(),
      email:          _emailCtrl.text.trim(),
      religion:       _religion,
      profession:     _profCtrl.text.trim(),
      status:         'Active',
      cnicExpiry:     '2034-01-01',
      appStatus:      'Submitted',
      trackingId:     _trackingId,
      registeredDate: DateTime.now().toString().substring(0, 10),
      password:       '',               // blank — citizen sets it on activation
      accountStatus:  'pre_registered', // citizen must activate via app
    );

    final auth = context.read<AuthProvider>();
    final err  = await auth.staffRegisterCitizen(newUser);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      _savedName     = _nameCtrl.text.trim();
      _savedCnic     = _cnicCtrl.text.trim();
      _savedTracking = _trackingId;
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Citizen')),
      body: _done ? _buildSlip() : _buildForm(),
    );
  }

  Widget _buildForm() {
    const steps = ['Personal & CNIC', 'Contact', 'Review'];
    return Column(children: [
      // Stepper
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: Colors.white,
        child: Row(children: steps.asMap().entries.map((e) {
          final idx = e.key; final active = idx == _step; final done = idx < _step;
          return Expanded(child: Row(children: [
            Expanded(child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: done ? AppTheme.success : active ? AppTheme.primary : AppTheme.divider,
                  shape: BoxShape.circle),
                child: Center(child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text('${idx+1}', style: TextStyle(
                        color: active ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              const SizedBox(height: 3),
              Text(e.value, style: TextStyle(fontSize: 9,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? AppTheme.primary : AppTheme.textSecondary)),
            ])),
            if (idx < steps.length - 1)
              Container(height: 2, width: 18, color: done ? AppTheme.success : AppTheme.divider),
          ]));
        }).toList()),
      ),

      if (_error != null)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.error.withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12))),
          ]),
        ),

      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (_step == 0) _buildPersonalStep(),
          if (_step == 1) _buildContactStep(),
          if (_step == 2) _buildReviewStep(),
        ]),
      )),

      // Buttons
      Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(children: [
          if (_step > 0) ...[
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() { _step--; _error = null; }),
              child: const Text('Back'),
            )),
            const SizedBox(width: 12),
          ],
          Expanded(flex: 2, child: _submitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: () {
                    if (_step < 2) { if (_validateStep()) setState(() => _step++); }
                    else           { _submit(); }
                  },
                  child: Text(_step == 2 ? 'Register Citizen' : 'Next'),
                )),
        ]),
      ),
    ]);
  }

  Widget _buildPersonalStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Personal Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
      const SizedBox(height: 16),
      _field('Full Name', _nameCtrl, Icons.person, required: true),
      _field("Father's Name", _fatherCtrl, Icons.family_restroom, required: true),
      _field('Date of Birth', _dobCtrl, Icons.cake, required: true, hint: 'YYYY-MM-DD'),
      _dropdown('Gender', _gender, ['Male', 'Female'], (v) => setState(() => _gender = v!)),
      _dropdown('Blood Group', _bloodGroup, AppConstants.bloodGroups, (v) => setState(() => _bloodGroup = v!)),
      _dropdown('Religion', _religion, AppConstants.religions, (v) => setState(() => _religion = v!)),
      _field('Profession', _profCtrl, Icons.work, hint: 'e.g. Engineer'),

      const SizedBox(height: 8),
      // CNIC assignment section
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.credit_card, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Text('CNIC Number Assignment', style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
          ]),
          const SizedBox(height: 4),
          const Text('Auto-generated CNIC below. You may manually override it.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: _cnicCtrl,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\-]'))],
            decoration: InputDecoration(
              labelText: 'CNIC Number',
              hintText: 'XXXXX-XXXXXXX-X',
              prefixIcon: const Icon(Icons.credit_card, color: AppTheme.primary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.autorenew, color: AppTheme.primary),
                tooltip: 'Regenerate CNIC',
                onPressed: () => setState(() => _regenerateCnic()),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildContactStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Contact & Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
      const SizedBox(height: 16),
      _field('Mobile Number', _mobileCtrl, Icons.phone,
          keyboardType: TextInputType.phone, required: true, hint: '0300-1234567'),
      _field('Email Address', _emailCtrl, Icons.email,
          keyboardType: TextInputType.emailAddress, hint: 'optional'),
      _field('Full Address', _addressCtrl, Icons.home, maxLines: 2, required: true),
      _field('City', _cityCtrl, Icons.location_city, required: true),
      _dropdown('Province', _province, AppConstants.provinces, (v) => setState(() => _province = v!)),
    ]);
  }

  Widget _buildReviewStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Review & Confirm',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
      const SizedBox(height: 16),
      _reviewCard('Personal', {
        'Name': _nameCtrl.text, "Father": _fatherCtrl.text,
        'DOB': _dobCtrl.text, 'Gender': _gender, 'Blood Group': _bloodGroup,
      }),
      const SizedBox(height: 10),
      _reviewCard('Contact', {
        'Mobile': _mobileCtrl.text, 'City': _cityCtrl.text, 'Province': _province,
      }),
      const SizedBox(height: 10),

      // Assigned CNIC highlighted
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.credit_card, color: AppTheme.primary, size: 16),
            SizedBox(width: 6),
            Text('Assigned CNIC (Bay-Form)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
          ]),
          const SizedBox(height: 8),
          Text(_cnicCtrl.text.trim(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text('Tracking: $_trackingId',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.warning.withOpacity(0.3))),
        child: const Row(children: [
          Icon(Icons.print_outlined, color: AppTheme.warning, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(
            'After registration, a bay-form slip will be generated. Give it to the citizen so they can activate their account.',
            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
        ]),
      ),
    ]);
  }

  /// The final "slip" screen shown to staff after successful registration
  Widget _buildSlip() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
        ),

        // Invisible circle hack — use Container
        const SizedBox(height: 2),

        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 20),
        const Text('Citizen Registered!', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        const Text('Print the bay-form slip below and hand it to the citizen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),

        // ── Bay-form slip ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Slip header
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('NADRA', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold,
                    fontSize: 14, fontFamily: 'Georgia', letterSpacing: 2)),
              ),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('National Database & Registration Authority',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text('Citizen Registration Bay-Form',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark)),
              ]),
            ]),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: AppTheme.divider)),

            _slipRow('Citizen Name', _savedName),
            const SizedBox(height: 10),

            // Prominent CNIC box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ASSIGNED CNIC NUMBER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: AppTheme.primary, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(_savedCnic, style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark, letterSpacing: 1.5,
                    fontFamily: 'monospace')),
              ]),
            ),
            const SizedBox(height: 12),
            _slipRow('Tracking ID', _savedTracking),
            _slipRow('Registered On', DateTime.now().toString().substring(0, 10)),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(color: AppTheme.divider)),

            // Instructions for citizen
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Instructions for Citizen:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.info)),
                SizedBox(height: 6),
                Text('1. Download the NADRA app or visit the web portal.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                SizedBox(height: 3),
                Text('2. Tap "Activate Account with CNIC" on the login screen.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                SizedBox(height: 3),
                Text('3. Enter the CNIC number above and set your password.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                SizedBox(height: 3),
                Text('4. Use CNIC + password to log in going forward.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Reset and register another
                setState(() {
                  _step = 0; _done = false; _error = null;
                  _nameCtrl.clear(); _fatherCtrl.clear(); _dobCtrl.clear();
                  _mobileCtrl.clear(); _emailCtrl.clear();
                  _addressCtrl.clear(); _cityCtrl.clear(); _profCtrl.clear();
                  _regenerateCnic();
                });
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Register Another'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Done'),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _slipRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
      ]),
    );
  }

  Widget _reviewCard(String title, Map<String, String> data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
        const Divider(height: 12),
        ...data.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 100, child: Text(e.key,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
            Expanded(child: Text(e.value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
        )),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1,
       bool required = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20)),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20)),
      ),
    );
  }
}
