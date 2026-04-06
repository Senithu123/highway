import 'package:firebase_auth/firebase_auth.dart';

class AdminAccess {
  AdminAccess._();

  static const String adminEmail = 'admin@gmail.com';
  static const String adminPassword = 'Wssw@2026';

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  static bool matchesCredentials({
    required String email,
    required String password,
  }) {
    return normalizeEmail(email) == normalizeEmail(adminEmail) &&
        password == adminPassword;
  }

  static bool isReservedAdminEmail(String email) {
    return normalizeEmail(email) == normalizeEmail(adminEmail);
  }

  static bool isAdminUser(User? user) {
    final email = user?.email;
    if (email == null) {
      return false;
    }

    return isReservedAdminEmail(email);
  }

  static bool hasAdminAccess(User? user) => isAdminUser(user);
}
