import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _api = ApiService();
  UserModel? _user;
  bool  _loading  = true;
  bool  _updating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() { _loading = true; _error = null; });
    final user = await _api.getUserById(widget.userId);
    if (!mounted) return;
    setState(() {
      _user    = user;
      _loading = false;
      if (user == null) _error = 'Failed to load citizen data.';
    });
  }

  Future<void> _changeStatus(String newStatus) async {
    if (_user == null) return;
    setState(() => _updating = true);
    final ok = await _api.updateAppStatus(_user!.id, newStatus);
    if (!mounted) return;
    if (ok) {
      await _loadUser(); // re-fetch updated data
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status updated to "$newStatus"'),
        backgroundColor: AppTheme.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Update failed. Check connection.'),
        backgroundColor: AppTheme.error,
      ));
    }
    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.name ?? 'Citizen Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUser,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null || _user == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
        const SizedBox(height: 12),
        Text(_error ?? 'Unknown error', style: const TextStyle(color: AppTheme.error)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _loadUser, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]));
    }
    final user  = _user!;
    final color = AppConstants.statusColor(user.appStatus);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(user.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(user.cnic,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 4),
              Row(children: [
                if (user.isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppTheme.error, borderRadius: BorderRadius.circular(6)),
                    child: const Text('CNIC EXPIRED',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                if (!user.isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: const Text('CNIC VALID',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ]),
            ])),
          ]),
        ),

        const SizedBox(height: 16),

        // Application status + update
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Application Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(user.appStatus,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 12),
            const Text('Update Status:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            _updating
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['Submitted', 'Under Review', 'Printed', 'Dispatched', 'Delivered']
                        .map((s) {
                      final isCurrentStatus = s == user.appStatus;
                      final btnColor = AppConstants.statusColor(s);
                      return ActionChip(
                        label: Text(s,
                            style: TextStyle(
                                fontSize: 11,
                                color: isCurrentStatus ? Colors.white : btnColor,
                                fontWeight: FontWeight.bold)),
                        backgroundColor: isCurrentStatus ? btnColor : btnColor.withOpacity(0.1),
                        side: BorderSide(color: btnColor.withOpacity(0.3)),
                        onPressed: isCurrentStatus ? null : () => _changeStatus(s),
                        avatar: isCurrentStatus
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      );
                    }).toList(),
                  ),
          ]),
        ),

        const SizedBox(height: 12),

        // Personal Info
        _infoCard('Personal Information', [
          _row(Icons.person,            "Full Name",     user.name),
          _row(Icons.family_restroom,   "Father's Name", user.fatherName),
          _row(Icons.cake_outlined,     "Date of Birth", user.dob),
          _row(Icons.wc_outlined,       "Gender",        user.gender),
          _row(Icons.bloodtype_outlined,"Blood Group",   user.bloodGroup),
          _row(Icons.mosque_outlined,   "Religion",      user.religion),
          _row(Icons.work_outline,      "Profession",    user.profession),
        ]),

        const SizedBox(height: 12),

        // Contact
        _infoCard('Contact & Location', [
          _row(Icons.phone_outlined,         "Mobile",   user.mobile),
          _row(Icons.email_outlined,         "Email",    user.email.isEmpty ? 'N/A' : user.email),
          _row(Icons.home_outlined,          "Address",  user.address),
          _row(Icons.location_city_outlined, "City",     user.city),
          _row(Icons.map_outlined,           "Province", user.province),
        ]),

        const SizedBox(height: 12),

        // CNIC record
        _infoCard('CNIC Record', [
          _row(Icons.credit_card,           "CNIC",           user.cnic),
          _row(Icons.verified_outlined,     "Status",         user.status),
          _row(Icons.event,                 "CNIC Expiry",    user.cnicExpiry),
          _row(Icons.calendar_today,        "Registered",     user.registeredDate),
          _row(Icons.tag,                   "Tracking ID",    user.trackingId),
        ]),

        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
        ),
        const Divider(height: 14, indent: 16, endIndent: 16),
        ...rows,
        const SizedBox(height: 10),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.primary.withOpacity(0.7)),
        const SizedBox(width: 10),
        SizedBox(width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
