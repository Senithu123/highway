import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_models.dart';
import '../firebase_auth_service.dart';
import '../payhere/payhere_payment_service.dart';
import '../toll_gate_data.dart';
import '../toll_repository.dart';
import 'payhere_details_page.dart';
import 'payment_methods_screen.dart';
import 'qr_scanner_screen.dart';
import 'vehicles_screen.dart';

class TripFlowScreen extends StatefulWidget {
  const TripFlowScreen({super.key});

  @override
  State<TripFlowScreen> createState() => _TripFlowScreenState();
}

class _TripFlowScreenState extends State<TripFlowScreen> {
  String? _selectedEntryGate;
  String? _selectedExitGate;
  String? _selectedVehicleId;
  String? _selectedPaymentMethodId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Scanner')),
      body: StreamBuilder<List<TollGate>>(
        stream: TollRepository.instance.watchTollGates(),
        builder: (context, gateSnapshot) {
          return StreamBuilder<TollPricingConfig>(
            stream: TollRepository.instance.watchPricingConfig(),
            builder: (context, pricingSnapshot) {
              return StreamBuilder<List<Vehicle>>(
                stream: TollRepository.instance.watchVehicles(),
                builder: (context, vehicleSnapshot) {
                  return StreamBuilder<List<PaymentMethod>>(
                    stream: TollRepository.instance.watchPaymentMethods(),
                    builder: (context, paymentSnapshot) {
                      return StreamBuilder<TollTrip?>(
                        stream: TollRepository.instance.watchActiveTrip(),
                        builder: (context, tripSnapshot) {
                          if (gateSnapshot.hasError ||
                              pricingSnapshot.hasError ||
                              vehicleSnapshot.hasError ||
                              paymentSnapshot.hasError ||
                              tripSnapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  gateSnapshot.error?.toString() ??
                                      pricingSnapshot.error?.toString() ??
                                      vehicleSnapshot.error?.toString() ??
                                      paymentSnapshot.error?.toString() ??
                                      tripSnapshot.error.toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          if (!gateSnapshot.hasData ||
                              !pricingSnapshot.hasData ||
                              !vehicleSnapshot.hasData ||
                              !paymentSnapshot.hasData ||
                              tripSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final gates = gateSnapshot.data!;
                          final pricing = pricingSnapshot.data!;
                          final vehicles = vehicleSnapshot.data!;
                          final paymentMethods = paymentSnapshot.data!;
                          final activeTrip = tripSnapshot.data;

                          if (activeTrip == null) {
                            return _buildEntryFlow(
                              context,
                              gates,
                              vehicles,
                              paymentMethods,
                            );
                          }

                          return _buildExitFlow(
                            context,
                            gates,
                            pricing,
                            activeTrip,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEntryFlow(
    BuildContext context,
    List<TollGate> gates,
    List<Vehicle> vehicles,
    List<PaymentMethod> paymentMethods,
  ) {
    final selectedVehicle = _resolveSelectedVehicle(vehicles);
    final selectedPayment = _resolveSelectedPayment(paymentMethods);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _FlowHeader(
          title: 'Entry Toll Scan',
          subtitle:
              'Scan the real entry gate QR code, then confirm the vehicle and payment method for this trip.',
        ),
        const SizedBox(height: 18),
        _ScanStatusCard(
          title: 'Entry Gate QR',
          gateLabel: _selectedEntryGate,
          helperText: _selectedEntryGate == null
              ? 'No entry gate scanned yet.'
              : 'Entry gate locked from scanned QR.',
          buttonLabel:
              _selectedEntryGate == null ? 'Scan Entry QR' : 'Rescan Entry QR',
          onPressed: _isSubmitting ? null : () => _scanEntryGate(gates),
        ),
        const SizedBox(height: 18),
        if (gates.isEmpty) ...[
          const _InlineWarning(
            text:
                'No toll stops are configured yet. Ask the admin to add stops and QR codes first.',
          ),
          const SizedBox(height: 18),
        ],
        if (vehicles.isEmpty) ...[
          const _InlineWarning(
            text:
                'Add at least one vehicle before starting a trip. Toll amounts depend on vehicle type.',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VehiclesScreen()),
              );
            },
            child: const Text('Add Vehicle'),
          ),
          const SizedBox(height: 18),
        ] else
          DropdownButtonFormField<String>(
            initialValue: selectedVehicle?.id,
            items: vehicles
                .map(
                  (vehicle) => DropdownMenuItem(
                    value: vehicle.id,
                    child: Text(
                      '${vehicle.displayName} - ${vehicle.category.label}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedVehicleId = value),
            decoration: const InputDecoration(
              labelText: 'Vehicle for this trip',
            ),
          ),
        const SizedBox(height: 18),
        if (paymentMethods.isEmpty) ...[
          const _InlineWarning(
            text: 'Add a card or wallet before you can confirm toll payments.',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
              );
            },
            child: const Text('Add Payment Method'),
          ),
          const SizedBox(height: 18),
        ] else
          DropdownButtonFormField<String>(
            initialValue: selectedPayment?.id,
            items: paymentMethods
                .map(
                  (method) => DropdownMenuItem(
                    value: method.id,
                    child: Text('${method.label} - ${method.summary}'),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedPaymentMethodId = value),
            decoration: const InputDecoration(
              labelText: 'Payment method',
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isSubmitting ||
                  _selectedEntryGate == null ||
                  selectedVehicle == null ||
                  selectedPayment == null ||
                  gates.isEmpty
              ? null
              : () => _startTrip(
                    context,
                    selectedVehicle,
                    selectedPayment,
                  ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(_isSubmitting ? 'Starting...' : 'Start Trip'),
        ),
      ],
    );
  }

  Widget _buildExitFlow(
    BuildContext context,
    List<TollGate> gates,
    TollPricingConfig pricing,
    TollTrip activeTrip,
  ) {
    double? farePreview;
    if (_selectedExitGate != null) {
      try {
        farePreview = TollRepository.instance.calculateFareForConfig(
          entryGate: activeTrip.entryGate,
          exitGate: _selectedExitGate!,
          category: activeTrip.vehicleCategory,
          gates: gates,
          pricing: pricing,
        );
      } catch (_) {
        farePreview = null;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _FlowHeader(
          title: 'Exit Toll Scan',
          subtitle:
              'An active trip is in progress. Scan the real exit gate QR code to calculate the fare and complete the payment.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activeTrip.entryGate} -> ${_selectedExitGate ?? 'Waiting for exit scan'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text('Vehicle: ${activeTrip.vehiclePlateNumber}'),
                Text('Category: ${activeTrip.vehicleCategory.label}'),
                Text('Payment: ${activeTrip.paymentMethodLabel}'),
                if (activeTrip.paymentMethodType == PaymentMethodType.card)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'PayHere will open for this toll payment.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  farePreview == null
                      ? 'Scan an exit gate QR to calculate the fare.'
                      : 'Fare preview: LKR ${farePreview.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ScanStatusCard(
          title: 'Exit Gate QR',
          gateLabel: _selectedExitGate,
          helperText: _selectedExitGate == null
              ? 'No exit gate scanned yet.'
              : 'Exit gate captured from scanned QR.',
          buttonLabel:
              _selectedExitGate == null ? 'Scan Exit QR' : 'Rescan Exit QR',
          onPressed: _isSubmitting
              ? null
              : () => _scanExitGate(
                    gates.where((gate) => gate.name != activeTrip.entryGate).toList(),
                  ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isSubmitting || _selectedExitGate == null
              ? null
              : () => _completeTrip(context, activeTrip, gates, pricing),
          icon: const Icon(Icons.payments_outlined),
          label: Text(_isSubmitting ? 'Processing...' : 'Confirm Payment'),
        ),
      ],
    );
  }

  Vehicle? _resolveSelectedVehicle(List<Vehicle> vehicles) {
    for (final vehicle in vehicles) {
      if (vehicle.id == _selectedVehicleId) {
        return vehicle;
      }
    }
    return vehicles.isEmpty ? null : vehicles.first;
  }

  PaymentMethod? _resolveSelectedPayment(List<PaymentMethod> methods) {
    for (final method in methods) {
      if (method.id == _selectedPaymentMethodId) {
        return method;
      }
    }
    return methods.isEmpty ? null : methods.first;
  }

  Future<void> _scanEntryGate(List<TollGate> gates) async {
    final rawValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          title: 'Scan Entry Gate',
          instruction:
              'Point the camera at the entry toll QR code to capture the gate automatically.',
          allowedGates: gates.map((gate) => gate.name).toList(growable: false),
        ),
      ),
    );

    if (!mounted || rawValue == null) {
      return;
    }

    final gate = _extractGateFromQr(rawValue, allowedGates: gates);

    if (gate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This QR code is not a recognized entry gate.'),
        ),
      );
      return;
    }

    setState(() => _selectedEntryGate = gate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entry gate scanned: $gate')),
    );
  }

  Future<void> _scanExitGate(List<TollGate> allowedExitGates) async {
    final rawValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          title: 'Scan Exit Gate',
          instruction:
              'Scan the exit toll QR code to calculate the fare for the active trip.',
          allowedGates: allowedExitGates
              .map((gate) => gate.name)
              .toList(growable: false),
        ),
      ),
    );

    if (!mounted || rawValue == null) {
      return;
    }

    final gate = _extractGateFromQr(rawValue, allowedGates: allowedExitGates);

    if (gate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This QR code is not a valid exit gate for this trip.'),
        ),
      );
      return;
    }

    setState(() => _selectedExitGate = gate);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exit gate scanned: $gate')),
    );
  }

  String? _extractGateFromQr(
    String rawValue, {
    required List<TollGate> allowedGates,
  }) {
    final matchedGate = TollGateCatalog.fromQrPayload(
      rawValue,
      inList: allowedGates,
    );
    return matchedGate?.name;
  }

  Future<void> _startTrip(
    BuildContext context,
    Vehicle vehicle,
    PaymentMethod paymentMethod,
  ) async {
    if (_selectedEntryGate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan an entry gate QR first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await TollRepository.instance.startTrip(
        entryGate: _selectedEntryGate!,
        vehicle: vehicle,
        paymentMethod: paymentMethod,
      );
      if (mounted) {
        setState(() => _selectedExitGate = null);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip started successfully.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _completeTrip(
    BuildContext context,
    TollTrip activeTrip,
    List<TollGate> gates,
    TollPricingConfig pricing,
  ) async {
    if (_selectedExitGate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan an exit gate QR first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final exitGate = _selectedExitGate!;
      final fareAmount = TollRepository.instance.calculateFareForConfig(
        entryGate: activeTrip.entryGate,
        exitGate: exitGate,
        category: activeTrip.vehicleCategory,
        gates: gates,
        pricing: pricing,
      );

      if (activeTrip.paymentMethodType == PaymentMethodType.card) {
        final currentUser = FirebaseAuth.instance.currentUser;
        final request = await Navigator.of(context).push<PayHereCustomerDetails>(
          MaterialPageRoute(
            builder: (_) => PayHereDetailsPage(
              title: 'Pay Toll with PayHere',
              subtitle:
                  '${activeTrip.entryGate} -> $exitGate\nSelected payment method: ${activeTrip.paymentMethodLabel}',
              confirmLabel: 'Continue to PayHere',
              amountLkr: fareAmount,
              signedInEmail: currentUser?.email,
            ),
          ),
        );

        if (request == null) {
          return;
        }

        final displayName = (currentUser?.displayName ?? '').trim();
        final email = (currentUser?.email ?? '').trim();

        await PayHerePaymentService.instance.startTollPayment(
          orderId: 'TRIP-${activeTrip.id}-${DateTime.now().millisecondsSinceEpoch}',
          amountLkr: request.amountLkr,
          fullName: displayName.isEmpty ? 'Highway TollPay User' : displayName,
          email: email.isEmpty ? 'sandbox-user@example.com' : email,
          phone: request.phone,
          address: request.address,
          city: request.city,
          entryGate: activeTrip.entryGate,
          exitGate: exitGate,
          paymentMethodLabel: activeTrip.paymentMethodLabel,
        );
      }

      final completedTrip = await TollRepository.instance.completeTrip(
        trip: activeTrip,
        exitGate: exitGate,
      );

      if (!context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Payment Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${completedTrip.entryGate} -> ${completedTrip.exitGate}'),
                const SizedBox(height: 8),
                Text('Amount: LKR ${completedTrip.amount.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text('Receipt: ${completedTrip.receiptNumber ?? '-'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        setState(() {
          _selectedEntryGate = null;
          _selectedExitGate = null;
        });
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(FirebaseAuthService.instance.messageFromError(error)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

class _ScanStatusCard extends StatelessWidget {
  const _ScanStatusCard({
    required this.title,
    required this.gateLabel,
    required this.helperText,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String? gateLabel;
  final String helperText;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gateLabel ?? 'Waiting for scan',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        helperText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.center_focus_strong_rounded),
                label: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Text(text),
    );
  }
}
