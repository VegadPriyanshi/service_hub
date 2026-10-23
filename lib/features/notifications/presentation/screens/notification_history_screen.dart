
import 'package:flutter/material.dart';
import 'package:service_hub/features/bookings/presentation/screens/my_bookings_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/notification_repository.dart';
import '../../domain/notification_model.dart';

class NotificationHistoryScreen extends StatefulWidget {
const NotificationHistoryScreen({super.key});

@override
State<NotificationHistoryScreen> createState() =>
_NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
extends State<NotificationHistoryScreen> {
final NotificationRepository _repository = NotificationRepository();

bool _markingAllAsRead = false;

Future<void> _markAllAsRead() async {
if (_markingAllAsRead) return;

setState(() {
_markingAllAsRead = true;
});

try {
await _repository.markAllAsRead();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('All notifications marked as read.'),
),
);
} catch (error) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Could not update notifications. Please try again.',
),
),
);

debugPrint('Mark all notifications as read error: $error');
} finally {
if (mounted) {
setState(() {
_markingAllAsRead = false;
});
}
}
}

Future<void> _markAsRead(NotificationModel notification) async {
if (notification.isRead) return;

try {
await _repository.markAsRead(notification.id);
} catch (error) {
debugPrint('Mark notification as read error: $error');
}
}

/// Opens My Bookings when the user taps a notification.
Future<void> _openNotification(
NotificationModel notification,
) async {
// Mark the selected notification as read.
await _markAsRead(notification);

if (!mounted) return;

// Open the customer's bookings.
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const MyBookingsScreen(),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF6F7FB),
appBar: AppBar(
title: const Text(
'Notifications',
style: TextStyle(fontWeight: FontWeight.bold),
),
backgroundColor: AppColors.surface,
foregroundColor: AppColors.textPrimary,
elevation: 0,
actions: [
TextButton(
onPressed: _markingAllAsRead ? null : _markAllAsRead,
child: _markingAllAsRead
? const SizedBox(
height: 18,
width: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Text(
'Mark all read',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
),
const SizedBox(width: 8),
],
),
body: SafeArea(
child: StreamBuilder<List<NotificationModel>>(
stream: _repository.watchNotifications(),
builder: (context, snapshot) {
if (snapshot.hasError) {
return _buildMessageState(
icon: Icons.error_outline_rounded,
title: 'Something went wrong',
message:
'Could not load notifications. Please try again.',
);
}

if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

final notifications =
snapshot.data ?? <NotificationModel>[];

if (notifications.isEmpty) {
return _buildMessageState(
icon: Icons.notifications_none_rounded,
title: 'No notifications yet',
message: 'Your booking updates will appear here.',
);
}

final unreadCount =
notifications.where((item) => !item.isRead).length;

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_buildSummaryCard(
total: notifications.length,
unread: unreadCount,
),
Padding(
padding: const EdgeInsets.fromLTRB(
16,
12,
16,
8,
),
child: Text(
'RECENT ACTIVITY',
style: TextStyle(
color: AppColors.textSecondary,
fontSize: 12,
fontWeight: FontWeight.bold,
letterSpacing: 1,
),
),
),
Expanded(
child: ListView.separated(
padding: const EdgeInsets.fromLTRB(
16,
4,
16,
24,
),
itemCount: notifications.length,
separatorBuilder: (_, index) =>
const SizedBox(height: 10),
itemBuilder: (context, index) {
final notification = notifications[index];

return _buildNotificationCard(notification);
},
),
),
],
);
},
),
),
);
}

Widget _buildSummaryCard({
required int total,
required int unread,
}) {
return Container(
width: double.infinity,
margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
child: Row(
children: [
Container(
height: 54,
width: 54,
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.18),
borderRadius: BorderRadius.circular(16),
),
child: const Icon(
Icons.notifications_active_rounded,
color: Colors.white,
size: 29,
),
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Stay up to date',
style: TextStyle(
color: Colors.white,
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 5),
Text(
'$total notifications · $unread unread',
style: const TextStyle(
color: Colors.white70,
fontSize: 13,
),
),
],
),
),
],
),
);
}

Widget _buildNotificationCard(
NotificationModel notification,
) {
final isUnread = !notification.isRead;
final color = _notificationColor(notification.type);

return Material(
color: isUnread
? const Color(0xFFEDE9FE)
    : Colors.white,
borderRadius: BorderRadius.circular(18),
child: InkWell(
borderRadius: BorderRadius.circular(18),
onTap: () => _openNotification(notification),
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: isUnread
? AppColors.primary.withValues(alpha: 0.25)
    : AppColors.divider,
),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
height: 46,
width: 46,
decoration: BoxDecoration(
color: color.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(14),
),
child: Icon(
_notificationIcon(notification.title),
color: color,
size: 24,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Text(
notification.title,
style: TextStyle(
fontSize: 15,
fontWeight: isUnread
? FontWeight.bold
    : FontWeight.w600,
color: AppColors.textPrimary,
),
),
),
if (isUnread)
Container(
margin: const EdgeInsets.only(
top: 5,
left: 8,
),
height: 8,
width: 8,
decoration: const BoxDecoration(
color: AppColors.primary,
shape: BoxShape.circle,
),
),
],
),
const SizedBox(height: 6),
Text(
notification.body,
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 13,
height: 1.45,
),
),
const SizedBox(height: 10),
Row(
children: [
const Icon(
Icons.access_time_rounded,
size: 14,
color: AppColors.textSecondary,
),
const SizedBox(width: 5),
Expanded(
child: Text(
_formatDate(notification.createdAt),
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 11,
),
),
),
if (isUnread)
const Text(
'NEW',
style: TextStyle(
color: AppColors.primary,
fontSize: 10,
fontWeight: FontWeight.bold,
letterSpacing: 0.5,
),
),
],
),
const SizedBox(height: 8),
const Row(
mainAxisSize: MainAxisSize.min,
children: [
Text(
'View bookings',
style: TextStyle(
color: AppColors.primary,
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
SizedBox(width: 4),
Icon(
Icons.arrow_forward_rounded,
size: 14,
color: AppColors.primary,
),
],
),
],
),
),
],
),
),
),
);
}

IconData _notificationIcon(String title) {
final value = title.toLowerCase();

if (value.contains('accepted')) {
return Icons.check_circle_rounded;
}

if (value.contains('rejected')) {
return Icons.cancel_rounded;
}

if (value.contains('completed')) {
return Icons.task_alt_rounded;
}

return Icons.notifications_active_rounded;
}

Color _notificationColor(String type) {
switch (type.toLowerCase()) {
case 'booking_update':
return AppColors.primary;
default:
return const Color(0xFF0D9488);
}
}

String _formatDate(DateTime? date) {
if (date == null) return 'Just now';

final localDate = date.toLocal();
final now = DateTime.now();
final difference = now.difference(localDate);

if (difference.inSeconds < 60 &&
!difference.isNegative) {
return 'Just now';
}

if (difference.inMinutes < 60 &&
!difference.isNegative) {
return '${difference.inMinutes} min ago';
}

if (difference.inHours < 24 &&
!difference.isNegative) {
return '${difference.inHours} hr ago';
}

final day = localDate.day.toString().padLeft(2, '0');
final month = localDate.month.toString().padLeft(2, '0');
final year = localDate.year;

return '$day/$month/$year';
}

Widget _buildMessageState({
required IconData icon,
required String title,
required String message,
}) {
return Center(
child: Padding(
padding: const EdgeInsets.all(28),
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
}
