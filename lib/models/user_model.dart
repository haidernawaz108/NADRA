import 'dart:math';

class UserModel {
  final String id;
  final String cnic;
  final String name;
  final String fatherName;
  final String dob;
  final String gender;
  final String bloodGroup;
  final String address;
  final String city;
  final String province;
  final String mobile;
  final String email;
  final String religion;
  final String profession;
  final String status;
  final String cnicExpiry;
  String appStatus;
  final String trackingId;
  final String registeredDate;
  final String password;
  // NEW: 'pre_registered' = staff created, citizen hasn't activated yet
  // 'active' = citizen has set password and activated
  final String accountStatus;

  UserModel({
    required this.id,
    required this.cnic,
    required this.name,
    required this.fatherName,
    required this.dob,
    required this.gender,
    required this.bloodGroup,
    required this.address,
    required this.city,
    required this.province,
    required this.mobile,
    required this.email,
    required this.religion,
    required this.profession,
    required this.status,
    required this.cnicExpiry,
    required this.appStatus,
    required this.trackingId,
    required this.registeredDate,
    this.password = '',
    this.accountStatus = 'active', // seed data is already active
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:             json['id'] ?? '',
      cnic:           json['cnic'] ?? '',
      name:           json['name'] ?? '',
      fatherName:     json['fatherName'] ?? '',
      dob:            json['dob'] ?? '',
      gender:         json['gender'] ?? '',
      bloodGroup:     json['bloodGroup'] ?? '',
      address:        json['address'] ?? '',
      city:           json['city'] ?? '',
      province:       json['province'] ?? '',
      mobile:         json['mobile'] ?? '',
      email:          json['email'] ?? '',
      religion:       json['religion'] ?? '',
      profession:     json['profession'] ?? '',
      status:         json['status'] ?? '',
      cnicExpiry:     json['cnicExpiry'] ?? '',
      appStatus:      json['appStatus'] ?? '',
      trackingId:     json['trackingId'] ?? '',
      registeredDate: json['registeredDate'] ?? '',
      password:       json['password'] ?? 'nadra1234',
      accountStatus:  json['accountStatus'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'cnic':           cnic,
    'name':           name,
    'fatherName':     fatherName,
    'dob':            dob,
    'gender':         gender,
    'bloodGroup':     bloodGroup,
    'address':        address,
    'city':           city,
    'province':       province,
    'mobile':         mobile,
    'email':          email,
    'religion':       religion,
    'profession':     profession,
    'status':         status,
    'cnicExpiry':     cnicExpiry,
    'appStatus':      appStatus,
    'trackingId':     trackingId,
    'registeredDate': registeredDate,
    'password':       password,
    'accountStatus':  accountStatus,
  };

  bool get isExpired {
    final expiry = DateTime.tryParse(cnicExpiry);
    if (expiry == null) return false;
    return expiry.isBefore(DateTime.now());
  }

  bool get isPreRegistered => accountStatus == 'pre_registered';
  bool get isActivated      => accountStatus == 'active';

  // Generate a valid Pakistani-format CNIC: XXXXX-XXXXXXX-X
  static String generateCnic() {
    final rng = Random();
    const districts = [
      '35202','42101','37405','35201','42301','38401','41201',
      '34501','35401','42201','38101','36101','42501','34201','35501',
    ];
    final district = districts[rng.nextInt(districts.length)];
    final personal  = (rng.nextInt(9000000) + 1000000).toString();
    final check     = (rng.nextInt(9) + 1).toString();
    return '$district-$personal-$check';
  }
}

class StaffModel {
  final String id;
  final String staffId;
  final String name;
  final String role;
  final String? deskId;
  final String password;

  StaffModel({
    required this.id,
    required this.staffId,
    required this.name,
    required this.role,
    this.deskId,
    required this.password,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
    id:       json['id'] ?? '',
    staffId:  json['staffId'] ?? '',
    name:     json['name'] ?? '',
    role:     json['role'] ?? '',
    deskId:   json['deskId'],
    password: json['password'] ?? '',
  );
}

class FeedbackModel {
  final String id;
  final String userId;
  final int rating;
  final String comment;
  final String date;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel(
    id:      json['id'] ?? '',
    userId:  json['userId'] ?? '',
    rating:  json['rating'] ?? 0,
    comment: json['comment'] ?? '',
    date:    json['date'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id':      id,
    'userId':  userId,
    'rating':  rating,
    'comment': comment,
    'date':    date,
  };
}
