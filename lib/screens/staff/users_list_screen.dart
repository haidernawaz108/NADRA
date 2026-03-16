import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import 'user_detail_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _api         = ApiService();
  final _searchCtrl  = TextEditingController();
  String _selectedStatus = 'All';
  List<UserModel> _users  = [];
  bool _loading           = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final users = await _api.getAllUsers(status: _selectedStatus);
      if (!mounted) return;
      setState(() { _users = users; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load data. Check connection.'; _loading = false; });
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      _loadUsers();
      return;
    }
    setState(() => _loading = true);
    final results = await _api.searchUsers(query, status: _selectedStatus);
    if (!mounted) return;
    setState(() { _users = results; _loading = false; });
  }

  Future<void> _onFilterStatus(String status) async {
    setState(() => _selectedStatus = status);
    if (_searchCtrl.text.isNotEmpty) {
      _onSearch(_searchCtrl.text);
    } else {
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Citizens (${_loading ? '...' : _users.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search by name, CNIC, city, tracking ID...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                      onPressed: () {
                        _searchCtrl.clear();
                        _loadUsers();
                      })
                  : null,
            ),
          ),
        ),

        // Status filter chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: AppConstants.appStatuses.map((status) {
              final isSelected = status == _selectedStatus;
              final color = status == 'All'
                  ? AppTheme.primary
                  : AppConstants.statusColor(status);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(status,
                      style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? color : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  onSelected: (_) => _onFilterStatus(status),
                  selectedColor: color.withOpacity(0.15),
                  checkmarkColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? color : AppTheme.divider)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        ),

        // Content
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off, color: AppTheme.error, size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppTheme.error)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _loadUsers, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]));
    }
    if (_users.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.people_outline, color: AppTheme.textSecondary, size: 48),
        const SizedBox(height: 12),
        const Text('No citizens found', style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _users.length,
        itemBuilder: (_, i) => _UserCard(user: _users[i], onStatusChanged: _loadUsers),
      ),
    );
  }
}

// ─── User Card ───────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onStatusChanged;
  const _UserCard({required this.user, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.statusColor(user.appStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => UserDetailScreen(userId: user.id)));
          onStatusChanged(); // Refresh list after returning
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user.cnic,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 2),
                  Text('${user.city}, ${user.province}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(user.appStatus,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Text(user.bloodGroup,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              if (user.isExpired)
                const Icon(Icons.warning_rounded, color: AppTheme.error, size: 16),
            ]),
          ]),
        ),
      ),
    );
  }
}
