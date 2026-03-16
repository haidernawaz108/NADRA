import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  List<UserModel> _users = [];
  List<StaffModel> _staff = [];
  List<FeedbackModel> _feedback = [];

  List<UserModel> get users => List.unmodifiable(_users);
  List<StaffModel> get staff => List.unmodifiable(_staff);
  List<FeedbackModel> get feedback => List.unmodifiable(_feedback);

  Future<void> initialize() async {
    await _loadFromAssets();
    await _loadFromPrefs();
  }

  Future<void> _loadFromAssets() async {
    try {
      final String data = await rootBundle.loadString('assets/data/users.json');
      final Map<String, dynamic> jsonData = json.decode(data);

      _users = (jsonData['users'] as List)
          .map((u) => UserModel.fromJson(u))
          .toList();
      _staff = (jsonData['staff'] as List)
          .map((s) => StaffModel.fromJson(s))
          .toList();
      _feedback = (jsonData['feedback'] as List)
          .map((f) => FeedbackModel.fromJson(f))
          .toList();
    } catch (e) {
      print('Error loading assets: $e');
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load additional users saved via app
    final usersJson = prefs.getString('extra_users');
    if (usersJson != null) {
      final List<dynamic> extra = json.decode(usersJson);
      final extraUsers = extra.map((u) => UserModel.fromJson(u)).toList();
      // Merge: update existing or add new
      for (final eu in extraUsers) {
        final idx = _users.indexWhere((u) => u.id == eu.id);
        if (idx >= 0) {
          _users[idx] = eu;
        } else {
          _users.add(eu);
        }
      }
    }

    // Load extra feedback
    final feedbackJson = prefs.getString('extra_feedback');
    if (feedbackJson != null) {
      final List<dynamic> extra = json.decode(feedbackJson);
      _feedback.addAll(extra.map((f) => FeedbackModel.fromJson(f)));
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Save modified/new users
    final modifiedUsers = _users.where((u) => u.id.startsWith('new_') || true).toList();
    await prefs.setString(
        'extra_users', json.encode(modifiedUsers.map((u) => u.toJson()).toList()));
  }

  // ─── CRUD Operations ──────────────────────────────────────

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  UserModel? getUserByCnic(String cnic) {
    try {
      return _users.firstWhere((u) => u.cnic == cnic);
    } catch (_) {
      return null;
    }
  }

  UserModel? getUserByTrackingId(String trackingId) {
    try {
      return _users.firstWhere((u) => u.trackingId == trackingId);
    } catch (_) {
      return null;
    }
  }

  StaffModel? authenticateStaff(String staffId, String password) {
    try {
      return _staff.firstWhere(
          (s) => s.staffId == staffId && s.password == password);
    } catch (_) {
      return null;
    }
  }

  Future<bool> addUser(UserModel user) async {
    try {
      _users.add(user);
      await _saveToPrefs();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateUser(UserModel updated) async {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx < 0) return false;
    _users[idx] = updated;
    await _saveToPrefs();
    return true;
  }

  Future<bool> updateAppStatus(String userId, String newStatus) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx < 0) return false;
    _users[idx].appStatus = newStatus;
    await _saveToPrefs();
    return true;
  }

  Future<bool> addFeedback(FeedbackModel fb) async {
    try {
      _feedback.add(fb);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'extra_feedback',
          json.encode(_feedback.map((f) => f.toJson()).toList()));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Search & Filter ──────────────────────────────────────

  List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return _users;
    final q = query.toLowerCase();
    return _users.where((u) =>
        u.name.toLowerCase().contains(q) ||
        u.cnic.contains(q) ||
        u.city.toLowerCase().contains(q) ||
        u.trackingId.toLowerCase().contains(q)).toList();
  }

  List<UserModel> filterByStatus(String status) {
    if (status == 'All') return _users;
    return _users.where((u) => u.appStatus == status).toList();
  }

  List<UserModel> filterByCity(String city) {
    return _users.where((u) => u.city == city).toList();
  }

  List<UserModel> filterByProvince(String province) {
    return _users.where((u) => u.province == province).toList();
  }

  // ─── Stats ────────────────────────────────────────────────

  Map<String, int> getStatusStats() {
    final Map<String, int> stats = {};
    for (final u in _users) {
      stats[u.appStatus] = (stats[u.appStatus] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> getCityStats() {
    final Map<String, int> stats = {};
    for (final u in _users) {
      stats[u.city] = (stats[u.city] ?? 0) + 1;
    }
    return Map.fromEntries(
        stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  Map<String, int> getProvinceStats() {
    final Map<String, int> stats = {};
    for (final u in _users) {
      stats[u.province] = (stats[u.province] ?? 0) + 1;
    }
    return stats;
  }

  int get totalUsers => _users.length;
  int get activeUsers => _users.where((u) => !u.isExpired).length;
  int get expiredUsers => _users.where((u) => u.isExpired).length;
  int get deliveredCount =>
      _users.where((u) => u.appStatus == 'Delivered').length;
  int get pendingCount =>
      _users.where((u) => u.appStatus == 'Under Review' ||
          u.appStatus == 'Submitted' || u.appStatus == 'Printed').length;

  double get averageFeedbackRating {
    if (_feedback.isEmpty) return 0;
    return _feedback.map((f) => f.rating).reduce((a, b) => a + b) /
        _feedback.length;
  }
}
