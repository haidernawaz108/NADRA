import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

/// Base URL of your XAMPP server.
/// Change to your PC's IP if testing on a physical device.
const String _base = 'http://localhost/nadra_api';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ─── Cached stats for quick access ──────────────────────────
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get cachedStats => _stats;

  // ─── HEADERS ────────────────────────────────────────────────
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ═══════════════════════════════════════════════════════════
  //  STAFF
  // ═══════════════════════════════════════════════════════════

  Future<StaffModel?> authenticateStaff(String staffId, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/staff.php'),
        headers: _headers,
        body: jsonEncode({'staff_id': staffId, 'password': password}),
      );
      if (res.statusCode == 200) {
        return StaffModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<StaffModel>> getAllStaff() async {
    try {
      final res = await http.get(Uri.parse('$_base/staff.php'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => StaffModel.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  USERS — READ
  // ═══════════════════════════════════════════════════════════

  Future<List<UserModel>> getAllUsers({String status = 'All'}) async {
    try {
      final uri = Uri.parse('$_base/users.php').replace(
        queryParameters: status == 'All' ? {} : {'status': status},
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      final res = await http.get(Uri.parse('$_base/users.php?id=$id'));
      if (res.statusCode == 200) return UserModel.fromJson(jsonDecode(res.body));
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getUserByCnic(String cnic) async {
    try {
      final res = await http.get(Uri.parse('$_base/users.php?cnic=${Uri.encodeComponent(cnic)}'));
      if (res.statusCode == 200) return UserModel.fromJson(jsonDecode(res.body));
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getUserByTracking(String tracking) async {
    try {
      final res = await http.get(Uri.parse('$_base/users.php?tracking=${Uri.encodeComponent(tracking)}'));
      if (res.statusCode == 200) return UserModel.fromJson(jsonDecode(res.body));
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<UserModel>> searchUsers(String query, {String status = 'All'}) async {
    try {
      final params = <String, String>{'search': query};
      if (status != 'All') params['status'] = status;
      final uri = Uri.parse('$_base/users.php').replace(queryParameters: params);
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  USERS — WRITE
  // ═══════════════════════════════════════════════════════════

  Future<UserModel?> createUser(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/users.php'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return UserModel.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$_base/users.php?id=$id'),
        headers: _headers,
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) return UserModel.fromJson(jsonDecode(res.body));
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateAppStatus(String userId, String newStatus) async {
    final result = await updateUser(userId, {'app_status': newStatus});
    return result != null;
  }

  // ═══════════════════════════════════════════════════════════
  //  FEEDBACK
  // ═══════════════════════════════════════════════════════════

  Future<List<FeedbackModel>> getAllFeedback() async {
    try {
      final res = await http.get(Uri.parse('$_base/feedback.php'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => FeedbackModel.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addFeedback(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/feedback.php'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  STATS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await http.get(Uri.parse('$_base/stats.php'));
      if (res.statusCode == 200) {
        _stats = jsonDecode(res.body);
        return _stats;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  TOKEN GENERATION
  // ═══════════════════════════════════════════════════════════

  /// [userIdentifier] can be a user ID or CNIC
  Future<Map<String, dynamic>?> generateToken(String userIdentifier) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/stats.php'),
        headers: _headers,
        body: jsonEncode({'user_id': userIdentifier}),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  CONNECTIVITY CHECK
  // ═══════════════════════════════════════════════════════════

  Future<bool> checkConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/stats.php'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
