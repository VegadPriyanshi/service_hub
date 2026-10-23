
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Pending',
    'Accepted',
    'Rejected',
    'Completed',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookingStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: user.uid)
        .orderBy('bookingDate', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Booking History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF182230),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF182230),
        elevation: 0,
        centerTitle: false,
      ),
      body: user == null
          ? _buildSignInMessage()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _bookingStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6750E8),
                    ),
                  );
                }

                final documents =
                    snapshot.data?.docs ?? [];

                final bookings = documents.where((document) {
                  if (selectedFilter == 'All') {
                    return true;
                  }

                  final data = document.data();
                  final status = (data['status'] ?? '')
                      .toString()
                      .toLowerCase();

                  return status ==
                      selectedFilter.toLowerCase();
                }).toList();

                if (documents.isEmpty) {
                  return _buildEmptyState(
                    isFiltered: false,
                  );
                }

                if (bookings.isEmpty) {
                  return _buildEmptyState(
                    isFiltered: true,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    24,
                  ),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final document = bookings[index];

                    return _buildBookingCard(
                      document.id,
                      document.data(),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6750E8),
            Color(0xFF8B70F5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6750E8).withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Bookings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Track your service bookings in one place.',
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
            size: 48,
            color: Colors.white,
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF6750E8),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF5F6673),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF6750E8)
                  : const Color(0xFFE5E7EF),
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

    final category =
    (data['category'] ?? 'General').toString();

    final status =
    (data['status'] ?? 'pending').toString().toLowerCase();

    final address = (data['address'] ?? '').toString();
    final notes = (data['notes'] ?? '').toString();

    final price = _formatPrice(data['price']);
    final bookingDate = _formatDate(data['bookingDate']);

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFECEEF4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
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
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.home_repair_service_rounded,
                  color: Color(0xFF6750E8),
                  size: 25,
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
                        color: Color(0xFF182230),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFF7B8494),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                price,
                style: const TextStyle(
                  color: Color(0xFF6750E8),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEF0F5)),
          const SizedBox(height: 14),

          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Booking date',
            bookingDate,
          ),

          if (address.isNotEmpty) ...[
            const SizedBox(height: 11),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Service address',
              address,
            ),
          ],

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 11),
            _buildInfoRow(
              Icons.notes_rounded,
              'Notes',
              notes,
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 7,
                      width: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${_shortId(bookingId)}',
                style: const TextStyle(
                  color: Color(0xFF9299A6),
                  fontSize: 11,
                ),
              ),
            ],
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
          size: 17,
          color: const Color(0xFF8A91A0),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9299A6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF343B49),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required bool isFiltered,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EDFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_rounded,
                color: Color(0xFF6750E8),
                size: 46,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isFiltered
                  ? 'No ${selectedFilter.toLowerCase()} bookings'
                  : 'No bookings yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF182230),
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try selecting another status filter.'
                  : 'Your service bookings will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7B8494),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Please sign in to view your booking history.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load booking history',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFB7791F);
      case 'accepted':
        return const Color(0xFF16835D);
      case 'rejected':
        return const Color(0xFFD64545);
      case 'completed':
        return const Color(0xFF6750E8);
      default:
        return const Color(0xFF737B8C);
    }
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Unknown';

    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatPrice(dynamic value) {
    if (value == null) return 'Price N/A';

    if (value is num) {
      return '₹${value.toStringAsFixed(0)}';
    }

    final parsed = num.tryParse(value.toString());

    if (parsed != null) {
      return '₹${parsed.toStringAsFixed(0)}';
    }

    return '₹$value';
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Date unavailable';

    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = _monthName(localDate.month);
    final year = localDate.year;

    final hour24 = localDate.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute =
    localDate.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';

    return '$day $month $year • '
        '$hour12:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return months[month - 1];
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }
}
