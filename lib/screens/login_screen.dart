import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'citizen/citizen_home.dart';
import 'staff/staff_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _cnicCtrl = TextEditingController();
  final _staffIdCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _passVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _cnicCtrl.dispose();
    _staffIdCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginCitizen() async {
    setState(() => _error = null);
    final cnic = _cnicCtrl.text.trim();
    if (cnic.isEmpty) {
      setState(() => _error = 'Please enter your CNIC number.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final err = await auth.loginAsCitizen(cnic);
    if (err != null) {
      setState(() => _error = err);
    } else {
      _navigateHome();
    }
  }

  Future<void> _loginStaff() async {
    setState(() => _error = null);
    final staffId = _staffIdCtrl.text.trim();
    final pass = _passCtrl.text;
    if (staffId.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter Staff ID and Password.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final err = await auth.loginAsStaff(staffId, pass);
    if (err != null) {
      setState(() => _error = err);
    } else {
      _navigateHome();
    }
  }

  void _navigateHome() {
    final auth = context.read<AuthProvider>();
    Widget home;
    if (auth.role == UserRole.citizen) {
      home = const CitizenHome();
    } else {
      home = const StaffHome();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => home),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'NADRA',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to NADRA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Digital Identity Management System',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Card
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Tab bar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabCtrl,
                          indicator: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.textSecondary,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Citizen Login'),
                            Tab(text: 'Staff Login'),
                          ],
                        ),
                      ),

                      // Error message
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppTheme.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: AppTheme.error, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Expanded(
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _buildCitizenLogin(auth.isLoading),
                            _buildStaffLogin(auth.isLoading),
                          ],
                        ),
                      ),

                      // Demo hint
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.info.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.info.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: AppTheme.info, size: 14),
                                  SizedBox(width: 6),
                                  Text('Demo Credentials',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppTheme.info)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                  'Citizen: 35202-1234567-1\nStaff ID: NADRA-R001 | Pass: admin123\nSupervisor: NADRA-S001 | Pass: super123',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCitizenLogin(bool loading) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text('Enter your CNIC',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _cnicCtrl,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              hintText: 'e.g. 35202-1234567-1',
              prefixIcon: Icon(Icons.credit_card, color: AppTheme.primary),
              labelText: 'CNIC Number',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Format: XXXXX-XXXXXXX-X',
            style: TextStyle(
                fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _loginCitizen,
                  icon: const Icon(Icons.login),
                  label: const Text('Login as Citizen'),
                ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Text('New to NADRA? Register Here',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffLogin(bool loading) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text('Staff Credentials',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _staffIdCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. NADRA-R001',
              prefixIcon: Icon(Icons.badge, color: AppTheme.primary),
              labelText: 'Staff ID',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: !_passVisible,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppTheme.primary),
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_passVisible
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _passVisible = !_passVisible),
              ),
            ),
          ),
          const SizedBox(height: 24),
          loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _loginStaff,
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Staff Login'),
                ),
        ],
      ),
    );
  }
}
