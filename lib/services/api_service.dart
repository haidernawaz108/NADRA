import '../models/user_model.dart';
import 'database_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _db = DatabaseService();
  Future<void> _init() => _db.initialize();

  Future<StaffModel?> authenticateStaff(String staffId, String password) async {
    await _init(); return _db.authenticateStaff(staffId, password);
  }

  Future<List<UserModel>> getAllUsers({String status = 'All'}) async {
    await _init(); return _db.filterByStatus(status);
  }

  Future<UserModel?> getUserById(String id) async {
    await _init(); return _db.getUserById(id);
  }

  Future<UserModel?> getUserByCnic(String cnic) async {
    await _init(); return _db.getUserByCnic(cnic);
  }

  Future<UserModel?> getUserByTracking(String tracking) async {
    await _init(); return _db.getUserByTrackingId(tracking);
  }

  Future<List<UserModel>> searchUsers(String query, {String status = 'All'}) async {
    await _init();
    var r = _db.searchUsers(query);
    if (status != 'All') r = r.where((u) => u.appStatus == status).toList();
    return r;
  }

  Future<UserModel?> createUser(Map<String, dynamic> data) async {
    await _init();
    final user = UserModel(
      id:             'new_${DateTime.now().millisecondsSinceEpoch}',
      cnic:           data['cnic'] ?? UserModel.generateCnic(),
      name:           data['name'] ?? '',
      fatherName:     data['father_name'] ?? '',
      dob:            data['dob'] ?? '',
      gender:         data['gender'] ?? 'Male',
      bloodGroup:     data['blood_group'] ?? 'O+',
      address:        data['address'] ?? '',
      city:           data['city'] ?? '',
      province:       data['province'] ?? 'Punjab',
      mobile:         data['mobile'] ?? '',
      email:          data['email'] ?? '',
      religion:       data['religion'] ?? 'Islam',
      profession:     data['profession'] ?? '',
      status:         'Active',
      cnicExpiry:     data['cnic_expiry'] ?? '2034-01-01',
      appStatus:      'Submitted',
      trackingId:     data['tracking_id'] ?? 'TRK-${DateTime.now().year}-${(DateTime.now().millisecondsSinceEpoch % 9999).toString().padLeft(4,'0')}',
      registeredDate: data['registered_date'] ?? DateTime.now().toString().substring(0, 10),
      password:       '',               // blank until citizen activates
      accountStatus:  'pre_registered', // IMPORTANT: staff-created record
    );
    final ok = await _db.addUser(user);
    return ok ? user : null;
  }

  Future<UserModel?> updateUser(String id, Map<String, dynamic> data) async {
    await _init();
    final old = _db.getUserById(id);
    if (old == null) return null;
    final updated = UserModel(
      id: old.id, cnic: data['cnic'] ?? old.cnic,
      name: data['name'] ?? old.name, fatherName: data['father_name'] ?? old.fatherName,
      dob: data['dob'] ?? old.dob, gender: data['gender'] ?? old.gender,
      bloodGroup: data['blood_group'] ?? old.bloodGroup,
      address: data['address'] ?? old.address, city: data['city'] ?? old.city,
      province: data['province'] ?? old.province, mobile: data['mobile'] ?? old.mobile,
      email: data['email'] ?? old.email, religion: data['religion'] ?? old.religion,
      profession: data['profession'] ?? old.profession,
      status: old.status, cnicExpiry: old.cnicExpiry,
      appStatus: data['app_status'] ?? old.appStatus,
      trackingId: old.trackingId, registeredDate: old.registeredDate,
      password: old.password, accountStatus: old.accountStatus,
    );
    return await _db.updateUser(updated) ? updated : null;
  }

  Future<bool> updateAppStatus(String userId, String newStatus) async {
    await _init(); return _db.updateAppStatus(userId, newStatus);
  }

  Future<List<FeedbackModel>> getAllFeedback() async {
    await _init(); return _db.feedback;
  }

  Future<bool> addFeedback(Map<String, dynamic> data) async {
    await _init();
    return _db.addFeedback(FeedbackModel(
      id:      'fb_${DateTime.now().millisecondsSinceEpoch}',
      userId:  data['user_id'] ?? '',
      rating:  data['rating'] is int ? data['rating'] : int.tryParse(data['rating'].toString()) ?? 5,
      comment: data['comment'] ?? '',
      date:    data['date'] ?? DateTime.now().toString().substring(0, 10),
    ));
  }

  Future<Map<String, dynamic>> getStats() async {
    await _init(); return _db.getStats();
  }

  Future<Map<String, dynamic>?> generateToken(String userIdentifier) async {
    await _init();
    UserModel? user = _db.getUserByCnic(userIdentifier) ?? _db.getUserById(userIdentifier);
    if (user == null) return null;
    final now = DateTime.now();
    return {
      'token':    'T${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4,'0')}',
      'userName': user.name,
      'cnic':     user.cnic,
      'time':     '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}',
    };
  }

  Future<bool> checkConnection() async => true;
}
