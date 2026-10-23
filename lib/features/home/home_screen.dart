
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/screens/login_screen.dart';
import '../bookings/presentation/screens/my_bookings_screen.dart';
import '../services/data/service_repository.dart';
import '../services/domain/service_model.dart';
import '../services/presentation/screens/service_details_screen.dart';
import '../profile/presentation/screens/customer_profile_screen.dart';
import '../notifications/data/notification_repository.dart';
import '../notifications/domain/notification_model.dart';
import '../notifications/presentation/screens/notification_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ServiceRepository _serviceRepository = ServiceRepository();

  final NotificationRepository _notificationRepository =
  NotificationRepository();

  late Future<List<ServiceModel>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _loadServices();
  }

  Future<List<ServiceModel>> _loadServices() {
    return _serviceRepository.getActiveServices();
  }

  void _refreshServices() {
    setState(() {
      _servicesFuture = _loadServices();
    });
  }


  Future<void> _logout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.logout_rounded,
            size: 36,
            color: Colors.redAccent,
          ),
          title: const Text('Logout?'),
          content: const Text(
            'Are you sure you want to logout? '
                'You will need to log in again to access your account.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // User cancelled or dismissed the dialog.
    if (shouldLogout != true || !mounted) return;

    try {
      await AuthRepository().logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout failed. Please try again.'),
        ),
      );
    }
  }


  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CustomerProfileScreen(),
      ),
    );
  }

  void _openServiceDetails(ServiceModel service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceDetailsScreen(service: service),
      ),
    );
  }

  void _openMyBookings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MyBookingsScreen(),
      ),
    );
  }

  void _openNotificationHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiceHub'),
        actions: [
          // Notifications with live unread count.
          StreamBuilder<List<NotificationModel>>(
            stream: _notificationRepository.watchNotifications(),
            builder: (context, snapshot) {
              final notifications =
                  snapshot.data ?? <NotificationModel>[];

              final unreadCount =
                  notifications.where((item) => !item.isRead).length;

              return IconButton(
                tooltip: 'Notifications',
                onPressed: _openNotificationHistory,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: -7,
                        top: -5,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'My Profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline_rounded),
          ),
          IconButton(
            tooltip: 'Refresh services',
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
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshServices();
            try {
              await _servicesFuture;
            } catch (_) {
              // Errors are displayed in the services section.
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome banner
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
                        Icons.home_repair_service_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your Home, Our Care',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Find trusted professionals for your home.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Welcome${user?.displayName == null ? '' : ', ${user!.displayName}'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Popular Services
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Popular Services',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _refreshServices,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                FutureBuilder<List<ServiceModel>>(
                  future: _servicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _MessageCard(
                        icon: Icons.error_outline_rounded,
                        message:
                        'Could not load services. Please check your connection and try again.',
                        actionLabel: 'Try Again',
                        onAction: _refreshServices,
                      );
                    }

                    final services =
                        snapshot.data ?? <ServiceModel>[];

                    if (services.isEmpty) {
                      return const _MessageCard(
                        icon: Icons.home_repair_service_outlined,
                        message:
                        'No services are available yet. Please check again later.',
                      );
                    }

                    return GridView.builder(
                      itemCount: services.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.90,
                      ),
                      itemBuilder: (context, index) {
                        final service = services[index];
                        final style = _styleForCategory(service.category);

                        return _ServiceCard(
                          service: service,
                          color: style.color,
                          icon: style.icon,
                          iconColor: style.iconColor,
                          onTap: () => _openServiceDetails(service),
                        );
                      },
                    );
                  },
                ),

                // My Bookings
                const SizedBox(height: 20),

                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _openMyBookings,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.divider,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Bookings',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'View your bookings and their status',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Trusted Professionals
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.divider,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trusted Professionals',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Quality service for your home.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ServiceStyle _styleForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'cleaning':
        return const _ServiceStyle(
          icon: Icons.cleaning_services_rounded,
          color: Color(0xFFEDE9FE),
          iconColor: Color(0xFF6653E8),
        );

      case 'plumbing':
        return const _ServiceStyle(
          icon: Icons.plumbing_rounded,
          color: Color(0xFFE0F2FE),
          iconColor: Color(0xFF0284C7),
        );

      case 'electrical':
        return const _ServiceStyle(
          icon: Icons.electrical_services_rounded,
          color: Color(0xFFFFF0D9),
          iconColor: Color(0xFFDA8A00),
        );

      case 'painting':
        return const _ServiceStyle(
          icon: Icons.format_paint_rounded,
          color: Color(0xFFFFE4E6),
          iconColor: Color(0xFFE54865),
        );

      default:
        return const _ServiceStyle(
          icon: Icons.home_repair_service_rounded,
          color: Color(0xFFEDE9FE),
          iconColor: Color(0xFF6653E8),
        );
    }
  }
}

class _ServiceStyle {
  const _ServiceStyle({
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final ServiceModel service;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 27,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '₹${service.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${service.durationMinutes} min',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
