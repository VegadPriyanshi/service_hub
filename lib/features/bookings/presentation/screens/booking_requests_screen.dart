
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BookingRequestsScreen extends StatelessWidget {
  const BookingRequestsScreen({super.key});

  Future<void> _updateStatus(
      BuildContext context,
      String bookingId,
      String status,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});

      if (!context.mounted) return;

      final message = switch (status) {
        'accepted' => 'Booking accepted successfully.',
        'rejected' => 'Booking rejected.',
        'completed' => 'Booking marked as completed!',
        _ => 'Booking status updated.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Permission denied. Check Firestore security rules.'
                : 'Could not update booking. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Bookings')),
        body: const Center(
          child: Text('Please log in again.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('providerId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Could not load booking requests. '
                        'Check your connection and Firestore rules.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data?.docs.toList() ?? [];

            docs.sort((a, b) {
              final aDate = a.data()['createdAt'];
              final bDate = b.data()['createdAt'];

              final aMillis = aDate is Timestamp
                  ? aDate.millisecondsSinceEpoch
                  : 0;
              final bMillis = bDate is Timestamp
                  ? bDate.millisecondsSinceEpoch
                  : 0;

              return bMillis.compareTo(aMillis);
            });

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 64,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Booking Requests Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Customer booking requests will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();

                final serviceName =
                    data['serviceName'] as String? ?? 'Service';
                final category = data['category'] as String? ?? '';

                // Customer contact snapshot stored with this booking.
                final customerName =
                    data['customerName'] as String? ?? 'Not available';
                final customerPhone =
                    data['customerPhone'] as String? ?? 'Not available';
                final customerProfileAddress =
                    data['customerProfileAddress'] as String? ??
                        'Not available';

                // Address entered for this specific service booking.
                final serviceAddress =
                    data['address'] as String? ?? 'Not provided';
                final notes = data['notes'] as String? ?? '';
                final status = data['status'] as String? ?? 'pending';
                final price = (data['price'] as num?)?.toDouble() ?? 0;
                final duration =
                    (data['durationMinutes'] as num?)?.toInt() ?? 0;
                final bookingDate = data['bookingDate'];

                String dateText = 'Date not available';

                if (bookingDate is Timestamp) {
                  final date = bookingDate.toDate();
                  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
                  final minute = date.minute.toString().padLeft(2, '0');
                  final period = date.hour >= 12 ? 'PM' : 'AM';

                  dateText =
                  '${date.day.toString().padLeft(2, '0')}/'
                      '${date.month.toString().padLeft(2, '0')}/'
                      '${date.year}  •  $hour:$minute $period';
                }

                final statusColor = switch (status) {
                  'accepted' => Colors.green,
                  'completed' => Colors.blue,
                  'rejected' => Colors.red,
                  _ => const Color(0xFFDA8A00),
                };

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service heading and booking status.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.home_repair_service_rounded,
                              color: Color(0xFF6653E8),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  serviceName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 28),

                      // Customer contact details.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Customer Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _BookingInfoRow(
                              icon: Icons.person_rounded,
                              text: customerName,
                            ),
                            const SizedBox(height: 12),
                            _BookingInfoRow(
                              icon: Icons.phone_outlined,
                              text: customerPhone,
                            ),
                            const SizedBox(height: 12),
                            _BookingInfoRow(
                              icon: Icons.home_outlined,
                              text: 'Profile address: $customerProfileAddress',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Booking details.
                      const Text(
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _BookingInfoRow(
                        icon: Icons.calendar_month_rounded,
                        text: dateText,
                      ),
                      const SizedBox(height: 12),
                      _BookingInfoRow(
                        icon: Icons.schedule_rounded,
                        text: '$duration minutes',
                      ),
                      const SizedBox(height: 12),
                      _BookingInfoRow(
                        icon: Icons.location_on_outlined,
                        text: 'Service address: $serviceAddress',
                      ),

                      if (notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _BookingInfoRow(
                          icon: Icons.notes_rounded,
                          text: notes,
                        ),
                      ],

                      // Pending bookings: Accept or Reject.
                      if (status == 'pending') ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(
                                  context,
                                  doc.id,
                                  'rejected',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(
                                  context,
                                  doc.id,
                                  'accepted',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                ),
                                child: const Text('Accept'),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Accepted bookings: Mark as Completed.
                      if (status == 'accepted') ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus(
                              context,
                              doc.id,
                              'completed',
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: const Text('Mark as Completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (status == 'completed') ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This service has been completed.',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BookingInfoRow extends StatelessWidget {
  const _BookingInfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
