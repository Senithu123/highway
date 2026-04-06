# PayHere Setup

This project now includes PayHere-ready mobile payment scaffolding for a wallet top-up flow.

Official PayHere Flutter SDK docs:
- https://support.payhere.lk/api-%26-mobile-sdk/flutter-sdk

## 1. Create a PayHere account

1. Create or sign in to your PayHere account.
2. For testing, use the Sandbox environment.

Sandbox/testing docs:
- https://support.payhere.lk/sandbox-and-testing

## 2. Whitelist your Android app

In PayHere:

1. Open `Settings > Domains & Credentials`.
2. Click `Add Domain/App`.
3. Choose `App`.
4. Enter this package name:
   `highway.toll`
5. Copy the generated app-specific `Merchant Secret`.
6. Request approval.

PayHere’s Flutter SDK docs say mobile apps must be whitelisted this way before payment requests can work.

## 3. Use these app values at runtime

Run the app with:

```bash
flutter run ^
  --dart-define=PAYHERE_MERCHANT_ID=your_merchant_id ^
  --dart-define=PAYHERE_MERCHANT_SECRET=your_app_merchant_secret ^
  --dart-define=PAYHERE_NOTIFY_URL=https://your-server.example.com/payhere/notify ^
  --dart-define=PAYHERE_SANDBOX=true
```

## 4. What was added in code

- `lib/payhere/payhere_keys.dart`
- `lib/payhere/payhere_payment_service.dart`

Call it like this from any button or flow:

```dart
await PayHerePaymentService.instance.startWalletTopUp(
  orderId: 'TOPUP-1001',
  amountLkr: 1000,
  fullName: 'Student Demo',
  email: 'student@example.com',
  phone: '0771234567',
  address: 'No. 1, Galle Road',
  city: 'Colombo',
);
```

On success, PayHere returns a `paymentId`.

## 5. Test cards for sandbox

PayHere’s sandbox docs provide test cards. Successful examples include:

- Visa: `4916217501611292`
- MasterCard: `5307732125531191`
- AMEX: `346781005510225`

For sandbox, use any valid:
- cardholder name
- expiry date
- CVV

Official source:
- https://support.payhere.lk/sandbox-and-testing

## 6. Important note about payment confirmation

To verify and record the final payment details safely, PayHere says you should provide a backend `notify_url` endpoint that accepts their payment notification POST request.

That means for a proper production flow, your server should:

1. receive the PayHere notify callback
2. verify/store the payment result
3. then update the user wallet balance in Firebase

## 7. Android-specific changes already added

Based on PayHere’s official Flutter SDK docs, this project now includes:

- PayHere Maven repository
- Android manifest merge support for `android:label`

