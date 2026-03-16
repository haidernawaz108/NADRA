import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../login_screen.dart';
import 'users_list_screen.dart';
import 'supervisor_dashboard.dart';

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth        = context.watch<AuthProvider>();
    final isSupervisor = auth.role == UserRole.supervisor;

    final pages = [
      if (isSupervisor)
        const SupervisorDashboard()
      else
        const _ReceptionistDashboard(),
      const UsersListScreen(),
      const _TokenScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withOpacity(0.15),
        destinations: [
          NavigationDestination(
            icon: Icon(isSupervisor ? Icons.dashboard_outlined : Icons.home_outlined),
            selectedIcon: Icon(
                isSupervisor ? Icons.dashboard : Icons.home,
                color: AppTheme.primary),
            label: isSupervisor ? 'Dashboard' : 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppTheme.primary),
            label: 'Citizens',
          ),
          const NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number, color: AppTheme.primary),
            label: 'Tokens',
          ),
        ],
      ),
    );
  }
}

// ─── Receptionist Dashboard ───────────────────────────────────────────────────

class _ReceptionistDashboard extends StatefulWidget {
  const _ReceptionistDashboard();

  @override
  State<_ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<_ReceptionistDashboard> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await ApiService().getStats();
    if (!mounted) return;
    setState(() { _stats = stats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final staff = auth.loggedInStaff!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NADRA - Staff Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Welcome card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(staff.name[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome, ${staff.name}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(staff.role,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  if (staff.deskId != null)
                    Text('Desk: ${staff.deskId}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            const Text('Quick Stats',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),

            _loading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator()))
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _statCard('Total Citizens', '${_stats['totalUsers'] ?? 0}',
                          Icons.people, AppTheme.primary),
                      _statCard('Active CNICs', '${_stats['activeUsers'] ?? 0}',
                          Icons.check_circle, AppTheme.success),
                      _statCard('Expired', '${_stats['expiredUsers'] ?? 0}',
                          Icons.warning, AppTheme.error),
                      _statCard('Pending', '${_stats['pendingCount'] ?? 0}',
                          Icons.hourglass_empty, AppTheme.warning),
                    ],
                  ),
            const SizedBox(height: 20),

            const Text('Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),

            _actionCard(context, 'Search Citizen',
                'Find citizen by CNIC, name or city',
                Icons.search, AppTheme.success, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UsersListScreen()));
            }),
            const SizedBox(height: 8),
            _actionCard(context, 'Generate Token',
                'Create a service token for a citizen',
                Icons.confirmation_number, AppTheme.primary, () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _StandaloneTokenScreen()));
            }),
            const SizedBox(height: 8),
            _actionCard(context, 'View All Applications',
                'Browse and filter citizen applications',
                Icons.folder_open_outlined, AppTheme.info, () {
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const UsersListScreen()));
            }),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _actionCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ]),
      ),
    );
  }
}

// ─── Token Screen (Bottom Nav Tab) ───────────────────────────────────────────

class _TokenScreen extends StatefulWidget {
  const _TokenScreen();

  @override
  State<_TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<_TokenScreen> {
  final _cnicCtrl = TextEditingController();
  Map<String, dynamic>? _tokenData;
  bool _loading = false;

  @override
  void dispose() {
    _cnicCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateToken() async {
    final cnic = _cnicCtrl.text.trim();
    if (cnic.isEmpty) return;
    setState(() { _loading = true; _tokenData = null; });

    final data = await ApiService().generateToken(cnic);

    if (!mounted) return;
    setState(() { _loading = false; _tokenData = data; });

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Citizen not found or server error'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Token')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Enter Citizen CNIC',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              const Text('The token will be saved to the database.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: _cnicCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. 35202-1234567-1',
                  prefixIcon: Icon(Icons.credit_card, color: AppTheme.primary),
                ),
                onSubmitted: (_) => _generateToken(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _generateToken,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.confirmation_number_outlined),
                  label: Text(_loading ? 'Generating...' : 'Generate Token'),
                ),
              ),
            ]),
          ),

          if (_tokenData != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(children: [
                const Icon(Icons.confirmation_number, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text('TOKEN GENERATED',
                    style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(_tokenData!['token'] ?? '',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Text(_tokenData!['userName'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_tokenData!['cnic'] ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.access_time, color: Colors.white60, size: 14),
                  const SizedBox(width: 4),
                  Text('Time: ${_tokenData!['time'] ?? ''}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── Standalone Token Screen (navigated from action card) ─────────────────────
class _StandaloneTokenScreen extends StatelessWidget {
  const _StandaloneTokenScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Token')),
      body: const _TokenScreen(),
    );
  }
}
