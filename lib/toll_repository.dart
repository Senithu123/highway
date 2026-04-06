import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_models.dart';
import 'toll_gate_data.dart';

class TollRepository {
  TollRepository._();

  static final TollRepository instance = TollRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();

  static List<String> get tollGates => TollGateCatalog.gateNames;

  CollectionReference<Map<String, dynamic>> get _tollGatesCollection =>
      _firestore.collection('toll_gates');

  DocumentReference<Map<String, dynamic>> get _pricingConfigDoc =>
      _firestore.collection('system_config').doc('toll_pricing');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You need to log in first.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> get _currentUserDoc =>
      _userDoc.doc(_uid);

  CollectionReference<Map<String, dynamic>> get _vehiclesCollection =>
      _currentUserDoc.collection('vehicles');

  CollectionReference<Map<String, dynamic>> get _paymentMethodsCollection =>
      _currentUserDoc.collection('payment_methods');

  CollectionReference<Map<String, dynamic>> get _tripsCollection =>
      _currentUserDoc.collection('trips');

  String get _userEmail => (_auth.currentUser?.email ?? '').trim();

  Future<void> _updateUserSummary(Map<String, dynamic> payload) {
    return _currentUserDoc.set({
      ...payload,
      'uid': _uid,
      'email': _userEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<TollGate>> watchTollGates() {
    return _tollGatesCollection
        .orderBy('kmMarker', descending: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return TollGateCatalog.gates;
      }

      return snapshot.docs
          .map((doc) => TollGate.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    });
  }

  Future<List<TollGate>> fetchTollGates() async {
    final snapshot =
        await _tollGatesCollection.orderBy('kmMarker', descending: false).get();
    if (snapshot.docs.isEmpty) {
      return TollGateCatalog.gates;
    }

    return snapshot.docs
        .map((doc) => TollGate.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  Stream<TollPricingConfig> watchPricingConfig() {
    return _pricingConfigDoc.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null || data.isEmpty) {
        return TollGateCatalog.defaultPricing;
      }
      return TollPricingConfig.fromMap(data);
    });
  }

  Future<TollPricingConfig> fetchPricingConfig() async {
    final snapshot = await _pricingConfigDoc.get();
    final data = snapshot.data();
    if (data == null || data.isEmpty) {
      return TollGateCatalog.defaultPricing;
    }
    return TollPricingConfig.fromMap(data);
  }

  Future<void> seedDefaultTollSystemIfMissing() async {
    final gatesSnapshot = await _tollGatesCollection.limit(1).get();
    if (gatesSnapshot.docs.isEmpty) {
      final batch = _firestore.batch();
      for (final gate in TollGateCatalog.gates) {
        batch.set(_tollGatesCollection.doc(gate.id), gate.toMap());
      }
      await batch.commit();
    }

    final pricingSnapshot = await _pricingConfigDoc.get();
    if (!pricingSnapshot.exists) {
      await _pricingConfigDoc.set(TollGateCatalog.defaultPricing.toMap());
    }
  }

  Future<void> saveTollGate(TollGate gate) async {
    await _tollGatesCollection.doc(gate.id).set(gate.toMap());
  }

  Future<void> deleteTollGate(String gateId) async {
    await _tollGatesCollection.doc(gateId).delete();
  }

  Future<void> savePricingConfig(TollPricingConfig config) async {
    await _pricingConfigDoc.set(config.toMap());
  }

  String buildGateId({
    required String highway,
    required String name,
  }) {
    final slug = name
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final prefix = highway.trim().toUpperCase();
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '$prefix-$slug-$stamp';
  }

  Stream<List<Vehicle>> watchVehicles() {
    return _vehiclesCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(Vehicle.fromDocument).toList(growable: false),
        );
  }

  Future<void> addVehicle({
    required String plateNumber,
    required VehicleCategory category,
    required String nickname,
  }) async {
    final vehicle = Vehicle(
      id: '',
      plateNumber: plateNumber.trim().toUpperCase(),
      category: category,
      nickname: nickname.trim(),
      createdAt: DateTime.now(),
    );

    await _vehiclesCollection.add({
      ...vehicle.toMap(),
      'ownerUid': _uid,
      'ownerEmail': _userEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateUserSummary({
      'vehicleCount': FieldValue.increment(1),
      'lastVehiclePlateNumber': vehicle.plateNumber,
      'lastVehicleCategory': vehicle.category.key,
    });
  }

  Stream<List<PaymentMethod>> watchPaymentMethods() {
    return _paymentMethodsCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PaymentMethod.fromDocument)
              .toList(growable: false),
        );
  }

  Future<void> addPaymentMethod({
    required PaymentMethodType type,
    required String label,
    required String details,
    required double balance,
  }) async {
    final method = PaymentMethod(
      id: '',
      type: type,
      label: label.trim(),
      details: details.trim(),
      balance: balance,
      createdAt: DateTime.now(),
    );

    await _paymentMethodsCollection.add({
      ...method.toMap(),
      'ownerUid': _uid,
      'ownerEmail': _userEmail,
      'updatedAt': FieldValue.serverTimestamp(),
      'isWallet': type == PaymentMethodType.wallet,
    });

    await _updateUserSummary({
      'paymentMethodCount': FieldValue.increment(1),
      'lastPaymentMethodLabel': method.label,
      'lastPaymentMethodType': method.type.key,
      if (type == PaymentMethodType.wallet)
        'walletBalanceTotal': FieldValue.increment(balance),
    });
  }

  Future<PaymentMethod?> fetchPrimaryWallet() async {
    final snapshot = await _paymentMethodsCollection
        .where('isWallet', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return PaymentMethod.fromDocument(snapshot.docs.first);
  }

  Future<void> applyWalletTopUp({
    required double amount,
    required String paymentReference,
    String label = 'PayHere Wallet',
    String details = 'PayHere sandbox top-up',
  }) async {
    if (amount <= 0) {
      throw StateError('Top-up amount must be greater than zero.');
    }

    final existingWallet = await fetchPrimaryWallet();
    final walletDoc = existingWallet == null
        ? _paymentMethodsCollection.doc()
        : _paymentMethodsCollection.doc(existingWallet.id);

    await _firestore.runTransaction((transaction) async {
      if (existingWallet == null) {
        transaction.set(walletDoc, {
          'type': PaymentMethodType.wallet.key,
          'label': label,
          'details': details,
          'balance': amount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'ownerUid': _uid,
          'ownerEmail': _userEmail,
          'isWallet': true,
          'lastTopUpReference': paymentReference,
          'lastTopUpAmount': amount,
        });

        transaction.set(
          _currentUserDoc,
          {
            'uid': _uid,
            'email': _userEmail,
            'paymentMethodCount': FieldValue.increment(1),
            'walletBalanceTotal': FieldValue.increment(amount),
            'lastPaymentMethodLabel': label,
            'lastPaymentMethodType': PaymentMethodType.wallet.key,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }

      transaction.update(walletDoc, {
        'details': details,
        'balance': existingWallet.balance + amount,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastTopUpReference': paymentReference,
        'lastTopUpAmount': amount,
      });

      transaction.set(
        _currentUserDoc,
        {
          'uid': _uid,
          'email': _userEmail,
          'walletBalanceTotal': FieldValue.increment(amount),
          'lastPaymentMethodLabel': existingWallet.label,
          'lastPaymentMethodType': PaymentMethodType.wallet.key,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Stream<List<TollTrip>> watchTrips() {
    return _tripsCollection
        .orderBy('entryTimestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(TollTrip.fromDocument).toList(growable: false),
        );
  }

  Stream<TollTrip?> watchActiveTrip() {
    return _tripsCollection
        .where('status', isEqualTo: TripStatus.active.name)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      return TollTrip.fromDocument(snapshot.docs.first);
    });
  }

  Future<TollTrip?> fetchActiveTrip() async {
    final snapshot = await _tripsCollection
        .where('status', isEqualTo: TripStatus.active.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return TollTrip.fromDocument(snapshot.docs.first);
  }

  String routeKey(String firstGate, String secondGate) {
    final ordered = [firstGate.trim(), secondGate.trim()]..sort();
    return '${ordered.first}|${ordered.last}';
  }

  double calculateFareForConfig({
    required String entryGate,
    required String exitGate,
    required VehicleCategory category,
    required List<TollGate> gates,
    required TollPricingConfig pricing,
  }) {
    if (entryGate == exitGate) {
      throw StateError('Entry gate and exit gate must be different.');
    }

    final entry = TollGateCatalog.byName(entryGate, inList: gates);
    final exit = TollGateCatalog.byName(exitGate, inList: gates);
    if (entry == null || exit == null) {
      throw StateError('Selected toll gate could not be recognized.');
    }

    final distanceKm = (entry.kmMarker - exit.kmMarker).abs();
    final base = (pricing.baseFare + (distanceKm * pricing.pricePerKm))
        .clamp(pricing.minimumFare, 1600)
        .toDouble();
    return double.parse((base * category.multiplier).toStringAsFixed(2));
  }

  Future<double> calculateFare({
    required String entryGate,
    required String exitGate,
    required VehicleCategory category,
  }) async {
    final gates = await fetchTollGates();
    final pricing = await fetchPricingConfig();
    return calculateFareForConfig(
      entryGate: entryGate,
      exitGate: exitGate,
      category: category,
      gates: gates,
      pricing: pricing,
    );
  }

  Future<void> startTrip({
    required String entryGate,
    required Vehicle vehicle,
    required PaymentMethod paymentMethod,
  }) async {
    final existingTrip = await fetchActiveTrip();
    if (existingTrip != null) {
      throw StateError('Finish the active trip before starting another one.');
    }

    final trip = TollTrip(
      id: '',
      status: TripStatus.active,
      entryGate: entryGate,
      exitGate: null,
      entryTimestamp: DateTime.now(),
      exitTimestamp: null,
      vehicleId: vehicle.id,
      vehiclePlateNumber: vehicle.plateNumber,
      vehicleCategory: vehicle.category,
      paymentMethodId: paymentMethod.id,
      paymentMethodType: paymentMethod.type,
      paymentMethodLabel: paymentMethod.label,
      amount: 0,
      receiptNumber: null,
    );

    await _tripsCollection.add({
      ...trip.toMap(),
      'ownerUid': _uid,
      'ownerEmail': _userEmail,
      'routeKey': entryGate.trim(),
      'vehicleNickname': vehicle.nickname,
      'vehicleDisplayName': vehicle.displayName,
      'paymentMethodType': paymentMethod.type.key,
      'paymentMethodDetails': paymentMethod.details,
      'paymentBalanceBeforeTrip': paymentMethod.balance,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateUserSummary({
      'tripCount': FieldValue.increment(1),
      'activeTripCount': FieldValue.increment(1),
      'lastTripStatus': TripStatus.active.name,
      'lastEntryGate': entryGate,
      'lastExitGate': null,
      'lastTripAmount': 0.0,
      'lastTripReceiptNumber': null,
      'lastVehiclePlateNumber': vehicle.plateNumber,
      'lastPaymentMethodLabel': paymentMethod.label,
      'lastTripStartedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<TollTrip> completeTrip({
    required TollTrip trip,
    required String exitGate,
  }) async {
    final amount = await calculateFare(
      entryGate: trip.entryGate,
      exitGate: exitGate,
      category: trip.vehicleCategory,
    );
    final receiptNumber =
        'HTP-${DateTime.now().millisecondsSinceEpoch}-${100 + _random.nextInt(900)}';
    final tripDoc = _tripsCollection.doc(trip.id);
    final paymentDoc = _paymentMethodsCollection.doc(trip.paymentMethodId);

    await _firestore.runTransaction((transaction) async {
      final paymentSnapshot = await transaction.get(paymentDoc);
      final payment = paymentSnapshot.exists
          ? PaymentMethod.fromDocument(paymentSnapshot)
          : null;

      if (payment == null) {
        throw StateError('Selected payment method could not be found.');
      }

      if (payment.type == PaymentMethodType.wallet && payment.balance < amount) {
        throw StateError('Wallet balance is too low for this trip.');
      }

      if (payment.type == PaymentMethodType.wallet) {
        transaction.update(paymentDoc, {
          'balance': payment.balance - amount,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastUsedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.update(paymentDoc, {
          'updatedAt': FieldValue.serverTimestamp(),
          'lastUsedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(tripDoc, {
        'status': TripStatus.completed.name,
        'exitGate': exitGate,
        'exitTimestamp': Timestamp.fromDate(DateTime.now()),
        'amount': amount,
        'receiptNumber': receiptNumber,
        'routeKey': routeKey(trip.entryGate, exitGate),
        'updatedAt': FieldValue.serverTimestamp(),
        'paymentBalanceAfterTrip': payment.type == PaymentMethodType.wallet
            ? payment.balance - amount
            : payment.balance,
      });

      transaction.set(
        _currentUserDoc,
        {
          'uid': _uid,
          'email': _userEmail,
          'activeTripCount': FieldValue.increment(-1),
          'completedTripCount': FieldValue.increment(1),
          'lastTripStatus': TripStatus.completed.name,
          'lastEntryGate': trip.entryGate,
          'lastExitGate': exitGate,
          'lastTripAmount': amount,
          'lastTripReceiptNumber': receiptNumber,
          'lastPaymentMethodLabel': trip.paymentMethodLabel,
          'lastVehiclePlateNumber': trip.vehiclePlateNumber,
          'lastTripCompletedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          if (payment.type == PaymentMethodType.wallet)
            'walletBalanceTotal': FieldValue.increment(-amount),
        },
        SetOptions(merge: true),
      );
    });

    final completed = await tripDoc.get();
    return TollTrip.fromDocument(completed);
  }
}
