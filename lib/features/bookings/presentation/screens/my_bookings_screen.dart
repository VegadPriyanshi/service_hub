
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../notifications/data/local_notification_service.dart';
import '../../../notifications/data/notification_repository.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    this.initialBookingId,
  });

  final String? initialBookingId;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Pending',
    'Accepted',
    'Rejected',
    'Completed',
  ];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _bookingStatusSubscription;

  final Map<String, String> _previousBookingStatuses = {};

  bool _hasReceivedInitialBookingSnapshot = false;

  @override
  void initState() {
    super.initState();
    _listenForBookingStatusChanges();
  }

  void _listenForBookingStatusChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _bookingStatusSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: user.uid)
        .snapshots()
        .listen(
          (snapshot) async {
        if (!_hasReceivedInitialBookingSnapshot) {
          for (final doc in snapshot.docs) {
            final data = doc.data();

            _previousBookingStatuses[doc.id] =
                (data['status'] ?? 'pending')
                    .toString()
                    .toLowerCase();
          }

          _hasReceivedInitialBookingSnapshot = true;
          return;
        }

        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.modified) {
            continue;
          }

          final doc = change.doc;
          final Map<String, dynamic>? data = doc.data();

          // FIX: document data can be null.
          if (data == null) continue;

          final newStatus =
          (data['status'] ?? '').toString().toLowerCase();

          final oldStatus = _previousBookingStatuses[doc.id];

          _previousBookingStatuses[doc.id] = newStatus;

          if (oldStatus == null || oldStatus == newStatus) {
            continue;
          }

          String? title;
          String? body;

          final serviceName =
          (data['serviceName'] ?? 'service').toString();

          switch (newStatus) {
            case 'accepted':
              title = 'Booking Accepted';
              body = 'Your $serviceName booking has been accepted.';
              break;

            case 'rejected':
              title = 'Booking Rejected';
              body = 'Your $serviceName booking has been rejected.';
              break;

            case 'completed':
              title = 'Service Completed';
              body = 'Your $serviceName has been completed.';
              break;

            default:
              continue;
          }

          try {
            await NotificationRepository().saveNotification(
              userId: user.uid,
              title: title,
              body: body,
              bookingId: doc.id,
              type: 'booking_update',
            );
          } catch (error) {
            debugPrint('Failed to save notification: $error');
          }

          try {
            await LocalNotificationService.instance.showNotification(
              id: doc.id.hashCode & 0x7fffffff,
              title: title,
              body: body,
              payload: doc.id,
            );
          } catch (error) {
            debugPrint('Booking notification error: $error');
          }
        }
      },
      onError: (Object error) {
        debugPrint('Booking status listener error: $error');
      },
    );
  }

  @override
  void dispose() {
    _bookingStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final isOpenedFromNotification =
        widget.initialBookingId != null &&
            widget.initialBookingId!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          isOpenedFromNotification ? 'Booking Details' : 'My Bookings',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: user == null
            ? const Center(
          child: Text('Please log in to view your bookings.'),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOpenedFromNotification) ...[
              _buildHeader(),
              _buildFilters(),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Booking related to your notification',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('customerId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildError();
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final bookings =
                      snapshot.data?.docs.toList() ?? [];

                  bookings.sort((a, b) {
                    final aValue = a.data()['createdAt'];
                    final bValue = b.data()['createdAt'];

                    final aTime = aValue is Timestamp
                        ? aValue.millisecondsSinceEpoch
                        : 0;

                    final bTime = bValue is Timestamp
                        ? bValue.millisecondsSinceEpoch
                        : 0;

                    return bTime.compareTo(aTime);
                  });

                  final filteredBookings = bookings.where((doc) {
                    if (isOpenedFromNotification) {
                      return doc.id == widget.initialBookingId;
                    }

                    if (selectedFilter == 'All') return true;

                    final status = (doc.data()['status'] ?? '')
                        .toString()
                        .toLowerCase();

                    return status == selectedFilter.toLowerCase();
                  }).toList();

                  if (bookings.isEmpty) {
                    return _buildEmptyState(
                      title: 'No Bookings Yet',
                      message:
                      'Your service bookings will appear here.',
                      icon: Icons.calendar_month_rounded,
                    );
                  }

                  if (filteredBookings.isEmpty) {
                    if (isOpenedFromNotification) {
                      return _buildEmptyState(
                        title: 'Booking Not Found',
                        message:
                        'This booking may have been removed or is no longer available.',
                        icon: Icons.search_off_rounded,
                      );
                    }

                    return _buildEmptyState(
                      title:
                      'No ${selectedFilter.toLowerCase()} bookings',
                      message:
                      'Try selecting another status filter.',
                      icon: Icons.filter_list_rounded,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      24,
                    ),
                    itemCount: filteredBookings.length,
                    separatorBuilder: (_, index) =>
                    const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final doc = filteredBookings[index];

                      return _buildBookingCard(
                        doc.id,
                        doc.data(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFF8174F5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Service Bookings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'View your bookings and track their status.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 42,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) {
              setState(() {
                selectedFilter = filter;
              });
            },
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.divider,
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(
      String bookingId,
      Map<String, dynamic> data,
      ) {
    final serviceName =
    (data['serviceName'] ?? 'Service').toString();
    final category = (data['category'] ?? '').toString();
    final address = (data['address'] ?? '').toString();
    final notes = (data['notes'] ?? '').toString();

    final status =
    (data['status'] ?? 'pending').toString().toLowerCase();

    final price = data['price'] is num
        ? (data['price'] as num).toDouble()
        : double.tryParse('${data['price']}') ?? 0;

    final duration = data['durationMinutes'] is num
        ? (data['durationMinutes'] as num).toInt()
        : 0;

    final dateText = _formatDate(data['bookingDate']);
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  size: 27,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
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
          _buildInfoRow(
            Icons.calendar_month_rounded,
            'Booking date',
            dateText,
          ),
          const SizedBox(height: 13),
          _buildInfoRow(
            Icons.schedule_rounded,
            'Duration',
            '$duration minutes',
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 13),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Service address',
              address,
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 13),
            _buildInfoRow(
              Icons.notes_rounded,
              'Notes',
              notes,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusMessage(status),
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Booking ID: ${_shortId(bookingId)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 45,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load your bookings.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return const Color(0xFFDA8A00);
    }
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'accepted':
        return 'Your booking has been accepted by the provider.';
      case 'rejected':
        return 'The provider has rejected this booking.';
      case 'completed':
        return 'Your service has been completed successfully.';
      default:
        return 'Waiting for the provider to respond.';
    }
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Date not available';
    }

    final date = value.toDate().toLocal();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }

  String _shortId(String id) {
    return id.length <= 8 ? id : id.substring(0, 8);
  }
}
