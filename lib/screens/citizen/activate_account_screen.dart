import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../services/database_service.dart';
import '../login_screen.dart';

/// Citizen activates their pre-registered account using the CNIC
/// from the bay-form slip given by NADRA office staff.
class ActivateAccountScreen extends StatefulWidget {
  const ActivateAccountScreen({super.key});
  @override
  State<ActivateAccountScreen> createState() => _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends State<ActivateAccountScreen> {
  final _db          = DatabaseService();
  int     _step      = 0;
  bool    _loading   = false;
  bool    _done      = false;
  String? _error;

  final _cnicCtrl    = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _passVisible  = false;
  bool _confVisible  = false;

  String _verifiedCnic = '';
  String _citizenName  = '';

  @override
  void dispose() {
    _cnicCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCnic() async {
    setState(() { _error = null; _loading = true; });
    final cnic = _cnicCtrl.text.trim();
    if (cnic.isEmpty) {
      setState(() { _error = 'Please enter your CNIC number.'; _loading = false; });
      return;
    }
    await _db.initialize();
    final user = _db.getUserByCnic(cnic);

    if (user == null) {
      setState(() {
        _error = 'CNIC not found. Please ensure NADRA staff has registered you first.';
        _loading = false;
      });
      return;
    }
    if (user.isActivated && user.password.isNotEmpty) {
      setState(() {
        _error = 'This account is already activated. Please login with your password.';
        _loading = false;
      });
      return;
    }
    setState(() {
      _verifiedCnic = cnic;
      _citizenName  = user.name;
      _step         = 1;
      _loading      = false;
    });
  }

  Future<void> _activate() async {
    setState(() => _error = null);
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.'); return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.'); return;
    }
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().activateAccount(_verifiedCnic, _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) setState(() => _error = err);
    else setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activate Account')),
      body: _done ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // Header banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(children: [
            Icon(Icons.description_outlined, color: Colors.white, size: 32),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bay-Form Activation', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 4),
              Text('Use the CNIC from your NADRA office slip.',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        // Step indicator
        Row(children: [
          _stepDot(0, 'Verify CNIC'),
          Expanded(child: Container(height: 2,
              color: _step > 0 ? AppTheme.success : AppTheme.divider)),
          _stepDot(1, 'Set Password'),
        ]),
        const SizedBox(height: 24),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.error.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        if (_step == 0) _buildVerifyStep(),
        if (_step == 1) _buildPasswordStep(),
      ]),
    );
  }

  Widget _buildVerifyStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Enter CNIC from your slip', style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      const Text(
        'The NADRA receptionist gave you a bay-form slip. Enter that CNIC number below.',
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      const SizedBox(height: 16),
      TextField(
        controller: _cnicCtrl,
        decoration: const InputDecoration(
          labelText: 'CNIC Number',
          hintText: 'e.g. 35202-1234567-1',
          prefixIcon: Icon(Icons.credit_card, color: AppTheme.primary),
        ),
        onSubmitted: (_) => _verifyCnic(),
      ),
      const SizedBox(height: 6),
      Text('Format: XXXXX-XXXXXXX-X',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.7))),
      const SizedBox(height: 24),
      _loading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton.icon(
              onPressed: _verifyCnic,
              icon: const Icon(Icons.search),
              label: const Text('Verify CNIC'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
    ]);
  }

  Widget _buildPasswordStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Verified citizen card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.verified_outlined, color: AppTheme.success, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('CNIC Verified', style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.success)),
            const SizedBox(height: 2),
            Text(_citizenName, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(_verifiedCnic, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
        ]),
      ),
      const SizedBox(height: 20),

      const Text('Set Your Password', style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      const Text('You will use this password every time you log in.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      const SizedBox(height: 16),

      TextField(
        controller: _passCtrl,
        obscureText: !_passVisible,
        decoration: InputDecoration(
          labelText: 'New Password',
          hintText: 'Minimum 6 characters',
          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
          suffixIcon: IconButton(
            icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _passVisible = !_passVisible),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _confirmCtrl,
        obscureText: !_confVisible,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          hintText: 'Re-enter your password',
          prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppTheme.primary),
          suffixIcon: IconButton(
            icon: Icon(_confVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _confVisible = !_confVisible),
          ),
        ),
      ),
      const SizedBox(height: 24),

      _loading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton.icon(
              onPressed: _activate,
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Activate My Account'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => setState(() { _step = 0; _error = null; }),
        child: const Text('Back'),
      ),
    ]);
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
            child: const Icon(Icons.how_to_reg, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 24),
          const Text('Account Activated!', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Text('Welcome, $_citizenName!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Your NADRA account is now active. You can log in anytime using your CNIC and the password you just set.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
            child: Column(children: [
              const Text('Your CNIC (Login ID)',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(_verifiedCnic, style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold,
                  color: AppTheme.primary, letterSpacing: 1)),
            ]),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false),
            icon: const Icon(Icons.login),
            label: const Text('Go to Login'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
          ),
        ]),
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final done   = _step > step;
    final active = _step == step;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: done ? AppTheme.success : active ? AppTheme.primary : AppTheme.divider,
          shape: BoxShape.circle),
        child: Center(
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text('${step + 1}', style: TextStyle(
                  color: active ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
          fontSize: 10,
          color: active ? AppTheme.primary : AppTheme.textSecondary,
          fontWeight: active ? FontWeight.bold : FontWeight.normal)),
    ]);
  }
}
