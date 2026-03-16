import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../login_screen.dart';
import 'user_detail_screen.dart'; // Fix 7: supervisor can view detail

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic> _stats = {};
  List<UserModel>      _allUsers = [];
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await ApiService().getStats();
      final users = await ApiService().getAllUsers();
      if (!mounted) return;
      setState(() { _stats = stats; _allUsers = users; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load data.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<AuthProvider>().loggedInStaff;
    if (staff == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
            Tab(icon: Icon(Icons.people), text: 'Applications'), // Fix 7
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildAnalyticsTab(),
                    _buildApplicationsTab(), // Fix 7
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: AppTheme.error)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Retry')),
    ]));
  }

  // ─── Tab 1: Analytics ──────────────────────────────────────

  Widget _buildAnalyticsTab() {
    final statusStats   = Map<String, int>.from(_stats['statusStats'] ?? {});
    final cityStats     = Map<String, int>.from(_stats['cityStats'] ?? {});
    final provinceStats = Map<String, int>.from(_stats['provinceStats'] ?? {});
    final double avgRating = (_stats['avgRating'] ?? 0.0).toDouble();
    final int totalFb      = _stats['totalFeedback'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSummaryCards(),
          const SizedBox(height: 20),
          _buildRatingCard(avgRating, totalFb),
          const SizedBox(height: 20),
          _sectionTitle('Application Statuses'),
          const SizedBox(height: 10),
          _buildStatusList(statusStats),
          const SizedBox(height: 20),
          _sectionTitle('City Wise Breakdown (Top 8)'),
          const SizedBox(height: 10),
          _buildCityGrid(cityStats),
          const SizedBox(height: 20),
          _sectionTitle('Province Distribution'),
          const SizedBox(height: 10),
          _buildProvinceDistribution(provinceStats),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  // ─── Tab 2: Applications list (Fix 7) ──────────────────────

  Widget _buildApplicationsTab() {
    if (_allUsers.isEmpty) {
      return const Center(child: Text('No applications found.', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _allUsers.length,
        itemBuilder: (_, i) {
          final user  = _allUsers[i];
          final color = AppConstants.statusColor(user.appStatus);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () async {
                // Fix 7: Supervisor taps to view full application detail
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => UserDetailScreen(userId: user.id)));
                _loadData(); // refresh after returning
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(user.cnic, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('${user.city}, ${user.province}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text(user.appStatus,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
                  ]),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Analytics widgets ────────────────────────────────────

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
      children: [
        _statCard('Total Registered', '${_stats['totalUsers'] ?? 0}',   Icons.people,         AppTheme.primary),
        _statCard('Pending',          '${_stats['pendingCount'] ?? 0}',  Icons.pending_actions,AppTheme.warning),
        _statCard('Delivered',        '${_stats['deliveredCount'] ?? 0}',Icons.local_shipping, AppTheme.success),
        _statCard('Expired',          '${_stats['expiredUsers'] ?? 0}',  Icons.warning_amber,  AppTheme.error),
        _statCard('Awaiting Activation','${_stats['preRegistered'] ?? 0}',Icons.how_to_reg_outlined, AppTheme.info),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildRatingCard(double avg, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF512DA8).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        const Icon(Icons.star_rate_rounded, color: Color(0xFFFFC107), size: 48),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Customer Satisfaction',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Based on $total feedback submission(s)',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(avg.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Text('/ 5.0', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
    ]);
  }

  Widget _buildStatusList(Map<String, int> data) {
    if (data.isEmpty) return const Text('No data', style: TextStyle(color: AppTheme.textSecondary));
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(children: data.entries.map((e) {
        final isLast = e.key == data.keys.last;
        final color  = AppConstants.statusColor(e.key);
        return Column(children: [
          ListTile(
            leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(AppConstants.statusIcon(e.key), color: color, size: 18)),
            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            trailing: Text(e.value.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (!isLast) const Divider(height: 1, indent: 56, endIndent: 16),
        ]);
      }).toList()),
    );
  }

  Widget _buildCityGrid(Map<String, int> data) {
    if (data.isEmpty) return const Text('No location data', style: TextStyle(color: AppTheme.textSecondary));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final entry = data.entries.elementAt(i);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider)),
          child: Row(children: [
            const Icon(Icons.location_city, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(entry.key,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text(entry.value.toString(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ]),
        );
      },
    );
  }

  Widget _buildProvinceDistribution(Map<String, int> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(children: data.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            SizedBox(width: 80, child: Text(e.key, style: const TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: e.value / maxVal,
                minHeight: 8,
                backgroundColor: AppTheme.divider,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            )),
            const SizedBox(width: 12),
            SizedBox(width: 30,
                child: Text(e.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.right)),
          ]),
        );
      }).toList()),
    );
  }
}
