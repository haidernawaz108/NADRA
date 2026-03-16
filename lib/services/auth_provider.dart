import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum UserRole { citizen, receptionist, supervisor, officer, none }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  UserModel?  _loggedInCitizen;
  StaffModel? _loggedInStaff;
  UserRole    _role      = UserRole.none;
  bool        _isLoading = false;
  String?     _connectionError;

  UserModel?  get loggedInCitizen    => _loggedInCitizen;
  StaffModel? get loggedInStaff      => _loggedInStaff;
  UserRole    get role               => _role;
  bool        get isLoading          => _isLoading;
  bool        get isLoggedIn         => _role != UserRole.none;
  String?     get connectionError    => _connectionError;

  String get displayName {
    if (_loggedInCitizen != null) return _loggedInCitizen!.name;
    if (_loggedInStaff   != null) return _loggedInStaff!.name;
    return '';
  }

  // ─── Citizen Login ─────────────────────────────────────────
  Future<String?> loginAsCitizen(String cnic) async {
    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      final user = await _api.getUserByCnic(cnic);
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return 'CNIC not found in system. Please register first.';
      }
      _loggedInCitizen = user;
      _role = UserRole.citizen;
    } catch (e) {
      _isLoading = false;
      _connectionError = 'Cannot connect to server. Make sure XAMPP is running.';
      notifyListeners();
      return _connectionError;
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  // ─── Staff Login ───────────────────────────────────────────
  Future<String?> loginAsStaff(String staffId, String password) async {
    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      final staff = await _api.authenticateStaff(staffId, password);
      if (staff == null) {
        _isLoading = false;
        notifyListeners();
        return 'Invalid Staff ID or password.';
      }
      _loggedInStaff = staff;
      switch (staff.role) {
        case 'Receptionist':
          _role = UserRole.receptionist;
          break;
        case 'Supervisor':
          _role = UserRole.supervisor;
          break;
        case 'DataEntryOfficer':
          _role = UserRole.officer;
          break;
        default:
          _role = UserRole.none;
      }
    } catch (e) {
      _isLoading = false;
      _connectionError = 'Cannot connect to server. Make sure XAMPP is running.';
      notifyListeners();
      return _connectionError;
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  // ─── Logout ────────────────────────────────────────────────
  void logout() {
    _loggedInCitizen = null;
    _loggedInStaff   = null;
    _role            = UserRole.none;
    _connectionError = null;
    notifyListeners();
  }

  // ─── Refresh citizen data from server ──────────────────────
  Future<void> refreshCitizenData() async {
    if (_loggedInCitizen == null) return;
    final updated = await _api.getUserById(_loggedInCitizen!.id);
    if (updated != null) {
      _loggedInCitizen = updated;
      notifyListeners();
    }
  }
}
