import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'database_service.dart';

enum UserRole { citizen, receptionist, supervisor, officer, none }

class AuthProvider extends ChangeNotifier {
  final _db = DatabaseService();

  UserModel?  _loggedInCitizen;
  StaffModel? _loggedInStaff;
  UserRole    _role      = UserRole.none;
  bool        _isLoading = false;

  UserModel?  get loggedInCitizen => _loggedInCitizen;
  StaffModel? get loggedInStaff   => _loggedInStaff;
  UserRole    get role             => _role;
  bool        get isLoading        => _isLoading;
  bool        get isLoggedIn       => _role != UserRole.none;

  String get displayName {
    if (_loggedInCitizen != null) return _loggedInCitizen!.name;
    if (_loggedInStaff   != null) return _loggedInStaff!.name;
    return '';
  }

  // ─── Citizen login (requires CNIC + password, must be activated) ───
  Future<String?> loginAsCitizen(String cnic, String password) async {
    _isLoading = true;
    notifyListeners();
    await _db.initialize();
    final user = _db.getUserByCnic(cnic);
    if (user == null) {
      _isLoading = false; notifyListeners();
      return 'CNIC not registered. Please visit a NADRA office.';
    }
    if (user.isPreRegistered) {
      _isLoading = false; notifyListeners();
      return 'Your account is not activated yet. Use "Activate Account" to set your password first.';
    }
    if (user.password.isEmpty || user.password != password) {
      _isLoading = false; notifyListeners();
      return 'Incorrect password. Please try again.';
    }
    _loggedInCitizen = user;
    _role = UserRole.citizen;
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // ─── Staff login ────────────────────────────────────────────────────
  Future<String?> loginAsStaff(String staffId, String password) async {
    _isLoading = true;
    notifyListeners();
    await _db.initialize();
    final staff = _db.authenticateStaff(staffId, password);
    if (staff == null) {
      _isLoading = false; notifyListeners();
      return 'Invalid Staff ID or password.';
    }
    _loggedInStaff = staff;
    switch (staff.role) {
      case 'Receptionist':     _role = UserRole.receptionist; break;
      case 'Supervisor':       _role = UserRole.supervisor;   break;
      case 'DataEntryOfficer': _role = UserRole.officer;      break;
      default:                 _role = UserRole.none;
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // ─── Citizen registers ────────────────────────────────────────────────
  Future<String?> registerCitizen(UserModel newUser) async {
    await _db.initialize();
    if (_db.getUserByCnic(newUser.cnic) != null) {
      return 'A citizen with this CNIC already exists.';
    }
    final ok = await _db.addUser(newUser);
    return ok ? null : 'Registration failed. Please try again.';
  }

  // ─── Staff registers a new citizen (pre_registered) ─────────────────
  Future<String?> staffRegisterCitizen(UserModel newUser) async {
    await _db.initialize();
    if (_db.getUserByCnic(newUser.cnic) != null) {
      return 'A citizen with this CNIC already exists.';
    }
    final ok = await _db.addUser(newUser);
    return ok ? null : 'Registration failed. Please try again.';
  }

  // ─── Citizen activates account using CNIC from slip + sets password ─
  Future<String?> activateAccount(String cnic, String password) async {
    await _db.initialize();
    final user = _db.getUserByCnic(cnic);
    if (user == null) {
      return 'CNIC not found. Please ensure staff has registered you.';
    }
    if (user.isActivated && user.password.isNotEmpty) {
      return 'This account is already activated. Please login instead.';
    }
    final ok = await _db.activateCitizenAccount(cnic, password);
    return ok ? null : 'Activation failed. Please try again.';
  }

  // ─── Logout ──────────────────────────────────────────────────────────
  void logout() {
    _loggedInCitizen = null;
    _loggedInStaff   = null;
    _role            = UserRole.none;
    notifyListeners();
  }

  // ─── Refresh citizen from DB ─────────────────────────────────────────
  Future<void> refreshCitizenData() async {
    if (_loggedInCitizen == null) return;
    final updated = _db.getUserById(_loggedInCitizen!.id);
    if (updated != null) { _loggedInCitizen = updated; notifyListeners(); }
  }
}
