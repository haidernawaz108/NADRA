import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_theme.dart';
import 'citizen/citizen_home.dart';
import 'citizen/activate_account_screen.dart'; // NEW
import 'staff/staff_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _cnicCtrl      = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _staffIdCtrl   = TextEditingController();
  final _staffPassCtrl = TextEditingController();
  bool _passVisible      = false;
  bool _staffPassVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabCtrl.dispose(); _cnicCtrl.dispose(); _passCtrl.dispose();
    _staffIdCtrl.dispose(); _staffPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginCitizen() async {
    setState(() => _error = null);
    if (_cnicCtrl.text.trim().isEmpty) { setState(() => _error = 'Please enter your CNIC.'); return; }
    if (_passCtrl.text.isEmpty)        { setState(() => _error = 'Please enter your password.'); return; }
    final err = await context.read<AuthProvider>().loginAsCitizen(_cnicCtrl.text.trim(), _passCtrl.text);
    if (err != null) { setState(() => _error = err); } else { _goHome(); }
  }

  Future<void> _loginStaff() async {
    setState(() => _error = null);
    if (_staffIdCtrl.text.trim().isEmpty || _staffPassCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter Staff ID and Password.'); return;
    }
    final err = await context.read<AuthProvider>().loginAsStaff(_staffIdCtrl.text.trim(), _staffPassCtrl.text);
    if (err != null) { setState(() => _error = err); } else { _goHome(); }
  }

  void _goHome() {
    final auth = context.read<AuthProvider>();
    final home = auth.role == UserRole.citizen ? const CitizenHome() : const StaffHome();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => home));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primaryDark, AppTheme.primary],
              begin: Alignment.topCenter, end: Alignment.center),
        ),
        child: SafeArea(
          child: Column(children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Center(child: Text('NADRA', style: TextStyle(
                      color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Georgia'))),
                ),
                const SizedBox(height: 14),
                const Text('Welcome to NADRA', style: TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
                const SizedBox(height: 4),
                Text('Digital Identity Management System',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ]),
            ),

            // ── Card ──
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: Column(children: [
                  const SizedBox(height: 18),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(14)),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.textSecondary,
                      dividerColor: Colors.transparent,
                      tabs: const [Tab(text: 'Citizen Login'), Tab(text: 'Staff Login')],
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.error.withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!,
                              style: const TextStyle(color: AppTheme.error, fontSize: 12))),
                        ]),
                      ),
                    ),

                  Expanded(child: TabBarView(controller: _tabCtrl, children: [
                    _buildCitizenTab(auth.isLoading),
                    _buildStaffTab(auth.isLoading),
                  ])),

                  // ── Demo hint ──
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.info.withOpacity(0.2))),
                      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.info_outline, color: AppTheme.info, size: 14),
                          SizedBox(width: 6),
                          Text('Demo Credentials', style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.info)),
                        ]),
                        SizedBox(height: 4),
                        Text(
                          'Citizen: 35202-1234567-1  |  Password: nadra1234\n'
                          'Staff (Receptionist): NADRA-R001  |  Pass: admin123\n'
                          'Supervisor: NADRA-S001  |  Pass: super123',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildCitizenTab(bool loading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 4),
        const Text('Enter your CNIC & Password',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        TextField(
          controller: _cnicCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. 35202-1234567-1',
            prefixIcon: Icon(Icons.credit_card, color: AppTheme.primary),
            labelText: 'CNIC Number',
          ),
        ),
        const SizedBox(height: 8),
        Text('Format: XXXXX-XXXXXXX-X',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.7))),
        const SizedBox(height: 12),
        TextField(
          controller: _passCtrl,
          obscureText: !_passVisible,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
            suffixIcon: IconButton(
              icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _passVisible = !_passVisible),
            ),
          ),
        ),
        const SizedBox(height: 20),
        loading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _loginCitizen,
                icon: const Icon(Icons.login),
                label: const Text('Login'),
              ),
        const SizedBox(height: 10),

        // ── "Activate Account" button (replaces old "Register Here") ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.info_outline, color: AppTheme.primary, size: 14),
              SizedBox(width: 6),
              Text('First time here?', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ]),
            const SizedBox(height: 6),
            const Text(
              'Visit your nearest NADRA office. Staff will register you and give you a bay-form slip with your CNIC number.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ActivateAccountScreen())),
                icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                label: const Text('Activate Account with CNIC'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStaffTab(bool loading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 4),
        const Text('Staff Credentials',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
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
          controller: _staffPassCtrl,
          obscureText: !_staffPassVisible,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
            suffixIcon: IconButton(
              icon: Icon(_staffPassVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _staffPassVisible = !_staffPassVisible),
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
      ]),
    );
  }
}
