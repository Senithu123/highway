import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'admin_access.dart';
import 'app_models.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();
  static const Duration _authTimeout = Duration(seconds: 15);
  static const Duration _profileLookupTimeout = Duration(seconds: 12);

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static bool get supportsCurrentPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _ensureReady() {
    if (!supportsCurrentPlatform) {
      throw StateError(
        'Firebase Auth and Firestore are configured for Android in this project right now.',
      );
    }

    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Firebase is not initialized yet. Restart the app after pub get.',
      );
    }
  }

  DocumentReference<Map<String, dynamic>> get _currentUserDoc {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You need to log in first.');
    }

    return _firestore.collection('users').doc(user.uid);
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    _ensureReady();

    if (AdminAccess.matchesCredentials(email: email, password: password)) {
      return signInAdmin();
    }

    return _auth
        .signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        )
        .timeout(
          _authTimeout,
          onTimeout: () => throw StateError(
            'Login is taking too long. Check your connection and try again.',
          ),
        );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    _ensureReady();

    if (AdminAccess.isReservedAdminEmail(email)) {
      throw StateError('That email address is reserved for admin access.');
    }

    return _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        )
        .timeout(
          _authTimeout,
          onTimeout: () => throw StateError(
            'Account creation is taking too long. Check your connection and try again.',
          ),
        );
  }

  Future<UserCredential> signInAdmin() async {
    _ensureReady();

    try {
      return await _auth
          .signInWithEmailAndPassword(
            email: AdminAccess.adminEmail,
            password: AdminAccess.adminPassword,
          )
          .timeout(
            _authTimeout,
            onTimeout: () => throw StateError(
              'Admin login is taking too long. Check your connection and try again.',
            ),
          );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found' &&
          error.code != 'invalid-credential') {
        rethrow;
      }

      return _auth
          .createUserWithEmailAndPassword(
            email: AdminAccess.adminEmail,
            password: AdminAccess.adminPassword,
          )
          .timeout(
            _authTimeout,
            onTimeout: () => throw StateError(
              'Admin login is taking too long. Check your connection and try again.',
            ),
          );
    }
  }

  String normalizePhoneNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StateError('Phone number is required.');
    }

    final cleaned = trimmed.replaceAll(RegExp(r'[\s()-]'), '');
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1).replaceAll(RegExp(r'\D'), '');
      if (digits.length < 9 || digits.length > 15) {
        throw StateError('Enter a valid phone number.');
      }
      return '+$digits';
    }

    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length == 10 && digitsOnly.startsWith('0')) {
      return '+94${digitsOnly.substring(1)}';
    }

    if (digitsOnly.length == 9) {
      return '+94$digitsOnly';
    }

    throw StateError(
      'Enter a valid phone number like 0763300873 or +94763300873.',
    );
  }

  Future<bool> currentUserProfileExists() async {
    _ensureReady();

    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .timeout(
          _profileLookupTimeout,
          onTimeout: () => throw StateError(
            'We signed you in, but could not confirm your profile yet. Check your connection and try again.',
          ),
        );
    return snapshot.exists;
  }

  Future<void> sendCurrentUserEmailVerification() async {
    _ensureReady();

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Create the account before requesting verification.');
    }

    await user.sendEmailVerification();
  }

  Future<void> saveCurrentEmailUserProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String driverLicenseNumber,
  }) async {
    _ensureReady();

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You need to sign up before saving your profile.');
    }

    final snapshot = await _currentUserDoc.get();
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();
    final data = <String, dynamic>{
      'uid': user.uid,
      'fullName': trimmedName,
      'email': trimmedEmail,
      'phoneNumber': normalizePhoneNumber(phoneNumber),
      'driverLicenseNumber': driverLicenseNumber.trim(),
      'authProvider': 'email',
      'lastSignInProvider': 'email',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data.addAll({
        'vehicleCount': 0,
        'paymentMethodCount': 0,
        'tripCount': 0,
        'activeTripCount': 0,
        'completedTripCount': 0,
        'walletBalanceTotal': 0.0,
        'lastTripStatus': null,
        'lastEntryGate': null,
        'lastExitGate': null,
        'lastTripAmount': 0.0,
        'lastTripReceiptNumber': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await _currentUserDoc.set(data, SetOptions(merge: true));

    if (trimmedName.isNotEmpty) {
      await user.updateDisplayName(trimmedName);
    }
    if (trimmedEmail.isNotEmpty && user.email != trimmedEmail) {
      await user.verifyBeforeUpdateEmail(trimmedEmail);
    }
    await user.reload();
  }

  Stream<ClientProfile?> watchCurrentUserProfile() {
    _ensureReady();

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _currentUserDoc.snapshots().map(
      (doc) => ClientProfile.fromDocument(doc, authUser: _auth.currentUser),
    );
  }

  Future<void> updateCurrentUserProfile({
    required String fullName,
    required String phoneNumber,
    required String driverLicenseNumber,
  }) async {
    _ensureReady();

    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You need to log in first.');
    }

    final trimmedName = fullName.trim();
    final snapshot = await _currentUserDoc.get();
    final payload = <String, dynamic>{
      'uid': user.uid,
      'fullName': trimmedName,
      'email': (user.email ?? '').trim(),
      'phoneNumber': normalizePhoneNumber(phoneNumber),
      'driverLicenseNumber': driverLicenseNumber.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await _currentUserDoc.set(payload, SetOptions(merge: true));
    await user.updateDisplayName(trimmedName.isEmpty ? null : trimmedName);
    await user.reload();
  }

  Future<void> signOut() async {
    _ensureReady();
    await _auth.signOut();
  }

  bool _errorContains(Object? value, String needle) {
    return value
            ?.toString()
            .toLowerCase()
            .contains(needle.toLowerCase()) ??
        false;
  }

  String? _messageFromAuthSetupError({
    String? code,
    String? message,
    Object? details,
  }) {
    if (_errorContains(code, 'operation-not-allowed') ||
        _errorContains(message, 'operation-not-allowed')) {
      return 'Email/password sign-in is not enabled in Firebase Authentication yet. Turn on the Email/Password provider in the Firebase console, then try again.';
    }

    if (_errorContains(details, 'channel-error')) {
      return 'A Firebase plugin is not connected in this app session yet. Fully stop the app and run it again.';
    }

    return null;
  }

  String messageFromError(Object error) {
    if (error is FirebaseAuthException) {
      final setupMessage = _messageFromAuthSetupError(
        code: error.code,
        message: error.message,
      );
      if (setupMessage != null) {
        return setupMessage;
      }

      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account already exists with that email.';
        case 'weak-password':
          return 'Use a stronger password with at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
      }

      return error.message ?? 'Authentication failed. Please try again.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore denied this request. Check your Firestore rules.';
        case 'unavailable':
          return 'Firestore is temporarily unavailable. Please try again.';
      }

      return error.message ?? 'Could not save your account details.';
    }

    if (error is PlatformException) {
      final setupMessage = _messageFromAuthSetupError(
        code: error.code,
        message: error.message,
        details: error.details,
      );
      if (setupMessage != null) {
        return setupMessage;
      }
    }

    if (error is StateError) {
      return error.toString().replaceFirst('Bad state: ', '');
    }

    return 'Something went wrong. Please try again.';
  }
}
