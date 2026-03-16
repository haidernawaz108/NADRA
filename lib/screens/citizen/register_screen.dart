import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../login_screen.dart';

/// Fix 2: Registration screen (was a stub before).
/// Fix 7: Auto-generates CNIC number.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int  _step       = 0;
  bool _submitting = false;
  String? _errorMsg;
  bool _done = false;
  late String _generatedCnic;
  late String _trackingId;

  final _nameCtrl    = TextEditingController();
  final _fatherCtrl  = TextEditingController();
  final _dobCtrl     = TextEditingController();
  final _mobileCtrl  = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl    = TextEditingController();
  final _profCtrl    = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _gender     = 'Male';
  String _bloodGroup = 'O+';
  String _province   = 'Punjab';
  String _religion   = 'Islam';

  @override
  void initState() {
    super.initState();
    // Fix 7: auto-generate CNIC on screen load
    _generatedCnic = UserModel.generateCnic();
    _trackingId = 'TRK-${DateTime.now().year}-'
        '${(DateTime.now().millisecondsSinceEpoch % 9999).toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _fatherCtrl.dispose(); _dobCtrl.dispose();
    _mobileCtrl.dispose(); _emailCtrl.dispose(); _addressCtrl.dispose();
    _cityCtrl.dispose(); _profCtrl.dispose();
    _passCtrl.dispose(); _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool _validateStep() {
    setState(() => _errorMsg = null);
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty)   { setState(() => _errorMsg = 'Full Name is required');     return false; }
      if (_fatherCtrl.text.trim().isEmpty) { setState(() => _errorMsg = "Father's Name is required"); return false; }
      if (_dobCtrl.text.trim().isEmpty)    { setState(() => _errorMsg = 'Date of Birth is required'); return false; }
    } else if (_step == 1) {
      if (_mobileCtrl.text.trim().isEmpty) { setState(() => _errorMsg = 'Mobile Number is required'); return false; }
      if (_addressCtrl.text.trim().isEmpty){ setState(() => _errorMsg = 'Address is required');       return false; }
      if (_cityCtrl.text.trim().isEmpty)   { setState(() => _errorMsg = 'City is required');          return false; }
    } else if (_step == 2) {
      if (_passCtrl.text.length < 6)       { setState(() => _errorMsg = 'Password must be at least 6 characters'); return false; }
      if (_passCtrl.text != _confirmPassCtrl.text) { setState(() => _errorMsg = 'Passwords do not match'); return false; }
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateStep()) return;
    setState(() { _submitting = true; _errorMsg = null; });

    final newUser = UserModel(
      id:             'new_${DateTime.now().millisecondsSinceEpoch}',
      cnic:           _generatedCnic, // Fix 7: auto-generated
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
      password:       _passCtrl.text,
    );

    final auth = context.read<AuthProvider>();
    final err  = await auth.registerCitizen(newUser);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (err != null) {
      setState(() => _errorMsg = err);
    } else {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Citizen Registration')),
      body: _done ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    const stepLabels = ['Personal', 'Contact', 'Password', 'Review'];
    return Column(children: [
      // Stepper header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.white,
        child: Row(
          children: stepLabels.asMap().entries.map((e) {
            final idx      = e.key;
            final isActive = idx == _step;
            final isDone   = idx < _step;
            return Expanded(
              child: Row(children: [
                Expanded(child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: isDone ? AppTheme.success : isActive ? AppTheme.primary : AppTheme.divider,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : Text('${idx + 1}', style: TextStyle(
                              color: isActive ? Colors.white : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(e.value, style: TextStyle(
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppTheme.primary : AppTheme.textSecondary)),
                ])),
                if (idx < stepLabels.length - 1)
                  Container(height: 2, width: 14,
                      color: isDone ? AppTheme.success : AppTheme.divider),
              ]),
            );
          }).toList(),
        ),
      ),

      // Error banner
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

      // Auto-CNIC banner (Fix 7)
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.credit_card, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Auto-assigned CNIC', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            Text(_generatedCnic,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                    color: AppTheme.primary, letterSpacing: 1)),
          ]),
        ]),
      ),

      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (_step == 0) _buildPersonalStep(),
            if (_step == 1) _buildContactStep(),
            if (_step == 2) _buildPasswordStep(),
            if (_step == 3) _buildReviewStep(),
          ]),
        ),
      ),

      // Navigation buttons
      Container(
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
                      if (_step < 3) {
                        if (_validateStep()) setState(() => _step++);
                      } else {
                        _submit();
                      }
                    },
                    child: Text(_step == 3 ? 'Register' : 'Next'),
                  ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildPersonalStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
      const SizedBox(height: 16),
      _field('Full Name', _nameCtrl, Icons.person, required: true),
      _field("Father's Name", _fatherCtrl, Icons.family_restroom, required: true),
      _field('Date of Birth', _dobCtrl, Icons.cake, required: true, hint: 'YYYY-MM-DD'),
      _dropdown('Gender', _gender, ['Male', 'Female'], (v) => setState(() => _gender = v!)),
      _dropdown('Blood Group', _bloodGroup, AppConstants.bloodGroups, (v) => setState(() => _bloodGroup = v!)),
      _dropdown('Religion', _religion, AppConstants.religions, (v) => setState(() => _religion = v!)),
      _field('Profession', _profCtrl, Icons.work, hint: 'e.g. Engineer'),
    ]);
  }

  Widget _buildContactStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Contact & Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
      const SizedBox(height: 16),
      _field('Mobile Number', _mobileCtrl, Icons.phone, keyboardType: TextInputType.phone, required: true, hint: '0300-1234567'),
      _field('Email Address', _emailCtrl, Icons.email, keyboardType: TextInputType.emailAddress, hint: 'optional'),
      _field('Full Address', _addressCtrl, Icons.home, maxLines: 2, required: true),
      _field('City', _cityCtrl, Icons.location_city, required: true),
      _dropdown('Province', _province, AppConstants.provinces, (v) => setState(() => _province = v!)),
    ]);
  }

  Widget _buildPasswordStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Set Your Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
      const SizedBox(height: 8),
      const Text('You will use this password to login.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      const SizedBox(height: 16),
      _field('Password', _passCtrl, Icons.lock_outline, obscure: true, required: true, hint: 'Min 6 characters'),
      _field('Confirm Password', _confirmPassCtrl, Icons.lock_outline, obscure: true, required: true, hint: 'Re-enter password'),
    ]);
  }

  Widget _buildReviewStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Review & Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
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
      _reviewCard('CNIC (Auto-assigned)', {'CNIC': _generatedCnic, 'Tracking ID': _trackingId}),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
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

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
            child: const Icon(Icons.how_to_reg, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('Registration Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          const Text(
            'Your account has been created. Please save your CNIC and Tracking ID below.',
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
              const Text('Your CNIC Number', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(_generatedCnic,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: AppTheme.primary, letterSpacing: 1)),
              const Divider(height: 20),
              const Text('Tracking ID', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(_trackingId,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              const Text('Use CNIC + your password to login.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false);
            },
            icon: const Icon(Icons.login),
            label: const Text('Go to Login'),
          ),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, bool required = false,
       bool obscure = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
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
