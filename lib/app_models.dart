import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum VehicleCategory {
  motorcycle,
  car,
  van,
  bus,
  truck,
}

extension VehicleCategoryX on VehicleCategory {
  String get key => switch (this) {
        VehicleCategory.motorcycle => 'motorcycle',
        VehicleCategory.car => 'car',
        VehicleCategory.van => 'van',
        VehicleCategory.bus => 'bus',
        VehicleCategory.truck => 'truck',
      };

  String get label => switch (this) {
        VehicleCategory.motorcycle => 'Motorcycle',
        VehicleCategory.car => 'Car',
        VehicleCategory.van => 'Van',
        VehicleCategory.bus => 'Bus',
        VehicleCategory.truck => 'Truck',
      };

  double get multiplier => switch (this) {
        VehicleCategory.motorcycle => 0.70,
        VehicleCategory.car => 1.00,
        VehicleCategory.van => 1.25,
        VehicleCategory.bus => 1.85,
        VehicleCategory.truck => 2.20,
      };
}

VehicleCategory vehicleCategoryFromKey(String? value) {
  return VehicleCategory.values.firstWhere(
    (category) => category.key == value,
    orElse: () => VehicleCategory.car,
  );
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.category,
    required this.nickname,
    required this.createdAt,
  });

  final String id;
  final String plateNumber;
  final VehicleCategory category;
  final String nickname;
  final DateTime createdAt;

  String get displayName =>
      nickname.trim().isEmpty ? plateNumber : '$nickname • $plateNumber';

  Map<String, dynamic> toMap() {
    return {
      'plateNumber': plateNumber,
      'category': category.key,
      'nickname': nickname,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Vehicle.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Vehicle(
      id: doc.id,
      plateNumber: (data['plateNumber'] as String? ?? '').trim(),
      category: vehicleCategoryFromKey(data['category'] as String?),
      nickname: (data['nickname'] as String? ?? '').trim(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

enum PaymentMethodType {
  card,
  wallet,
}

extension PaymentMethodTypeX on PaymentMethodType {
  String get key => switch (this) {
        PaymentMethodType.card => 'card',
        PaymentMethodType.wallet => 'wallet',
      };

  String get label => switch (this) {
        PaymentMethodType.card => 'Card',
        PaymentMethodType.wallet => 'Wallet',
      };
}

PaymentMethodType paymentMethodTypeFromKey(String? value) {
  return PaymentMethodType.values.firstWhere(
    (type) => type.key == value,
    orElse: () => PaymentMethodType.card,
  );
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.details,
    required this.balance,
    required this.createdAt,
  });

  final String id;
  final PaymentMethodType type;
  final String label;
  final String details;
  final double balance;
  final DateTime createdAt;

  String get summary {
    if (type == PaymentMethodType.wallet) {
      return 'Wallet balance: LKR ${balance.toStringAsFixed(2)}';
    }

    return details;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.key,
      'label': label,
      'details': details,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentMethod.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PaymentMethod(
      id: doc.id,
      type: paymentMethodTypeFromKey(data['type'] as String?),
      label: (data['label'] as String? ?? '').trim(),
      details: (data['details'] as String? ?? '').trim(),
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

enum TripStatus {
  active,
  completed,
}

TripStatus tripStatusFromKey(String? value) {
  return TripStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => TripStatus.active,
  );
}

class TollTrip {
  const TollTrip({
    required this.id,
    required this.status,
    required this.entryGate,
    required this.exitGate,
    required this.entryTimestamp,
    required this.exitTimestamp,
    required this.vehicleId,
    required this.vehiclePlateNumber,
    required this.vehicleCategory,
    required this.paymentMethodId,
    required this.paymentMethodType,
    required this.paymentMethodLabel,
    required this.amount,
    required this.receiptNumber,
  });

  final String id;
  final TripStatus status;
  final String entryGate;
  final String? exitGate;
  final DateTime entryTimestamp;
  final DateTime? exitTimestamp;
  final String vehicleId;
  final String vehiclePlateNumber;
  final VehicleCategory vehicleCategory;
  final String paymentMethodId;
  final PaymentMethodType paymentMethodType;
  final String paymentMethodLabel;
  final double amount;
  final String? receiptNumber;

  bool get isActive => status == TripStatus.active;

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'entryGate': entryGate,
      'exitGate': exitGate,
      'entryTimestamp': Timestamp.fromDate(entryTimestamp),
      'exitTimestamp':
          exitTimestamp == null ? null : Timestamp.fromDate(exitTimestamp!),
      'vehicleId': vehicleId,
      'vehiclePlateNumber': vehiclePlateNumber,
      'vehicleCategory': vehicleCategory.key,
      'paymentMethodId': paymentMethodId,
      'paymentMethodType': paymentMethodType.key,
      'paymentMethodLabel': paymentMethodLabel,
      'amount': amount,
      'receiptNumber': receiptNumber,
    };
  }

  factory TollTrip.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return TollTrip(
      id: doc.id,
      status: tripStatusFromKey(data['status'] as String?),
      entryGate: (data['entryGate'] as String? ?? '').trim(),
      exitGate: (data['exitGate'] as String?)?.trim(),
      entryTimestamp:
          (data['entryTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      exitTimestamp: (data['exitTimestamp'] as Timestamp?)?.toDate(),
      vehicleId: (data['vehicleId'] as String? ?? '').trim(),
      vehiclePlateNumber: (data['vehiclePlateNumber'] as String? ?? '').trim(),
      vehicleCategory:
          vehicleCategoryFromKey(data['vehicleCategory'] as String?),
      paymentMethodId: (data['paymentMethodId'] as String? ?? '').trim(),
      paymentMethodType:
          paymentMethodTypeFromKey(data['paymentMethodType'] as String?),
      paymentMethodLabel:
          (data['paymentMethodLabel'] as String? ?? '').trim(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      receiptNumber: (data['receiptNumber'] as String?)?.trim(),
    );
  }
}

class ClientProfile {
  const ClientProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.driverLicenseNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String driverLicenseNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if (phoneNumber.trim().isNotEmpty) {
      return phoneNumber.trim();
    }
    return email;
  }

  String get initials {
    final segments = displayName
        .split(RegExp(r'\s+'))
        .where((segment) => segment.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);

    if (segments.isEmpty) {
      return 'CL';
    }

    return segments
        .map((segment) => segment.trim().substring(0, 1).toUpperCase())
        .join();
  }

  factory ClientProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    User? authUser,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    return ClientProfile(
      uid: (data['uid'] as String? ?? authUser?.uid ?? doc.id).trim(),
      fullName: (data['fullName'] as String? ?? authUser?.displayName ?? '')
          .trim(),
      email: (data['email'] as String? ?? authUser?.email ?? '').trim(),
      phoneNumber:
          (data['phoneNumber'] as String? ?? authUser?.phoneNumber ?? '').trim(),
      driverLicenseNumber: (data['driverLicenseNumber'] as String? ?? '')
          .trim(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
