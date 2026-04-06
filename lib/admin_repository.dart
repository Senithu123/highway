import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_models.dart';

class AdminRepository {
  AdminRepository._();

  static final AdminRepository instance = AdminRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AdminDashboardData> watchDashboardData({
    Duration refreshInterval = const Duration(seconds: 8),
  }) async* {
    while (true) {
      yield await fetchDashboardData();
      await Future<void>.delayed(refreshInterval);
    }
  }

  Future<AdminDashboardData> fetchDashboardData() async {
    final usersSnapshot = await _getUsersSnapshot();
    final users = usersSnapshot.docs
        .map(AdminUserAccount.fromDocument)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final vehicles = <AdminVehicleRecord>[];
    final trips = <AdminTripRecord>[];

    for (final user in users) {
      final userDoc = _firestore.collection('users').doc(user.uid);

      final vehicleSnapshot = await _getUserVehicles(userDoc.path);
      vehicles.addAll(
        vehicleSnapshot.docs.map(
          (doc) => AdminVehicleRecord(
            userId: user.uid,
            vehicle: Vehicle.fromDocument(doc),
          ),
        ),
      );

      final tripSnapshot = await _getUserTrips(userDoc.path);
      trips.addAll(
        tripSnapshot.docs.map(
          (doc) => AdminTripRecord(
            userId: user.uid,
            trip: TollTrip.fromDocument(doc),
          ),
        ),
      );
    }

    vehicles.sort((a, b) => b.vehicle.createdAt.compareTo(a.vehicle.createdAt));
    trips.sort((a, b) {
      final bTime = b.trip.exitTimestamp ?? b.trip.entryTimestamp;
      final aTime = a.trip.exitTimestamp ?? a.trip.entryTimestamp;
      return bTime.compareTo(aTime);
    });

    return AdminDashboardData(
      users: users,
      vehicles: vehicles,
      trips: trips,
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getUsersSnapshot() async {
    try {
      return await _firestore.collection('users').get();
    } on FirebaseException catch (error) {
      throw StateError('Failed to read /users: ${error.code}');
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getUserVehicles(
    String userDocPath,
  ) async {
    try {
      return await _firestore.collection('$userDocPath/vehicles').get();
    } on FirebaseException catch (error) {
      throw StateError('Failed to read $userDocPath/vehicles: ${error.code}');
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getUserTrips(
    String userDocPath,
  ) async {
    try {
      return await _firestore.collection('$userDocPath/trips').get();
    } on FirebaseException catch (error) {
      throw StateError('Failed to read $userDocPath/trips: ${error.code}');
    }
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.users,
    required this.vehicles,
    required this.trips,
  });

  final List<AdminUserAccount> users;
  final List<AdminVehicleRecord> vehicles;
  final List<AdminTripRecord> trips;
}

class AdminUserAccount {
  const AdminUserAccount({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.driverLicenseNumber,
    required this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String driverLicenseNumber;
  final DateTime createdAt;

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if (phoneNumber.trim().isNotEmpty) {
      return phoneNumber.trim();
    }
    return email;
  }

  factory AdminUserAccount.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AdminUserAccount(
      uid: (data['uid'] as String? ?? doc.id).trim(),
      fullName: (data['fullName'] as String? ?? '').trim(),
      email: (data['email'] as String? ?? '').trim(),
      phoneNumber: (data['phoneNumber'] as String? ?? '').trim(),
      driverLicenseNumber: (data['driverLicenseNumber'] as String? ?? '').trim(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AdminVehicleRecord {
  const AdminVehicleRecord({
    required this.userId,
    required this.vehicle,
  });

  final String userId;
  final Vehicle vehicle;
}

class AdminTripRecord {
  const AdminTripRecord({
    required this.userId,
    required this.trip,
  });

  final String userId;
  final TollTrip trip;
}
