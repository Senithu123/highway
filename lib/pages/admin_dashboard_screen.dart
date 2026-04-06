import 'dart:math';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../admin_access.dart';
import '../admin_repository.dart';
import '../app_models.dart';
import '../firebase_auth_service.dart';
import 'admin_toll_management_page.dart';
import 'welcome_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  Future<void> _handleLogout() async {
    await FirebaseAuthService.instance.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (!AdminAccess.hasAdminAccess(user)) {
      return _BlockedAdminScreen(email: user?.email);
    }

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
                  const Color(0xFF090B16).withValues(alpha: 0.58),
                  const Color(0xFF05060D).withValues(alpha: 0.96),
                ],
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -50,
            child: _GlowBlob(
              size: 220,
              color: const Color(0xFF4AA6FF).withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 130,
            right: -40,
            child: _GlowBlob(
              size: 240,
              color: const Color(0xFF7F65FF).withValues(alpha: 0.18),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<AdminDashboardData>(
                    stream: AdminRepository.instance.watchDashboardData(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _AdminErrorPanel(error: snapshot.error);
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final data = snapshot.data!;
                      final analytics = _AdminAnalytics.fromData(
                        users: data.users,
                        vehicles: data.vehicles,
                        trips: data.trips,
                      );

                      return IndexedStack(
                        index: _selectedIndex,
                        children: [
                          _buildOverviewPage(analytics),
                          _buildVehiclesPage(analytics),
                          _buildHistoryPage(analytics),
                          _buildReportsPage(analytics),
                          const AdminTollManagementPage(),
                        ],
                      );
                    },
                  ),
                ),
                _AdminBottomNavBar(
                  selectedIndex: _selectedIndex,
                  onSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewPage(_AdminAnalytics analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onLogout: _handleLogout),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This admin login opens a live control center for enrollment, toll usage, revenue, and traffic behavior.',
                  style: TextStyle(
                    color: Color(0xFFC7CEE0),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HighlightBox(
                        label: 'Total Revenue',
                        value: analytics.totalRevenueLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HighlightBox(
                        label: 'Top Route',
                        value: analytics.topRouteLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                label: 'Users Enrolled',
                value: '${analytics.totalUsers}',
                icon: Icons.people_alt_rounded,
              ),
              _MetricTile(
                label: 'Users Who Used Toll',
                value: '${analytics.activeUsers}',
                icon: Icons.verified_user_rounded,
              ),
              _MetricTile(
                label: 'Vehicles Added',
                value: '${analytics.totalVehicles}',
                icon: Icons.directions_car_filled_rounded,
              ),
              _MetricTile(
                label: 'Completed Trips',
                value: '${analytics.completedTrips}',
                icon: Icons.route_rounded,
              ),
              _MetricTile(
                label: 'Live Trips',
                value: '${analytics.activeTrips}',
                icon: Icons.traffic_rounded,
              ),
              _MetricTile(
                label: 'Average Toll',
                value: analytics.averageFareLabel,
                icon: Icons.payments_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Main Busy Hours',
            subtitle: 'Peak entry windows based on recorded trip starts.',
          ),
          const SizedBox(height: 10),
          _Panel(
            child: analytics.busyHours.isEmpty
                ? const _EmptyText(
                    'Busy hour insights will appear once users start making trips.',
                  )
                : Column(
                    children: analytics.busyHours
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BusyHourRow(
                              item: item,
                              maxCount: analytics.maxHourCount,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Extra Insights',
            subtitle: 'High-value admin details beyond the headline numbers.',
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SimpleListPanel(
                  title: 'Top Routes',
                  emptyText: 'Top routes will appear after completed trips.',
                  items: analytics.topRoutes,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SimpleListPanel(
                  title: 'Top Entry Gates',
                  emptyText:
                      'Top gate activity will appear after completed trips.',
                  items: analytics.topEntryGates,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Newest Enrollments',
            subtitle: 'Latest users added to the system.',
          ),
          const SizedBox(height: 10),
          _Panel(
            child: analytics.recentUsers.isEmpty
                ? const _EmptyText(
                    'New registrations will show here once users sign up.',
                  )
                : Column(
                    children: analytics.recentUsers
                        .map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _UserRow(user: user),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildVehiclesPage(_AdminAnalytics analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onLogout: _handleLogout),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehicle Registry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'See every vehicle users have registered in the toll system.',
                  style: TextStyle(
                    color: Color(0xFFC7CEE0),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HighlightBox(
                        label: 'Total Vehicles',
                        value: '${analytics.totalVehicles}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HighlightBox(
                        label: 'Users With Vehicles',
                        value: '${analytics.usersWithVehicles}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'User Vehicles',
            subtitle: 'Vehicles registered by users across the system.',
          ),
          const SizedBox(height: 10),
          _Panel(
            child: analytics.recentVehicles.isEmpty
                ? const _EmptyText(
                    'Registered user vehicles will appear here once users add them.',
                  )
                : Column(
                    children: analytics.recentVehicles
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _VehicleRow(item: item),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHistoryPage(_AdminAnalytics analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onLogout: _handleLogout),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Review completed toll journeys and recent system-wide usage.',
                  style: TextStyle(
                    color: Color(0xFFC7CEE0),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HighlightBox(
                        label: 'Completed Trips',
                        value: '${analytics.completedTrips}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HighlightBox(
                        label: 'Total Revenue',
                        value: analytics.totalRevenueLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'System Trip History',
            subtitle: 'Recent completed toll history across every user.',
          ),
          const SizedBox(height: 10),
          _Panel(
            child: analytics.recentHistory.isEmpty
                ? const _EmptyText(
                    'Completed trip history will appear here once payments are made.',
                  )
                : Column(
                    children: analytics.recentHistory
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HistoryRow(item: item),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildReportsPage(_AdminAnalytics analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onLogout: _handleLogout),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Track toll income and visualize how the highway is being used throughout the day.',
                  style: TextStyle(
                    color: Color(0xFFC7CEE0),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HighlightBox(
                        label: 'Total Income',
                        value: analytics.totalRevenueLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HighlightBox(
                        label: 'Today\'s Income',
                        value: analytics.todayRevenueLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                label: 'Trips Today',
                value: '${analytics.todayTrips}',
                icon: Icons.today_rounded,
              ),
              _MetricTile(
                label: 'Completed Trips',
                value: '${analytics.completedTrips}',
                icon: Icons.receipt_long_rounded,
              ),
              _MetricTile(
                label: 'Peak Hour',
                value: analytics.peakHourLabel,
                icon: Icons.query_stats_rounded,
              ),
              _MetricTile(
                label: 'Average Toll',
                value: analytics.averageFareLabel,
                icon: Icons.payments_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Highway Usage Graph',
            subtitle: 'Trips started by hour across the full day.',
          ),
          const SizedBox(height: 10),
          _Panel(
            child: analytics.usageByHour.every((item) => item.count == 0)
                ? const _EmptyText(
                    'Usage graph will appear once trips start flowing through the system.',
                  )
                : _UsageBarChart(points: analytics.usageByHour),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Traffic Notes',
            subtitle: 'Quick operational insights from usage and revenue.',
          ),
          const SizedBox(height: 10),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReportBullet(
                  title: 'Peak traffic window',
                  value: analytics.peakHourSummary,
                ),
                const SizedBox(height: 10),
                _ReportBullet(
                  title: 'Top entry gate',
                  value: analytics.topGateLabel,
                ),
                const SizedBox(height: 10),
                _ReportBullet(
                  title: 'Most used route',
                  value: analytics.topRouteLabel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Control Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Signed in as ${AdminAccess.adminEmail}',
                style: const TextStyle(color: Color(0xFFB9C1DB)),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEE, d MMM yyyy').format(DateTime.now()),
                style: const TextStyle(
                  color: Color(0xFF8C98BD),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onLogout,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF78B9FF)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD3D9EC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightBox extends StatelessWidget {
  const _HighlightBox({
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9CA8C9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFFA8B2CF), height: 1.4),
        ),
      ],
    );
  }
}

class _SimpleListPanel extends StatelessWidget {
  const _SimpleListPanel({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<_CountInsight> items;

  @override
  Widget build(BuildContext context) {
    return _Panel(
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
          const SizedBox(height: 12),
          if (items.isEmpty)
            _EmptyText(emptyText)
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(color: Color(0xFFD7DCF0)),
                      ),
                    ),
                    Text(
                      '${item.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BusyHourRow extends StatelessWidget {
  const _BusyHourRow({
    required this.item,
    required this.maxCount,
  });

  final _HourInsight item;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount == 0 ? 0.0 : item.count / maxCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${item.count} trips',
              style: const TextStyle(color: Color(0xFF9AA6C8), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6ED4FF)),
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final AdminUserAccount user;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: const TextStyle(color: Color(0xFFC7D0E6)),
              ),
              const SizedBox(height: 4),
              Text(
                'Joined ${DateFormat('d MMM yyyy, h:mm a').format(user.createdAt)}',
                style: const TextStyle(
                  color: Color(0xFF8F9ABA),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final _HistoryInsight item;

  @override
  Widget build(BuildContext context) {
    final trip = item.record.trip;
    final timestamp = trip.exitTimestamp ?? trip.entryTimestamp;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'LKR ${trip.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF8ED8FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.userEmail,
            style: const TextStyle(color: Color(0xFFB8C0D9), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(text: '${trip.entryGate} -> ${trip.exitGate ?? '-'}'),
              _Tag(text: trip.vehiclePlateNumber),
              _Tag(text: trip.vehicleCategory.label),
              _Tag(text: DateFormat('d MMM yyyy, h:mm a').format(timestamp)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.item});

  final _VehicleInsight item;

  @override
  Widget build(BuildContext context) {
    final vehicle = item.record.vehicle;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                vehicle.category.label,
                style: const TextStyle(
                  color: Color(0xFF8ED8FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.userEmail,
            style: const TextStyle(color: Color(0xFFB8C0D9), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(text: vehicle.plateNumber),
              if (vehicle.nickname.trim().isNotEmpty)
                _Tag(text: vehicle.nickname),
              _Tag(text: DateFormat('d MMM yyyy, h:mm a').format(vehicle.createdAt)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFD5DCF1), fontSize: 12),
      ),
    );
  }
}

class _AdminBottomNavBar extends StatelessWidget {
  const _AdminBottomNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: _Panel(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _AdminNavItem(
              icon: Icons.space_dashboard_rounded,
              label: 'Overview',
              isActive: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
            _AdminNavItem(
              icon: Icons.directions_car_filled_rounded,
              label: 'Vehicles',
              isActive: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
            _AdminNavItem(
              icon: Icons.history_rounded,
              label: 'History',
              isActive: selectedIndex == 2,
              onTap: () => onSelected(2),
            ),
            _AdminNavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              isActive: selectedIndex == 3,
              onTap: () => onSelected(3),
            ),
            _AdminNavItem(
              icon: Icons.qr_code_2_rounded,
              label: 'Tolls',
              isActive: selectedIndex == 4,
              onTap: () => onSelected(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
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
    final color = isActive ? const Color(0xFF6ED4FF) : const Color(0xFFD6DCF0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageBarChart extends StatelessWidget {
  const _UsageBarChart({required this.points});

  final List<_HourInsight> points;

  @override
  Widget build(BuildContext context) {
    final maxCount = points.fold<int>(
      0,
      (current, item) => item.count > current ? item.count : current,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points
              .map(
                (point) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _UsageBar(
                    point: point,
                    maxCount: maxCount,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.point,
    required this.maxCount,
  });

  final _HourInsight point;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount == 0 ? 0.0 : point.count / maxCount;
    final barHeight = 18 + (ratio * 118);

    return SizedBox(
      width: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${point.count}',
            style: const TextStyle(
              color: Color(0xFFA8B2CF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 18,
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF4B6BEB),
                  Color(0xFF73D6FF),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            point.shortLabel,
            style: const TextStyle(
              color: Color(0xFFD6DCF0),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportBullet extends StatelessWidget {
  const _ReportBullet({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Color(0xFF6ED4FF),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFFD4DAEE),
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFFBBC2D9), height: 1.5),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF171A29).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _BlockedAdminScreen extends StatelessWidget {
  const _BlockedAdminScreen({this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _Panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin access only',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email == null
                      ? 'This screen is reserved for the configured admin account.'
                      : '$email is not allowed to open the admin dashboard.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC6CDDF),
                    height: 1.5,
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

class _AdminErrorPanel extends StatelessWidget {
  const _AdminErrorPanel({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final projectId =
        Firebase.apps.isEmpty ? 'Firebase not initialized' : Firebase.app().options.projectId;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                'Admin analytics could not load',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                FirebaseAuthService.instance.messageFromError(
                  error ?? StateError('Unknown admin dashboard error.'),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC5CBDF),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              if (error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    'Raw error: $error',
                    style: const TextStyle(
                      color: Color(0xFF9FAAC8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              if (error != null) const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
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
                      'Admin debug info',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${user?.email ?? 'Not signed in'}',
                      style: const TextStyle(
                        color: Color(0xFFD3D8EA),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UID: ${user?.uid ?? 'Unavailable'}',
                      style: const TextStyle(
                        color: Color(0xFFD3D8EA),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Project: $projectId',
                      style: const TextStyle(
                        color: Color(0xFFD3D8EA),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'If you see permission denied here, the admin account also needs Firestore rules that allow reading all users and trip collections.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF97A3C5),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAnalytics {
  _AdminAnalytics({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalVehicles,
    required this.usersWithVehicles,
    required this.completedTrips,
    required this.activeTrips,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.todayTrips,
    required this.averageFare,
    required this.busyHours,
    required this.usageByHour,
    required this.topRoutes,
    required this.topEntryGates,
    required this.recentUsers,
    required this.recentVehicles,
    required this.recentHistory,
  });

  final int totalUsers;
  final int activeUsers;
  final int totalVehicles;
  final int usersWithVehicles;
  final int completedTrips;
  final int activeTrips;
  final double totalRevenue;
  final double averageFare;
  final List<_HourInsight> busyHours;
  final List<_HourInsight> usageByHour;
  final List<_CountInsight> topRoutes;
  final List<_CountInsight> topEntryGates;
  final List<AdminUserAccount> recentUsers;
  final List<_VehicleInsight> recentVehicles;
  final List<_HistoryInsight> recentHistory;

  String get totalRevenueLabel => 'LKR ${totalRevenue.toStringAsFixed(2)}';
  String get averageFareLabel => 'LKR ${averageFare.toStringAsFixed(2)}';
  String get topRouteLabel =>
      topRoutes.isEmpty ? 'No trip data yet' : topRoutes.first.label;
  String get topGateLabel =>
      topEntryGates.isEmpty ? 'No gate data yet' : topEntryGates.first.label;
  int get maxHourCount => busyHours.isEmpty ? 0 : busyHours.first.count;
  String get todayRevenueLabel => 'LKR ${todayRevenue.toStringAsFixed(2)}';
  String get peakHourLabel {
    if (usageByHour.every((item) => item.count == 0)) {
      return 'No usage';
    }

    final peak = usageByHour.reduce(
      (a, b) => a.count >= b.count ? a : b,
    );
    return peak.label;
  }

  String get peakHourSummary {
    if (usageByHour.every((item) => item.count == 0)) {
      return 'No trips recorded yet.';
    }

    final peak = usageByHour.reduce(
      (a, b) => a.count >= b.count ? a : b,
    );
    return '${peak.label} with ${peak.count} trips started.';
  }

  final double todayRevenue;
  final int todayTrips;

  factory _AdminAnalytics.fromData({
    required List<AdminUserAccount> users,
    required List<AdminVehicleRecord> vehicles,
    required List<AdminTripRecord> trips,
  }) {
    final userById = {for (final user in users) user.uid: user};
    final completed = trips
        .where((item) => item.trip.status == TripStatus.completed)
        .toList(growable: false);
    final activeTrips =
        trips.where((item) => item.trip.status == TripStatus.active).length;
    final totalRevenue = completed.fold<double>(
      0,
      (sum, item) => sum + item.trip.amount,
    );
    final averageFare = completed.isEmpty
        ? 0.0
        : totalRevenue / completed.length;
    final now = DateTime.now();
    var todayRevenue = 0.0;
    var todayTrips = 0;

    final hourCounts = <int, int>{};
    final routeCounts = <String, int>{};
    final gateCounts = <String, int>{};

    for (final item in completed) {
      final tripDay = item.trip.exitTimestamp ?? item.trip.entryTimestamp;
      if (_isSameDay(tripDay, now)) {
        todayRevenue += item.trip.amount;
        todayTrips += 1;
      }

      hourCounts.update(
        item.trip.entryTimestamp.hour,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      gateCounts.update(
        item.trip.entryGate,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if ((item.trip.exitGate ?? '').isNotEmpty) {
        final route = '${item.trip.entryGate} -> ${item.trip.exitGate}';
        routeCounts.update(route, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    List<_CountInsight> sortCounts(Map<String, int> source) {
      final list = source.entries
          .map((entry) => _CountInsight(label: entry.key, count: entry.value))
          .toList(growable: false);
      list.sort((a, b) {
        final countCompare = b.count.compareTo(a.count);
        return countCompare != 0 ? countCompare : a.label.compareTo(b.label);
      });
      return list;
    }

    final hours = hourCounts.entries
        .map((entry) => _HourInsight(hour: entry.key, count: entry.value))
        .toList(growable: false)
      ..sort((a, b) {
        final countCompare = b.count.compareTo(a.count);
        return countCompare != 0 ? countCompare : a.hour.compareTo(b.hour);
      });

    final usageByHour = List<_HourInsight>.generate(
      24,
      (hour) => _HourInsight(
        hour: hour,
        count: hourCounts[hour] ?? 0,
      ),
      growable: false,
    );

    final history = completed
        .map(
          (item) => _HistoryInsight(
            record: item,
            userName: userById[item.userId]?.displayName ?? 'Unknown user',
            userEmail: userById[item.userId]?.email ?? 'Email unavailable',
          ),
        )
        .toList(growable: false);
    history.sort((a, b) {
      final aTime = a.record.trip.exitTimestamp ?? a.record.trip.entryTimestamp;
      final bTime = b.record.trip.exitTimestamp ?? b.record.trip.entryTimestamp;
      return bTime.compareTo(aTime);
    });

    final recentVehicles = vehicles
        .map(
          (item) => _VehicleInsight(
            record: item,
            userName: userById[item.userId]?.displayName ?? 'Unknown user',
            userEmail: userById[item.userId]?.email ?? 'Email unavailable',
          ),
        )
        .toList(growable: false);
    recentVehicles.sort(
      (a, b) => b.record.vehicle.createdAt.compareTo(a.record.vehicle.createdAt),
    );

    return _AdminAnalytics(
      totalUsers: users.length,
      activeUsers: completed.map((item) => item.userId).toSet().length,
      totalVehicles: vehicles.length,
      usersWithVehicles: vehicles.map((item) => item.userId).toSet().length,
      completedTrips: completed.length,
      activeTrips: activeTrips,
      totalRevenue: totalRevenue,
      todayRevenue: todayRevenue,
      todayTrips: todayTrips,
      averageFare: averageFare,
      busyHours: hours.take(min(4, hours.length)).toList(growable: false),
      usageByHour: usageByHour,
      topRoutes: sortCounts(routeCounts)
          .take(min(5, routeCounts.length))
          .toList(growable: false),
      topEntryGates: sortCounts(gateCounts)
          .take(min(5, gateCounts.length))
          .toList(growable: false),
      recentUsers: users.take(min(5, users.length)).toList(growable: false),
      recentVehicles: recentVehicles,
      recentHistory: history,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _HourInsight {
  const _HourInsight({
    required this.hour,
    required this.count,
  });

  final int hour;
  final int count;

  String get label {
    final period = hour >= 12 ? 'PM' : 'AM';
    final value = hour % 12 == 0 ? 12 : hour % 12;
    return '$value:00 $period';
  }

  String get shortLabel {
    final period = hour >= 12 ? 'P' : 'A';
    final value = hour % 12 == 0 ? 12 : hour % 12;
    return '$value$period';
  }
}

class _CountInsight {
  const _CountInsight({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;
}

class _HistoryInsight {
  const _HistoryInsight({
    required this.record,
    required this.userName,
    required this.userEmail,
  });

  final AdminTripRecord record;
  final String userName;
  final String userEmail;
}

class _VehicleInsight {
  const _VehicleInsight({
    required this.record,
    required this.userName,
    required this.userEmail,
  });

  final AdminVehicleRecord record;
  final String userName;
  final String userEmail;
}
