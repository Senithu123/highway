import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_models.dart';
import '../firebase_auth_service.dart';
import '../toll_repository.dart';
import 'payment_methods_screen.dart';
import 'trip_history_screen.dart';
import 'vehicles_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _showEditProfileSheet(ClientProfile profile) async {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: profile.fullName);
    final phoneController = TextEditingController(text: profile.phoneNumber);
    final licenseController =
        TextEditingController(text: profile.driverLicenseNumber);
    var isSaving = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (modalContext, setModalState) {
              Future<void> save() async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                setModalState(() => isSaving = true);
                try {
                  await FirebaseAuthService.instance.updateCurrentUserProfile(
                    fullName: fullNameController.text,
                    phoneNumber: phoneController.text,
                    driverLicenseNumber: licenseController.text,
                  );
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully.'),
                      ),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          FirebaseAuthService.instance.messageFromError(error),
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
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom: MediaQuery.of(modalContext).viewInsets.bottom + 18,
                ),
                child: _Panel(
                  radius: 28,
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _InputField(
                          controller: fullNameController,
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Full name is required.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _InputField(
                          controller: phoneController,
                          label: 'Phone Number',
                          icon: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required.';
                            }
                            final digits = value.replaceAll(RegExp(r'\D'), '');
                            return digits.length < 9
                                ? 'Enter a valid phone number.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _InputField(
                          controller: licenseController,
                          label: 'Driver License Number',
                          icon: Icons.badge_outlined,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => save(),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Driver license number is required.'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: isSaving ? null : save,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(isSaving ? 'Saving...' : 'Save Changes'),
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
      fullNameController.dispose();
      phoneController.dispose();
      licenseController.dispose();
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(() => _isSigningOut = true);
    try {
      await FirebaseAuthService.instance.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FirebaseAuthService.instance.messageFromError(error)),
        ),
      );
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/app_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  const Color(0xFF080B17).withValues(alpha: 0.56),
                  const Color(0xFF04060D).withValues(alpha: 0.96),
                ],
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<ClientProfile?>(
              stream: FirebaseAuthService.instance.watchCurrentUserProfile(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _Panel(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          FirebaseAuthService.instance.messageFromError(
                            profileSnapshot.error!,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }

                if (!profileSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = profileSnapshot.data;
                if (profile == null) {
                  return const Center(
                    child: Text(
                      'No client profile is available right now.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return StreamBuilder<List<Vehicle>>(
                  stream: TollRepository.instance.watchVehicles(),
                  initialData: const [],
                  builder: (context, vehicleSnapshot) {
                    return StreamBuilder<List<PaymentMethod>>(
                      stream: TollRepository.instance.watchPaymentMethods(),
                      initialData: const [],
                      builder: (context, paymentSnapshot) {
                        return StreamBuilder<List<TollTrip>>(
                          stream: TollRepository.instance.watchTrips(),
                          initialData: const [],
                          builder: (context, tripSnapshot) {
                            final vehicles =
                                vehicleSnapshot.data ?? const <Vehicle>[];
                            final payments =
                                paymentSnapshot.data ?? const <PaymentMethod>[];
                            final trips = tripSnapshot.data ?? const <TollTrip>[];
                            final completedTrips = trips
                                .where((trip) => trip.status == TripStatus.completed)
                                .length;
                            final walletBalance = payments
                                .where(
                                  (method) =>
                                      method.type == PaymentMethodType.wallet,
                                )
                                .fold<double>(0, (sum, method) => sum + method.balance);

                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Client Profile',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _showEditProfileSheet(profile),
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        label: const Text('Edit'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _Panel(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 34,
                                              backgroundColor: const Color(0xFF4D67F4),
                                              child: Text(
                                                profile.initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    profile.displayName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    profile.email,
                                                    style: const TextStyle(
                                                      color: Color(0xFFBFCAE7),
                                                    ),
                                                  ),
                                                  if (profile.createdAt != null) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Joined ${DateFormat('MMMM d, y').format(profile.createdAt!)}',
                                                      style: const TextStyle(
                                                        color: Color(0xFF8F9CC1),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _StatBox(
                                                label: 'Vehicles',
                                                value: '${vehicles.length}',
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _StatBox(
                                                label: 'Trips',
                                                value: '$completedTrips',
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _StatBox(
                                                label: 'Wallet',
                                                value:
                                                    'LKR ${walletBalance.toStringAsFixed(0)}',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _Panel(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      children: [
                                        _DetailTile(
                                          label: 'Full Name',
                                          value: profile.fullName.isEmpty
                                              ? 'Not added'
                                              : profile.fullName,
                                        ),
                                        _DetailTile(
                                          label: 'Email',
                                          value: profile.email.isEmpty
                                              ? 'Not added'
                                              : profile.email,
                                        ),
                                        _DetailTile(
                                          label: 'Phone Number',
                                          value: profile.phoneNumber.isEmpty
                                              ? 'Not added'
                                              : profile.phoneNumber,
                                        ),
                                        _DetailTile(
                                          label: 'License Number',
                                          value: profile.driverLicenseNumber.isEmpty
                                              ? 'Not added'
                                              : profile.driverLicenseNumber,
                                          showDivider: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _LinkTile(
                                    title: 'My Vehicles',
                                    subtitle: '${vehicles.length} registered',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const VehiclesScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _LinkTile(
                                    title: 'Payment Methods',
                                    subtitle: '${payments.length} saved',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PaymentMethodsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _LinkTile(
                                    title: 'Trip History',
                                    subtitle: '$completedTrips completed trips',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TripHistoryScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _isSigningOut ? null : _signOut,
                                      icon: _isSigningOut
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.logout_rounded),
                                      label: Text(
                                        _isSigningOut
                                            ? 'Signing Out...'
                                            : 'Sign Out',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF171B2A).withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFB6C1E2)),
        prefixIcon: Icon(icon, color: const Color(0xFF88B8FF)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF6FB8FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF7F92)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF7F92)),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF92A0C8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF91A0C8),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: _Panel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF95A3CA)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF8A96BD),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
