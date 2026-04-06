import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../toll_gate_data.dart';
import '../toll_repository.dart';

class AdminTollManagementPage extends StatefulWidget {
  const AdminTollManagementPage({super.key});

  @override
  State<AdminTollManagementPage> createState() => _AdminTollManagementPageState();
}

class _AdminTollManagementPageState extends State<AdminTollManagementPage> {
  final _baseFareController = TextEditingController();
  final _pricePerKmController = TextEditingController();
  final _minimumFareController = TextEditingController();

  bool _pricingInitialized = false;
  bool _isSavingPricing = false;
  bool _isSeedingDefaults = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TollRepository.instance.seedDefaultTollSystemIfMissing();
    });
  }

  @override
  void dispose() {
    _baseFareController.dispose();
    _pricePerKmController.dispose();
    _minimumFareController.dispose();
    super.dispose();
  }

  void _syncPricingControllers(TollPricingConfig pricing) {
    if (_pricingInitialized) {
      return;
    }
    _baseFareController.text = pricing.baseFare.toStringAsFixed(2);
    _pricePerKmController.text = pricing.pricePerKm.toStringAsFixed(2);
    _minimumFareController.text = pricing.minimumFare.toStringAsFixed(2);
    _pricingInitialized = true;
  }

  Future<void> _seedDefaults() async {
    setState(() => _isSeedingDefaults = true);
    try {
      await TollRepository.instance.seedDefaultTollSystemIfMissing();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default toll gates and pricing loaded.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSeedingDefaults = false);
      }
    }
  }

  Future<void> _savePricing() async {
    final baseFare = double.tryParse(_baseFareController.text.trim());
    final pricePerKm = double.tryParse(_pricePerKmController.text.trim());
    final minimumFare = double.tryParse(_minimumFareController.text.trim());

    if (baseFare == null || pricePerKm == null || minimumFare == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid numbers for all pricing fields.')),
      );
      return;
    }

    setState(() => _isSavingPricing = true);
    try {
      await TollRepository.instance.savePricingConfig(
        TollPricingConfig(
          baseFare: baseFare,
          pricePerKm: pricePerKm,
          minimumFare: minimumFare,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toll pricing updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingPricing = false);
      }
    }
  }

  Future<void> _openGateEditor({TollGate? gate}) async {
    final nameController = TextEditingController(text: gate?.name ?? '');
    final highwayController = TextEditingController(text: gate?.highway ?? 'E01');
    final kmController = TextEditingController(
      text: gate == null ? '' : gate.kmMarker.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    var isSaving = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> save() async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final km = double.parse(kmController.text.trim());
                final name = nameController.text.trim();
                final highway = highwayController.text.trim().toUpperCase();
                final gateId = gate?.id ??
                    TollRepository.instance.buildGateId(
                      highway: highway,
                      name: name,
                    );

                setModalState(() => isSaving = true);
                try {
                  await TollRepository.instance.saveTollGate(
                    TollGate(
                      id: gateId,
                      name: name,
                      highway: highway,
                      kmMarker: km,
                    ),
                  );
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          gate == null
                              ? 'Stop added with its QR code.'
                              : 'Stop updated successfully.',
                        ),
                      ),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.toString().replaceFirst('Bad state: ', ''),
                        ),
                      ),
                    );
                  }
                } finally {
                  if (sheetContext.mounted) {
                    setModalState(() => isSaving = false);
                  }
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: _AdminGlassPanel(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          gate == null ? 'Add Toll Stop' : 'Edit Toll Stop',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AdminField(
                          controller: nameController,
                          label: 'Stop Name',
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Stop name is required.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _AdminField(
                          controller: highwayController,
                          label: 'Highway Code',
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Highway code is required.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _AdminField(
                          controller: kmController,
                          label: 'KM Marker',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              double.tryParse((value ?? '').trim()) == null
                                  ? 'Enter a valid kilometer marker.'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: isSaving ? null : save,
                          child: Text(
                            isSaving
                                ? 'Saving...'
                                : gate == null
                                    ? 'Add Stop'
                                    : 'Save Changes',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      highwayController.dispose();
      kmController.dispose();
    }
  }

  Future<void> _deleteGate(TollGate gate) async {
    await TollRepository.instance.deleteTollGate(gate.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${gate.name} removed from toll stops.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TollPricingConfig>(
      stream: TollRepository.instance.watchPricingConfig(),
      builder: (context, pricingSnapshot) {
        final pricing = pricingSnapshot.data ?? TollGateCatalog.defaultPricing;
        _syncPricingControllers(pricing);

        return StreamBuilder<List<TollGate>>(
          stream: TollRepository.instance.watchTollGates(),
          builder: (context, gateSnapshot) {
            final gates = gateSnapshot.data ?? TollGateCatalog.gates;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stops, QRs & Pricing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSeedingDefaults ? null : _seedDefaults,
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: Text(
                            _isSeedingDefaults
                                ? 'Loading Defaults...'
                                : 'Load Default Stops',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openGateEditor(),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Add Stop'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _AdminGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pricing Controls',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _AdminField(
                          controller: _baseFareController,
                          label: 'Base Fare',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AdminField(
                          controller: _pricePerKmController,
                          label: 'Price Per KM',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AdminField(
                          controller: _minimumFareController,
                          label: 'Minimum Fare',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _isSavingPricing ? null : _savePricing,
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(
                            _isSavingPricing ? 'Saving Prices...' : 'Save Prices',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AdminGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Stops (${gates.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (gates.isEmpty)
                          const Text(
                            'No toll stops are configured yet.',
                            style: TextStyle(color: Color(0xFFC7CEE0)),
                          )
                        else
                          ...gates.map(
                            (gate) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _GateQrAdminCard(
                                gate: gate,
                                pricing: pricing,
                                onEdit: () => _openGateEditor(gate: gate),
                                onDelete: () => _deleteGate(gate),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminGlassPanel extends StatelessWidget {
  const _AdminGlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171B2A).withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: child,
    );
  }
}

class _AdminField extends StatelessWidget {
  const _AdminField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB6C1E2)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6FB8FF)),
        ),
      ),
    );
  }
}

class _GateQrAdminCard extends StatelessWidget {
  const _GateQrAdminCard({
    required this.gate,
    required this.pricing,
    required this.onEdit,
    required this.onDelete,
  });

  final TollGate gate;
  final TollPricingConfig pricing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: gate.qrLink));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${gate.name} link copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sampleFare = (pricing.baseFare + (gate.kmMarker * pricing.pricePerKm))
        .clamp(pricing.minimumFare, 1600)
        .toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gate.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${gate.highway} • KM ${gate.kmMarker.toStringAsFixed(0)} • Sample toll LKR $sampleFare',
                      style: const TextStyle(
                        color: Color(0xFFC7CEE0),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      gate.qrPayload,
                      style: const TextStyle(
                        color: Color(0xFF89C8FF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QR Link',
                            style: TextStyle(
                              color: Color(0xFFC7CEE0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            gate.qrLink,
                            style: const TextStyle(
                              color: Color(0xFF89C8FF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: gate.qrPayload,
                  version: QrVersions.auto,
                  size: 110,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyLink(context),
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Copy Link'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Edit Stop'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
