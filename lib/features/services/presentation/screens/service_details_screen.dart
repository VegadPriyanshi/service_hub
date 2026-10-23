
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/service_model.dart';
import '../../../bookings/presentation/screens/booking_form_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  const ServiceDetailsScreen({
    super.key,
    required this.service,
  });

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      size: 42,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      service.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '₹${service.price.toStringAsFixed(0)} • '
                          '${service.durationMinutes} minutes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                'About This Service',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _InfoContainer(
                child: Text(
                  service.description.trim().isEmpty
                      ? 'No description has been provided for this service.'
                      : service.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Service Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              _DetailRow(
                icon: Icons.currency_rupee_rounded,
                title: 'Service Price',
                value: '₹${service.price.toStringAsFixed(0)}',
                iconColor: const Color(0xFF6653E8),
                iconBackground: const Color(0xFFEDE9FE),
              ),
              const SizedBox(height: 12),

              _DetailRow(
                icon: Icons.schedule_rounded,
                title: 'Estimated Duration',
                value: '${service.durationMinutes} minutes',
                iconColor: const Color(0xFF0284C7),
                iconBackground: const Color(0xFFE0F2FE),
              ),
              const SizedBox(height: 12),

              _DetailRow(
                icon: Icons.verified_rounded,
                title: 'Availability',
                value: service.isActive ? 'Available' : 'Unavailable',
                iconColor: service.isActive
                    ? const Color(0xFF15803D)
                    : Colors.grey,
                iconBackground: service.isActive
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF1F5F9),
              ),

              const SizedBox(height: 26),

              const Text(
                'About the Provider',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Load the provider's business profile from Firestore.
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(service.providerId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const _InfoContainer(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const _InfoContainer(
                      child: Text(
                        'Provider information is currently unavailable.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data?.data();

                  if (data == null) {
                    return const _InfoContainer(
                      child: Text(
                        'Business profile has not been added yet.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  final businessName =
                      (data['businessName'] as String?)?.trim() ?? '';
                  final phone =
                      (data['businessPhone'] as String?)?.trim() ?? '';
                  final address =
                      (data['businessAddress'] as String?)?.trim() ?? '';
                  final description =
                      (data['businessDescription'] as String?)?.trim() ?? '';
                  final workingHours =
                      (data['workingHours'] as String?)?.trim() ?? '';
                  final experience = data['experienceYears'];

                  return _InfoContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                businessName.isEmpty
                                    ? 'Service Provider'
                                    : businessName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (experience is num) ...[
                          const SizedBox(height: 18),
                          _ProviderInfoLine(
                            icon: Icons.workspace_premium_outlined,
                            label: 'Experience',
                            value: '${experience.toInt()} years',
                          ),
                        ],

                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _ProviderInfoLine(
                            icon: Icons.phone_outlined,
                            label: 'Business Phone',
                            value: phone,
                          ),
                        ],

                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _ProviderInfoLine(
                            icon: Icons.location_on_outlined,
                            label: 'Business Address',
                            value: address,
                          ),
                        ],

                        if (workingHours.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _ProviderInfoLine(
                            icon: Icons.access_time_rounded,
                            label: 'Working Hours',
                            value: workingHours,
                          ),
                        ],

                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Divider(),
                          const SizedBox(height: 10),
                          const Text(
                            'About the Business',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],

                        if (businessName.isEmpty &&
                            phone.isEmpty &&
                            address.isEmpty &&
                            description.isEmpty &&
                            workingHours.isEmpty &&
                            experience == null) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'The provider has not completed their business profile.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 30,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Review the service and provider details before booking.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: service.isActive
                      ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BookingFormScreen(
                          service: service,
                        ),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    service.isActive ? 'Book Now' : 'Service Unavailable',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoContainer extends StatelessWidget {
  const _InfoContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

class _ProviderInfoLine extends StatelessWidget {
  const _ProviderInfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
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
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
