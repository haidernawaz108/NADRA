import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';

class TrackApplicationScreen extends StatefulWidget {
  const TrackApplicationScreen({super.key});

  @override
  State<TrackApplicationScreen> createState() => _TrackApplicationScreenState();
}

class _TrackApplicationScreenState extends State<TrackApplicationScreen> {
  final _trackingCtrl = TextEditingController();
  UserModel? _result;
  bool _loading  = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with logged-in citizen's tracking ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.loggedInCitizen != null) {
        _trackingCtrl.text = auth.loggedInCitizen!.trackingId;
        _search();
      }
    });
  }

  @override
  void dispose() {
    _trackingCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _trackingCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _notFound = false; _result = null; });
    final user = await ApiService().getUserByTracking(q);
    if (!mounted) return;
    setState(() { _loading = false; _result = user; _notFound = user == null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Application')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Search box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Enter Tracking ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('Format: TRK-YYYY-XXXX', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: _trackingCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'e.g. TRK-2024-0001',
                  prefixIcon: Icon(Icons.track_changes, color: AppTheme.primary),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _search,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                  label: Text(_loading ? 'Searching...' : 'Track Application'),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          if (_notFound)
            _buildNotFound(),

          if (_result != null)
            _buildResult(_result!),
        ]),
      ),
    );
  }

  Widget _buildNotFound() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
      ),
      child: Column(children: [
        const Icon(Icons.search_off, color: AppTheme.error, size: 48),
        const SizedBox(height: 12),
        const Text('Application Not Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.error)),
        const SizedBox(height: 8),
        const Text('No application found with this tracking ID.\nPlease double-check and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResult(UserModel user) {
    const statuses = ['Submitted', 'Under Review', 'Printed', 'Dispatched', 'Delivered'];
    int currentIdx = statuses.indexOf(user.appStatus);
    if (currentIdx < 0) currentIdx = 0;

    final color = AppConstants.statusColor(user.appStatus);

    return Column(children: [
      // Status header card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Icon(AppConstants.statusIcon(user.appStatus), color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(user.appStatus,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Tracking: ${user.trackingId}',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, letterSpacing: 1)),
        ]),
      ),

      const SizedBox(height: 16),

      // Progress bar
      if (user.appStatus != 'Expired')
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Application Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(children: statuses.asMap().entries.map((e) {
              final idx = e.key; final isCompleted = idx <= currentIdx;
              return Expanded(child: Column(children: [
                Row(children: [
                  Expanded(child: Container(height: 4,
                      decoration: BoxDecoration(
                          color: isCompleted ? AppTheme.success : AppTheme.divider,
                          borderRadius: BorderRadius.circular(2)))),
                ]),
                const SizedBox(height: 6),
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? AppTheme.success : AppTheme.divider)),
                const SizedBox(height: 4),
                Text(e.value, style: TextStyle(
                    fontSize: 8,
                    color: isCompleted ? AppTheme.success : AppTheme.textSecondary,
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal),
                    textAlign: TextAlign.center),
              ]));
            }).toList()),
          ]),
        ),

      const SizedBox(height: 12),

      // Applicant details
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Applicant Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
          const Divider(height: 16),
          _row('Name',           user.name),
          _row('CNIC',           user.cnic),
          _row('Mobile',         user.mobile),
          _row('City',           user.city),
          _row('Province',       user.province),
          _row('Applied On',     user.registeredDate),
          _row('CNIC Expiry',    user.cnicExpiry),
        ]),
      ),
    ]);
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
        Expanded(child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
      ]),
    );
  }
}
