import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../login_screen.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await ApiService().getStats();
      if (!mounted) return;
      setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load statistics.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<AuthProvider>().loggedInStaff;
    if (staff == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NADRA - Supervisor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppTheme.error)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
            onPressed: _loadStats, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]));
    }

    final statusStats   = Map<String, int>.from(_stats['statusStats'] ?? {});
    final cityStats     = Map<String, int>.from(_stats['cityStats'] ?? {});
    final provinceStats = Map<String, int>.from(_stats['provinceStats'] ?? {});
    final double avgRating = (_stats['avgRating'] ?? 0.0).toDouble();
    final int   totalFb    = _stats['totalFeedback'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header summary
          _buildSummaryCards(),

          const SizedBox(height: 24),

          // Rating card
          _buildRatingCard(avgRating, totalFb),

          const SizedBox(height: 24),

          // Application Status Breakdown
          _sectionTitle('Application Statuses'),
          const SizedBox(height: 12),
          _buildStatusList(statusStats),

          const SizedBox(height: 24),

          // Top Cities
          _sectionTitle('City Wise Breakdown (Top 8)'),
          const SizedBox(height: 12),
          _buildCityGrid(cityStats),

          const SizedBox(height: 24),

          // Provinces
          _sectionTitle('Province Distribution'),
          const SizedBox(height: 12),
          _buildProvinceDistribution(provinceStats),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard('Total Registered', '${_stats['totalUsers'] ?? 0}',
            Icons.people, AppTheme.primary),
        _statCard('Pending Processing', '${_stats['pendingCount'] ?? 0}',
            Icons.pending_actions, AppTheme.warning),
        _statCard('Delivered CNICs', '${_stats['deliveredCount'] ?? 0}',
            Icons.local_shipping, AppTheme.success),
        _statCard('Expired CNICs', '${_stats['expiredUsers'] ?? 0}',
            Icons.warning_amber, AppTheme.error),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
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
        gradient: const LinearGradient(
            colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
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
    if (data.isEmpty) return const Text('No data available', style: TextStyle(color: AppTheme.textSecondary));
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        children: data.entries.map((e) {
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
        }).toList(),
      ),
    );
  }

  Widget _buildCityGrid(Map<String, int> data) {
    if (data.isEmpty) return const Text('No location data available', style: TextStyle(color: AppTheme.textSecondary));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
      ),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final entry = data.entries.elementAt(i);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        children: data.entries.map((e) {
          final max   = data.values.reduce((a, b) => a > b ? a : b);
          final value = e.value;
          final pct   = value / max;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(width: 80, child: Text(e.key, style: const TextStyle(fontSize: 12))),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: AppTheme.divider,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 30,
                  child: Text(value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.right)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}
