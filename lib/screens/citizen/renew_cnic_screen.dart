import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';

class RenewCnicScreen extends StatefulWidget {
  const RenewCnicScreen({super.key});

  @override
  State<RenewCnicScreen> createState() => _RenewCnicScreenState();
}

class _RenewCnicScreenState extends State<RenewCnicScreen> {
  final _mobileCtrl  = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();

  bool    _submitting = false;
  bool    _submitted  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill from logged-in citizen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().loggedInCitizen;
      if (user != null) {
        _mobileCtrl.text  = user.mobile;
        _addressCtrl.text = user.address;
        _emailCtrl.text   = user.email;
      }
    });
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_mobileCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Mobile number is required.');
      return;
    }
    setState(() { _submitting = true; _error = null; });

    final auth = context.read<AuthProvider>();
    final user = auth.loggedInCitizen;
    if (user == null) return;

    final result = await ApiService().updateUser(user.id, {
      'app_status': 'Submitted',
      'mobile':     _mobileCtrl.text.trim(),
      'email':      _emailCtrl.text.trim(),
      'address':    _addressCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result != null) {
      // Refresh citizen data in provider
      await auth.refreshCitizenData();
      setState(() => _submitted = true);
    } else {
      setState(() => _error = 'Renewal failed. Please check your connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Renew CNIC')),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    final user = context.watch<AuthProvider>().loggedInCitizen;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Current info card
        if (user != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Current CNIC Details', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text('CNIC: ${user.cnic}', style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.event, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Text('Expiry: ${user.cnicExpiry}',
                    style: TextStyle(
                        color: user.isExpired ? Colors.redAccent : Colors.white70,
                        fontSize: 12)),
                if (user.isExpired) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(8)),
                    child: const Text('EXPIRED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // Info notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.info.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppTheme.info, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Renewal updates your contact details and re-submits your application. You may update your information below.',
              style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        const Text('Update Contact Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
        const SizedBox(height: 12),

        // Error
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12))),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        TextField(
          controller: _mobileCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Number *',
            hintText: 'e.g. 0300-1234567',
            prefixIcon: Icon(Icons.phone, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'optional',
            prefixIcon: Icon(Icons.email, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Full Address',
            prefixIcon: Icon(Icons.home, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: _submitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Submit Renewal Request'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
        ),
        const SizedBox(height: 12),
        const Text(
          '* After submission, you will be required to visit the nearest NADRA center for biometric verification and fee payment.',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
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
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('Renewal Submitted!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          const Text(
            'Your CNIC renewal request has been submitted successfully.\n\nPlease visit your nearest NADRA center for biometric verification and fee payment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.info.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppTheme.info, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Track your renewal status from the Track Application section.',
                style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              )),
            ]),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
          ),
        ]),
      ),
    );
  }
}
