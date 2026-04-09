import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_models.dart';
import '../toll_repository.dart';
import 'payment_methods_screen.dart';
import 'profile_screen.dart';
import 'trip_flow_screen.dart';
import 'trip_history_screen.dart';
import 'vehicles_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final greetingName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : 'Driver';

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
                  Colors.black.withValues(alpha: 0.18),
                  const Color(0xFF090B16).withValues(alpha: 0.54),
                  const Color(0xFF05060D).withValues(alpha: 0.96),
                ],
              ),
            ),
          ),
          Positioned(
            top: 72,
            left: -52,
            child: _GlowBlob(
              size: 200,
              color: const Color(0xFF4AA6FF).withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 120,
            right: -36,
            child: _GlowBlob(
              size: 250,
              color: const Color(0xFF7F65FF).withValues(alpha: 0.20),
            ),
          ),
          SafeArea(
            child: StreamBuilder<List<Vehicle>>(
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
                        if (vehicleSnapshot.hasError ||
                            paymentSnapshot.hasError ||
                            tripSnapshot.hasError) {
                          final error = vehicleSnapshot.error ??
                              paymentSnapshot.error ??
                              tripSnapshot.error;
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: _SectionPanel(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Dashboard data could not load',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$error',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFC5CBDF),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final vehicles = vehicleSnapshot.data ?? const <Vehicle>[];
                        final paymentMethods =
                            paymentSnapshot.data ?? const <PaymentMethod>[];
                        final trips = tripSnapshot.data ?? const <TollTrip>[];
                        final activeTrips =
                            trips.where((trip) => trip.isActive).toList();
                        final activeTrip =
                            activeTrips.isEmpty ? null : activeTrips.first;
                        final recentTrips = trips
                            .where(
                              (trip) => trip.status == TripStatus.completed,
                            )
                            .take(3)
                            .toList();

                        final matchedVehicle = activeTrip == null
                            ? (vehicles.isEmpty ? null : vehicles.first)
                            : _findVehicle(vehicles, activeTrip.vehicleId);
                        final matchedPayment = activeTrip == null
                            ? _preferredPayment(paymentMethods)
                            : _findPayment(
                                paymentMethods,
                                activeTrip.paymentMethodId,
                              );

                        return Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  10,
                                  14,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Center(
                                      child: Text(
                                        'Highway TollPay',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      height: 1,
                                      color: const Color(0xFF705CFF)
                                          .withValues(alpha: 0.45),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'Hello, $greetingName',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 31,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      activeTrip == null
                                          ? 'Ready for your next toll journey.'
                                          : 'Your trip is currently active, drive safe!',
                                      style: const TextStyle(
                                        color: Color(0xFFB6BBD0),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    if (activeTrip != null)
                                      _ActiveTripCard(
                                        trip: activeTrip,
                                        onExitScan: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const TripFlowScreen(),
                                            ),
                                          );
                                        },
                                      )
                                    else
                                      _StartTripCard(
                                        onStart: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const TripFlowScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _InfoTile(
                                            title: 'Vehicle info',
                                            value: matchedVehicle == null
                                                ? 'Not Added'
                                                : matchedVehicle.plateNumber,
                                            subtitle: matchedVehicle == null
                                                ? 'Add vehicle'
                                                : matchedVehicle.category.label,
                                            icon: Icons.directions_car_filled,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _InfoTile(
                                            title: 'Payment Method',
                                            value: matchedPayment == null
                                                ? 'Not Added'
                                                : matchedPayment.label,
                                            subtitle: matchedPayment == null
                                                ? 'Set up payment'
                                                : matchedPayment.type ==
                                                        PaymentMethodType.wallet
                                                    ? 'LKR ${matchedPayment.balance.toStringAsFixed(2)}'
                                                    : matchedPayment.details,
                                            icon: Icons.credit_card_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'Quick Actions',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _QuickActionButton(
                                          icon:
                                              Icons.directions_car_filled_outlined,
                                          label: 'My\nVehicles',
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const VehiclesScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        _QuickActionButton(
                                          icon: Icons.payment_rounded,
                                          label: 'Payment\nMethods',
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PaymentMethodsScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        _QuickActionButton(
                                          icon: Icons.history_rounded,
                                          label: 'Trip\nHistory',
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const TripHistoryScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'Recent Trips',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (recentTrips.isEmpty)
                                      _SectionPanel(
                                        padding: const EdgeInsets.all(16),
                                        child: const Text(
                                          'No completed trips yet. Finish a trip to see receipts here.',
                                          style: TextStyle(
                                            color: Color(0xFFBBC2D9),
                                            height: 1.5,
                                          ),
                                        ),
                                      )
                                    else
                                      ...recentTrips.map(
                                        (trip) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: _RecentTripTile(trip: trip),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            _BottomNavBar(
                              onHomeTap: () {},
                              onScanTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TripFlowScreen(),
                                  ),
                                );
                              },
                              onProfileTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
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

  Vehicle? _findVehicle(List<Vehicle> vehicles, String vehicleId) {
    for (final vehicle in vehicles) {
      if (vehicle.id == vehicleId) {
        return vehicle;
      }
    }
    return null;
  }

  PaymentMethod? _findPayment(
    List<PaymentMethod> methods,
    String paymentMethodId,
  ) {
    for (final method in methods) {
      if (method.id == paymentMethodId) {
        return method;
      }
    }
    return null;
  }

  PaymentMethod? _preferredPayment(List<PaymentMethod> methods) {
    if (methods.isEmpty) {
      return null;
    }

    for (final method in methods) {
      if (method.type == PaymentMethodType.wallet) {
        return method;
      }
    }
    return methods.first;
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({
    required this.trip,
    required this.onExitScan,
  });

  final TollTrip trip;
  final VoidCallback onExitScan;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('h:mm a');
    return _SectionPanel(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -8,
            bottom: -8,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.32,
                child: Image.asset(
                  'assets/images/app_background.png',
                  fit: BoxFit.cover,
                  width: 170,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _TripMetaRow(label: 'Entry Gate', value: trip.entryGate),
              _TripMetaRow(
                label: 'Entry Time',
                value: formatter.format(trip.entryTimestamp),
              ),
              _TripMetaRow(label: 'Vehicle', value: trip.vehiclePlateNumber),
              const _TripMetaRow(label: 'Status', value: 'On Route'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onExitScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const Text('Scan Exit QR'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4666E6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartTripCard extends StatelessWidget {
  const _StartTripCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start New Trip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Scan your entry gate QR, choose the vehicle, and confirm the payment method to begin the trip.',
            style: TextStyle(
              color: Color(0xFFC4CAE0),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Open Trip Scanner'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4666E6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFB9C0D9),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F63DA).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF78B9FF), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8B95B7),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: _SectionPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF395FE0).withValues(alpha: 0.22),
                ),
                child: Icon(icon, color: const Color(0xFF7DB9FF), size: 16),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD7DCF0),
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTripTile extends StatelessWidget {
  const _RecentTripTile({required this.trip});

  final TollTrip trip;

  @override
  Widget build(BuildContext context) {
    return _SectionPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_car_filled_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${trip.entryGate} -> ${trip.exitGate ?? '-'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'LKR ${trip.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF8E7DFF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.onHomeTap,
    required this.onScanTap,
    required this.onProfileTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onScanTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: _SectionPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: true,
              onTap: onHomeTap,
            ),
            _NavItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan QR',
              onTap: onScanTap,
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF6DD8FF) : const Color(0xFF8C93AE);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripMetaRow extends StatelessWidget {
  const _TripMetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFD3D8EA),
            height: 1.45,
          ),
          children: [
            TextSpan(text: '$label : '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF171A29).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
