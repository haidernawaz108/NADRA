import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../login_screen.dart';

class CitizenProfile extends StatelessWidget {
  const CitizenProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.loggedInCitizen!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar + name header
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primary.withOpacity(0.15),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(user.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(user.cnic,
                    style: const TextStyle(
                        color: AppTheme.primary, fontSize: 13, letterSpacing: 1, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              _statusBadge(user),
            ]),
          ),

          const SizedBox(height: 24),

          _section('Personal Information', [
            _info('Full Name',    user.name,           Icons.person),
            _info("Father's Name",user.fatherName,     Icons.family_restroom),
            _info('Date of Birth',user.dob,            Icons.cake_outlined),
            _info('Gender',       user.gender,         Icons.wc_outlined),
            _info('Blood Group',  user.bloodGroup,     Icons.bloodtype_outlined),
            _info('Religion',     user.religion,       Icons.mosque_outlined),
            _info('Profession',   user.profession,     Icons.work_outline),
          ]),

          const SizedBox(height: 16),

          _section('Contact Information', [
            _info('Mobile',  user.mobile,  Icons.phone_outlined),
            _info('Email',   user.email.isEmpty ? 'N/A' : user.email, Icons.email_outlined),
            _info('Address', user.address, Icons.home_outlined),
            _info('City',    user.city,    Icons.location_city_outlined),
            _info('Province',user.province,Icons.map_outlined),
          ]),

          const SizedBox(height: 16),

          _section('CNIC Details', [
            _info('CNIC Number',   user.cnic,           Icons.credit_card),
            _info('Status',        user.status,         Icons.verified_outlined),
            _info('Expiry Date',   user.cnicExpiry,     Icons.event),
            _info('Applied On',    user.registeredDate, Icons.calendar_today_outlined),
            _info('Tracking ID',   user.trackingId,     Icons.tag),
            _info('App. Status',   user.appStatus,      Icons.pending_actions_outlined),
          ]),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _statusBadge(UserModel user) {
    final color = AppConstants.statusColor(user.appStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(AppConstants.statusIcon(user.appStatus), color: color, size: 14),
        const SizedBox(width: 6),
        Text(user.appStatus,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
        ),
        const Divider(height: 14, indent: 16, endIndent: 16),
        ...children,
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _info(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.primary.withOpacity(0.7)),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
