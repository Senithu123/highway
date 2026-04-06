import 'package:flutter/material.dart';

class PayHereCustomerDetails {
  const PayHereCustomerDetails({
    required this.amountLkr,
    required this.phone,
    required this.address,
    required this.city,
  });

  final double amountLkr;
  final String phone;
  final String address;
  final String city;
}

class PayHereDetailsPage extends StatefulWidget {
  const PayHereDetailsPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    this.amountLkr,
    this.allowAmountEdit = false,
    this.signedInEmail,
    this.initialPhone = '0771234567',
    this.initialAddress = 'No. 1, Galle Road',
    this.initialCity = 'Colombo',
  });

  final String title;
  final String subtitle;
  final String confirmLabel;
  final double? amountLkr;
  final bool allowAmountEdit;
  final String? signedInEmail;
  final String initialPhone;
  final String initialAddress;
  final String initialCity;

  @override
  State<PayHereDetailsPage> createState() => _PayHereDetailsPageState();
}

class _PayHereDetailsPageState extends State<PayHereDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  bool _isContinuing = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.amountLkr?.toStringAsFixed(2) ?? '1000.00',
    );
    _phoneController = TextEditingController(text: widget.initialPhone);
    _addressController = TextEditingController(text: widget.initialAddress);
    _cityController = TextEditingController(text: widget.initialCity);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _continueToPayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      return;
    }

    setState(() => _isContinuing = true);
    Navigator.of(context).pop(
      PayHereCustomerDetails(
        amountLkr: amount,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.subtitle,
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  readOnly: !widget.allowAmountEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.allowAmountEdit
                        ? 'Amount (LKR)'
                        : 'Amount',
                  ),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount.';
                    }
                    return null;
                  },
                ),
                if ((widget.signedInEmail ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Signed in as ${widget.signedInEmail!.trim()}',
                    style: const TextStyle(height: 1.5),
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Phone number is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Address is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'City is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isContinuing ? null : _continueToPayment,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    _isContinuing ? 'Continuing...' : widget.confirmLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
