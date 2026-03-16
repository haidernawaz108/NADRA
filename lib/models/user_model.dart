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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      cnic: json['cnic'] ?? '',
      name: json['name'] ?? '',
      fatherName: json['fatherName'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      religion: json['religion'] ?? '',
      profession: json['profession'] ?? '',
      status: json['status'] ?? '',
      cnicExpiry: json['cnicExpiry'] ?? '',
      appStatus: json['appStatus'] ?? '',
      trackingId: json['trackingId'] ?? '',
      registeredDate: json['registeredDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cnic': cnic,
      'name': name,
      'fatherName': fatherName,
      'dob': dob,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'city': city,
      'province': province,
      'mobile': mobile,
      'email': email,
      'religion': religion,
      'profession': profession,
      'status': status,
      'cnicExpiry': cnicExpiry,
      'appStatus': appStatus,
      'trackingId': trackingId,
      'registeredDate': registeredDate,
    };
  }

  bool get isExpired {
    final expiry = DateTime.tryParse(cnicExpiry);
    if (expiry == null) return false;
    return expiry.isBefore(DateTime.now());
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

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] ?? '',
      staffId: json['staffId'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      deskId: json['deskId'],
      password: json['password'] ?? '',
    );
  }
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

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'date': date,
      };
}
