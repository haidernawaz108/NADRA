import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  List<UserModel>     _users    = [];
  List<StaffModel>    _staff    = [];
  List<FeedbackModel> _feedback = [];
  bool _initialized = false;

  List<UserModel>     get users    => List.unmodifiable(_users);
  List<StaffModel>    get staff    => List.unmodifiable(_staff);
  List<FeedbackModel> get feedback => List.unmodifiable(_feedback);

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadFromAssets();
    await _loadFromPrefs();
    _initialized = true;
  }

  // Force reload (used after writes to ensure fresh state)
  Future<void> reload() async {
    _initialized = false;
    _users = []; _staff = []; _feedback = [];
    await initialize();
  }

  Future<void> _loadFromAssets() async {
    try {
      final data = await rootBundle.loadString('data/users.json');
      final json = jsonDecode(data) as Map<String, dynamic>;
      _users    = (json['users']    as List).map((u) => UserModel.fromJson(u)).toList();
      _staff    = (json['staff']    as List).map((s) => StaffModel.fromJson(s)).toList();
      _feedback = (json['feedback'] as List).map((f) => FeedbackModel.fromJson(f)).toList();
    } catch (e) {
      print('Asset load error: $e');
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('extra_users');
    if (usersJson != null) {
      for (final eu in (jsonDecode(usersJson) as List).map((u) => UserModel.fromJson(u))) {
        final idx = _users.indexWhere((u) => u.id == eu.id);
        if (idx >= 0) _users[idx] = eu; else _users.add(eu);
      }
    }
    final fbJson = prefs.getString('extra_feedback');
    if (fbJson != null) {
      _feedback.addAll((jsonDecode(fbJson) as List).map((f) => FeedbackModel.fromJson(f)));
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extra_users', jsonEncode(_users.map((u) => u.toJson()).toList()));
  }

  // ─── Lookup ───────────────────────────────────────────────

  UserModel? getUserById(String id) {
    try { return _users.firstWhere((u) => u.id == id); } catch (_) { return null; }
  }

  UserModel? getUserByCnic(String cnic) {
    try { return _users.firstWhere((u) => u.cnic == cnic); } catch (_) { return null; }
  }

  UserModel? getUserByTrackingId(String id) {
    try { return _users.firstWhere((u) => u.trackingId == id); } catch (_) { return null; }
  }

  StaffModel? authenticateStaff(String staffId, String password) {
    try { return _staff.firstWhere((s) => s.staffId == staffId && s.password == password); }
    catch (_) { return null; }
  }

  // ─── Write ────────────────────────────────────────────────

  Future<bool> addUser(UserModel user) async {
    try { _users.add(user); await _persist(); return true; }
    catch (_) { return false; }
  }

  Future<bool> updateUser(UserModel updated) async {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx < 0) return false;
    _users[idx] = updated;
    await _persist();
    return true;
  }

  Future<bool> updateAppStatus(String userId, String newStatus) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx < 0) return false;
    final o = _users[idx];
    _users[idx] = UserModel(
      id: o.id, cnic: o.cnic, name: o.name, fatherName: o.fatherName,
      dob: o.dob, gender: o.gender, bloodGroup: o.bloodGroup,
      address: o.address, city: o.city, province: o.province,
      mobile: o.mobile, email: o.email, religion: o.religion,
      profession: o.profession, status: o.status, cnicExpiry: o.cnicExpiry,
      appStatus: newStatus, trackingId: o.trackingId,
      registeredDate: o.registeredDate, password: o.password,
      accountStatus: o.accountStatus,
    );
    await _persist();
    return true;
  }

  /// Called when citizen activates account: sets password and marks accountStatus = active
  Future<bool> activateCitizenAccount(String cnic, String password) async {
    final idx = _users.indexWhere((u) => u.cnic == cnic);
    if (idx < 0) return false;
    final o = _users[idx];
    _users[idx] = UserModel(
      id: o.id, cnic: o.cnic, name: o.name, fatherName: o.fatherName,
      dob: o.dob, gender: o.gender, bloodGroup: o.bloodGroup,
      address: o.address, city: o.city, province: o.province,
      mobile: o.mobile, email: o.email, religion: o.religion,
      profession: o.profession, status: o.status, cnicExpiry: o.cnicExpiry,
      appStatus: o.appStatus, trackingId: o.trackingId,
      registeredDate: o.registeredDate, password: password,
      accountStatus: 'active',
    );
    await _persist();
    return true;
  }

  Future<bool> addFeedback(FeedbackModel fb) async {
    try {
      _feedback.add(fb);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('extra_feedback', jsonEncode(_feedback.map((f) => f.toJson()).toList()));
      return true;
    } catch (_) { return false; }
  }

  // ─── Query ────────────────────────────────────────────────

  List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return _users;
    final q = query.toLowerCase();
    return _users.where((u) =>
      u.name.toLowerCase().contains(q) || u.cnic.contains(q) ||
      u.city.toLowerCase().contains(q) || u.trackingId.toLowerCase().contains(q)).toList();
  }

  List<UserModel> filterByStatus(String status) {
    if (status == 'All') return _users;
    return _users.where((u) => u.appStatus == status).toList();
  }

  // ─── Stats ────────────────────────────────────────────────

  Map<String, dynamic> getStats() {
    final statusStats = <String, int>{};
    final cityStats   = <String, int>{};
    final provStats   = <String, int>{};
    for (final u in _users) {
      statusStats[u.appStatus] = (statusStats[u.appStatus] ?? 0) + 1;
      cityStats[u.city]        = (cityStats[u.city] ?? 0) + 1;
      provStats[u.province]    = (provStats[u.province] ?? 0) + 1;
    }
    final sortedCities = Map.fromEntries(
      (cityStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(8));
    final preReg = _users.where((u) => u.isPreRegistered).length;
    final double avgRating = _feedback.isEmpty ? 0.0
        : _feedback.map((f) => f.rating).reduce((a, b) => a + b) / _feedback.length;
    return {
      'totalUsers':     _users.length,
      'activeUsers':    _users.where((u) => !u.isExpired).length,
      'expiredUsers':   _users.where((u) => u.isExpired).length,
      'deliveredCount': _users.where((u) => u.appStatus == 'Delivered').length,
      'pendingCount':   _users.where((u) => ['Under Review','Submitted','Printed'].contains(u.appStatus)).length,
      'preRegistered':  preReg,
      'statusStats':    statusStats,
      'cityStats':      sortedCities,
      'provinceStats':  provStats,
      'avgRating':      avgRating,
      'totalFeedback':  _feedback.length,
    };
  }
}
