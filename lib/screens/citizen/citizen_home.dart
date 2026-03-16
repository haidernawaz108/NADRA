import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../login_screen.dart';
import 'citizen_profile.dart';
import 'apply_cnic_screen.dart';
import 'track_application_screen.dart';
import 'renew_cnic_screen.dart';
import 'feedback_screen.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _CitizenDashboard(),
    TrackApplicationScreen(),
    CitizenProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.primary),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.track_changes_outlined),
              selectedIcon: Icon(Icons.track_changes, color: AppTheme.primary),
              label: 'Track'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primary),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _CitizenDashboard extends StatelessWidget {
  const _CitizenDashboard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.loggedInCitizen!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NADRA Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildWelcomeCard(user),
          const SizedBox(height: 20),
          _buildStatusCard(user),
          const SizedBox(height: 20),
          const Text('Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          _buildServicesGrid(context, user),
          const SizedBox(height: 20),
          _buildInfoCard(user),
        ]),
      ),
    );
  }

  Widget _buildWelcomeCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(
            user.name.isNotEmpty ? user.name[0] : 'U',
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Assalamu Alaikum', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(user.cnic, style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 0.5)),
          ),
        ])),
        if (user.isExpired)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
            child: const Text('EXPIRED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  Widget _buildStatusCard(UserModel user) {
    final color = AppConstants.statusColor(user.appStatus);
    final icon  = AppConstants.statusIcon(user.appStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          const Text('Application Status',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(user.appStatus,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 10),
        _buildStatusProgress(user.appStatus),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.tag, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text('Tracking: ${user.trackingId}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildStatusProgress(String status) {
    const statuses = ['Submitted', 'Under Review', 'Printed', 'Dispatched', 'Delivered'];
    int currentIdx = statuses.indexOf(status);
    if (currentIdx < 0) currentIdx = 0;
    return Row(
      children: statuses.asMap().entries.map((e) {
        final isCompleted = e.key <= currentIdx && status != 'Expired';
        return Expanded(child: Row(children: [
          Expanded(child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.success : AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          if (e.key < statuses.length - 1) const SizedBox(width: 2),
        ]));
      }).toList(),
    );
  }

  // Fix 3: Already registered citizens should NOT see "Apply New CNIC"
  Widget _buildServicesGrid(BuildContext context, UserModel user) {
    // A citizen is "already registered" if their CNIC is not blank (i.e., they have a record)
    // We hide "Apply New CNIC" and show "Renew CNIC" instead.
    final bool alreadyRegistered = user.cnic.isNotEmpty;

    final services = <Map<String, dynamic>>[
      if (!alreadyRegistered) // Fix 3: only show if not yet registered
        {
          'title': 'Apply New CNIC',
          'icon': Icons.add_card,
          'color': AppTheme.primary,
          'screen': const ApplyCnicScreen(),
        },
      {
        'title': 'Renew CNIC',
        'icon': Icons.refresh_rounded,
        'color': AppTheme.info,
        'screen': const RenewCnicScreen(),
      },
      {
        'title': 'Track Application',
        'icon': Icons.track_changes,
        'color': AppTheme.warning,
        'screen': const TrackApplicationScreen(),
      },
      {
        'title': 'Submit Feedback',
        'icon': Icons.star_rate_rounded,
        'color': AppTheme.accent,
        'screen': const FeedbackScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
      ),
      itemCount: services.length,
      itemBuilder: (_, i) {
        final s     = services[i];
        final color = s['color'] as Color;
        return InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => s['screen'] as Widget)),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(s['icon'] as IconData, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(s['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
          SizedBox(width: 8),
          Text('Personal Info', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ]),
        const Divider(height: 20),
        _infoRow('City',       user.city,       Icons.location_city),
        _infoRow('Province',   user.province,   Icons.map_outlined),
        _infoRow('Blood Group',user.bloodGroup, Icons.bloodtype),
        _infoRow('Profession', user.profession, Icons.work_outline),
        _infoRow('CNIC Expiry',user.cnicExpiry, Icons.event),
      ]),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
