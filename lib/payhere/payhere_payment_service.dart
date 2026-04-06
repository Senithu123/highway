import 'dart:async';

import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

import 'payhere_keys.dart';

class PayHerePaymentService {
  PayHerePaymentService._();

  static final PayHerePaymentService instance = PayHerePaymentService._();

  Future<String> startWalletTopUp({
    required String orderId,
    required double amountLkr,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String city,
  }) {
    return _startPayment(
      orderId: orderId,
      amountLkr: amountLkr,
      itemTitle: 'Highway TollPay Wallet Top-up',
      custom1: 'wallet_top_up',
      custom2: orderId,
      fullName: fullName,
      email: email,
      phone: phone,
      address: address,
      city: city,
    );
  }

  Future<String> startTollPayment({
    required String orderId,
    required double amountLkr,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String entryGate,
    required String exitGate,
    required String paymentMethodLabel,
  }) {
    return _startPayment(
      orderId: orderId,
      amountLkr: amountLkr,
      itemTitle: 'Highway TollPay Toll Charge',
      custom1: 'toll_trip_payment',
      custom2: '$entryGate|$exitGate|$paymentMethodLabel',
      fullName: fullName,
      email: email,
      phone: phone,
      address: address,
      city: city,
    );
  }

  Future<String> _startPayment({
    required String orderId,
    required double amountLkr,
    required String itemTitle,
    required String custom1,
    required String custom2,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String city,
  }) {
    if (!PayHereKeys.isConfigured) {
      throw StateError(
        'PayHere is not configured yet. Add PAYHERE_MERCHANT_ID and PAYHERE_MERCHANT_SECRET before testing.',
      );
    }

    final notifyUrl = PayHereKeys.notifyUrl.trim().isEmpty
        ? 'https://example.com/payhere/notify'
        : PayHereKeys.notifyUrl.trim();

    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? 'Highway' : nameParts.first;
    final lastName = nameParts.length < 2
        ? 'User'
        : nameParts.skip(1).join(' ').trim();

    final completer = Completer<String>();
    final paymentObject = <String, dynamic>{
      'sandbox': PayHereKeys.sandbox,
      'merchant_id': PayHereKeys.merchantId,
      'merchant_secret': PayHereKeys.merchantSecret,
      'notify_url': notifyUrl,
      'order_id': orderId,
      'items': itemTitle,
      'amount': amountLkr.toStringAsFixed(2),
      'currency': 'LKR',
      'first_name': firstName,
      'last_name': lastName,
      'email': email.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'country': 'Sri Lanka',
      'delivery_address': address.trim(),
      'delivery_city': city.trim(),
      'delivery_country': 'Sri Lanka',
      'custom_1': custom1,
      'custom_2': custom2,
    };

    PayHere.startPayment(
      paymentObject,
      (paymentId) {
        if (!completer.isCompleted) {
          completer.complete(paymentId.toString());
        }
      },
      (error) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('PayHere payment failed: $error'),
          );
        }
      },
      () {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('PayHere payment was dismissed before completion.'),
          );
        }
      },
    );

    return completer.future;
  }
}
