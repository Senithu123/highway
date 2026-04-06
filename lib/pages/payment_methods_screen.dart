import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_empty_state.dart';
import '../app_models.dart';
import '../firebase_auth_service.dart';
import '../payhere/payhere_payment_service.dart';
import '../toll_repository.dart';
import 'payhere_details_page.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            tooltip: 'Top Up with PayHere',
            onPressed: () => _showPayHereTopUpSheet(context),
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCardSheet(context),
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Add Card'),
      ),
      body: StreamBuilder<List<PaymentMethod>>(
        stream: TollRepository.instance.watchPaymentMethods(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final methods = snapshot.data!;
          if (methods.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No payment methods yet',
                  subtitle:
                      'Add a card or top up your wallet to start paying tolls.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showPayHereTopUpSheet(context),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Top Up with PayHere'),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: methods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final method = methods[index];
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        child: Icon(
                          method.type == PaymentMethodType.wallet
                              ? Icons.account_balance_wallet_outlined
                              : Icons.credit_card_rounded,
                        ),
                      ),
                      title: Text(method.label),
                      subtitle: Text(method.summary),
                      trailing: method.type == PaymentMethodType.wallet
                          ? Text(
                              'LKR ${method.balance.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                    if (method.type == PaymentMethodType.wallet)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: () => _showPayHereTopUpSheet(
                              context,
                              wallet: method,
                            ),
                            icon: const Icon(Icons.add_card_rounded),
                            label: const Text('Top Up'),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPayHereTopUpSheet(
    BuildContext outerContext, {
    PaymentMethod? wallet,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    try {
      final request = await Navigator.of(outerContext).push<PayHereCustomerDetails>(
        MaterialPageRoute(
          builder: (_) => PayHereDetailsPage(
            title: 'Top Up Wallet',
            subtitle: wallet == null
                ? 'Add money to your wallet with PayHere.'
                : 'Add money to your wallet with PayHere.',
            confirmLabel: 'Continue to PayHere',
            amountLkr: 1000,
            allowAmountEdit: true,
            signedInEmail: currentUser?.email,
          ),
        ),
      );

      if (request == null) {
        return;
      }

      final orderId = 'TOPUP-${DateTime.now().millisecondsSinceEpoch}';
      final displayName = (currentUser?.displayName ?? '').trim();
      final email = (currentUser?.email ?? '').trim();

      final paymentId = await PayHerePaymentService.instance.startWalletTopUp(
        orderId: orderId,
        amountLkr: request.amountLkr,
        fullName: displayName.isEmpty ? 'Highway TollPay User' : displayName,
        email: email.isEmpty ? 'sandbox-user@example.com' : email,
        phone: request.phone,
        address: request.address,
        city: request.city,
      );

      await TollRepository.instance.applyWalletTopUp(
        amount: request.amountLkr,
        paymentReference: paymentId,
        label: wallet?.label ?? 'PayHere Wallet',
        details: 'PayHere sandbox top-up ($paymentId)',
      );

      if (outerContext.mounted) {
        ScaffoldMessenger.of(outerContext).showSnackBar(
          SnackBar(
            content: Text(
              'Wallet topped up successfully. Payment ID: $paymentId',
            ),
          ),
        );
      }
    } catch (error) {
      if (outerContext.mounted) {
        final message = FirebaseAuthService.instance.messageFromError(error);
        ScaffoldMessenger.of(outerContext).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> _showAddCardSheet(BuildContext outerContext) async {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController(text: 'PayHere Sandbox Card');
    final detailsController = TextEditingController(
      text: 'Visa 4916 2175 0161 1292',
    );
    var isSaving = false;

    try {
      await showModalBottomSheet<void>(
        context: outerContext,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> save() async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                setModalState(() => isSaving = true);
                try {
                  await TollRepository.instance.addPaymentMethod(
                    type: PaymentMethodType.card,
                    label: labelController.text.trim(),
                    details: detailsController.text.trim(),
                    balance: 0.0,
                  );

                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }

                  if (outerContext.mounted) {
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      const SnackBar(
                        content: Text('Card added successfully.'),
                      ),
                    );
                  }
                } catch (error) {
                  if (outerContext.mounted) {
                    ScaffoldMessenger.of(outerContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          FirebaseAuthService.instance.messageFromError(error),
                        ),
                      ),
                    );
                  }
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Add Card',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Save a card label for trip payments. The payment itself still happens in PayHere when you confirm a toll.',
                        style: TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Card Label',
                          hintText: 'PayHere Sandbox Card',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'A label is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: detailsController,
                        decoration: const InputDecoration(
                          labelText: 'Card Details',
                          hintText: 'Visa 4916 2175 0161 1292',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Details are required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: isSaving ? null : save,
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Card'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      labelController.dispose();
      detailsController.dispose();
    }
  }
}
