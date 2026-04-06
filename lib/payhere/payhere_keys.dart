class PayHereKeys {
  PayHereKeys._();

  static const bool sandbox = bool.fromEnvironment(
    'PAYHERE_SANDBOX',
    defaultValue: true,
  );

  static const String merchantId = String.fromEnvironment(
    'PAYHERE_MERCHANT_ID',
    defaultValue: '',
  );

  static const String merchantSecret = String.fromEnvironment(
    'PAYHERE_MERCHANT_SECRET',
    defaultValue: '',
  );

  static const String notifyUrl = String.fromEnvironment(
    'PAYHERE_NOTIFY_URL',
    defaultValue: '',
  );

  static bool get isConfigured =>
      merchantId.trim().isNotEmpty && merchantSecret.trim().isNotEmpty;
}
