
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../services/data/service_repository.dart';
import '../services/domain/service_model.dart';
import '../services/presentation/screens/add_service_screen.dart';
import '../services/presentation/screens/my_services_screen.dart';
import '../bookings/presentation/screens/booking_requests_screen.dart';
import '../notifications/data/local_notification_service.dart';
import 'business_profile_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final ServiceRepository _serviceRepository = ServiceRepository();

  late Future<List<ServiceModel>> _servicesFuture;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _bookingSubscription;

  bool _hasReceivedInitialBookingSnapshot = false;

  @override
  void initState() {
    super.initState();

    _servicesFuture = _loadServices();
    _listenForNewBookings();
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    super.dispose();
  }

  Future<List<ServiceModel>> _loadServices() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return <ServiceModel>[];
    }

    return _serviceRepository.getProviderServices(user.uid);
  }



  void _listenForNewBookings() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    _bookingSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) async {
        if (!_hasReceivedInitialBookingSnapshot) {
          _hasReceivedInitialBookingSnapshot = true;
          return;
        }

        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) {
            continue;
          }

          final booking = change.doc.data();

          if (booking == null || booking['status'] != 'pending') {
            continue;
          }

          final serviceName =
              booking['serviceName'] as String? ?? 'Service';

          final customerName =
              booking['customerName'] as String? ?? 'A customer';

          try {
            await LocalNotificationService.instance.showNotification(
              id: change.doc.id.hashCode & 0x7fffffff,
              title: 'New Booking Request',
              body: '$customerName booked $serviceName.',
              payload: change.doc.id,
            );
          } catch (error) {
            debugPrint('Booking notification error: $error');
          }
        }
      },
      onError: (Object error) {
        debugPrint('Booking listener error: $error');
      },
    );
  }



  void _refreshServices() {
    setState(() {
      _servicesFuture = _loadServices();
    });
  }

  Future<void> _logout() async {
    await AuthRepository().logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  Future<void> _openAddService() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AddServiceScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      _refreshServices();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service added successfully!'),
        ),
      );
    }
  }

  Future<void> _openMyServices() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const MyServicesScreen(),
      ),
    );

    if (mounted) {
      _refreshServices();
    }
  }

  void _openBookingRequests() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BookingRequestsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refreshServices,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFF8174F5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.handyman_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Grow Your Service Business',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome${user?.displayName == null ? '' : ', ${user!.displayName}'}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your services and customer bookings in one place.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Overview heading
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // Live statistics from Firestore
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('providerId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _InfoCard(
                      icon: Icons.error_outline_rounded,
                      message:
                      'Could not load booking statistics. Please refresh.',
                    );
                  }

                  final bookings = snapshot.data?.docs ?? [];

                  final pendingCount = bookings.where((booking) {
                    return booking.data()['status'] == 'pending';
                  }).length;

                  final completedBookings = bookings.where((booking) {
                    return booking.data()['status'] == 'completed';
                  }).toList();

                  final completedCount = completedBookings.length;

                  final totalEarnings = completedBookings.fold<double>(
                    0,
                        (total, booking) {
                      final price = booking.data()['price'];

                      return total +
                          (price is num ? price.toDouble() : 0);
                    },
                  );

                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _OverviewCard(
                              title: 'New Bookings',
                              value: isLoading ? '...' : '$pendingCount',
                              icon: Icons.calendar_month_rounded,
                              color: const Color(0xFFEDE9FE),
                              iconColor: const Color(0xFF6653E8),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _OverviewCard(
                              title: 'Completed',
                              value: isLoading ? '...' : '$completedCount',
                              icon: Icons.task_alt_rounded,
                              color: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _OverviewCard(
                              title: 'Total Earnings',
                              value: isLoading
                                  ? '...'
                                  : '₹${totalEarnings.toStringAsFixed(0)}',
                              icon: Icons.currency_rupee_rounded,
                              color: const Color(0xFFFFF0D9),
                              iconColor: const Color(0xFFDA8A00),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: FutureBuilder<List<ServiceModel>>(
                              future: _servicesFuture,
                              builder: (context, serviceSnapshot) {
                                final count =
                                    serviceSnapshot.data?.length ?? 0;

                                final serviceCount =
                                serviceSnapshot.hasError
                                    ? '!'
                                    : serviceSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                    !serviceSnapshot.hasData
                                    ? '...'
                                    : '$count';

                                return _OverviewCard(
                                  title: 'My Services',
                                  value: serviceCount,
                                  icon: Icons.home_repair_service_rounded,
                                  color: const Color(0xFFE0F2FE),
                                  iconColor: const Color(0xFF0284C7),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 14),

              _ActionTile(
                icon: Icons.add_business_rounded,
                title: 'Add a Service',
                subtitle: 'List a service for customers',
                onTap: _openAddService,
              ),

              const SizedBox(height: 12),

              _ActionTile(
                icon: Icons.event_note_rounded,
                title: 'Manage Bookings',
                subtitle: 'View and manage customer requests',
                onTap: _openBookingRequests,
              ),

              const SizedBox(height: 12),

              _ActionTile(
                icon: Icons.person_outline_rounded,
                title: 'Business Profile',
                subtitle: 'Manage your professional details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BusinessProfileScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Interactive My Services master card
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _openMyServices,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.home_repair_service_rounded,
                            color: Color(0xFF6653E8),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My Services',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'View and manage all your services',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<List<ServiceModel>>(
                                future: _servicesFuture,
                                builder: (context, snapshot) {
                                  final count =
                                      snapshot.data?.length ?? 0;

                                  final message = snapshot.hasError
                                      ? 'Services unavailable'
                                      : snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                      !snapshot.hasData
                                      ? 'Loading services...'
                                      : '$count services listed';

                                  return Text(
                                    message,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Business profile reminder card removed.
            ],
          ),
        ),
      ),
    );
  }
}

// Information and error card
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Overview statistic card
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Quick action tile
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
