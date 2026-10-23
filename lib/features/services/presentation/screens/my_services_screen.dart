
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/service_repository.dart';
import '../../domain/service_model.dart';
import 'add_service_screen.dart';

class MyServicesScreen extends StatefulWidget {
const MyServicesScreen({super.key});

@override
State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
final ServiceRepository _repository = ServiceRepository();

late Future<List<ServiceModel>> _servicesFuture;

@override
void initState() {
super.initState();
_loadServices();
}

void _loadServices() {
final user = FirebaseAuth.instance.currentUser;

_servicesFuture = user == null
? Future<List<ServiceModel>>.value([])
    : _repository.getProviderServices(user.uid);
}

Future<void> _refresh() async {
setState(_loadServices);
await _servicesFuture;
}

Future<void> _editService(ServiceModel service) async {
final result = await Navigator.of(context).push<bool>(
MaterialPageRoute<bool>(
builder: (_) => AddServiceScreen(service: service),
),
);

if (!mounted) return;

if (result == true) {
setState(_loadServices);

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Service updated successfully!'),
backgroundColor: Colors.green,
),
);
}
}

Future<void> _deleteService(ServiceModel service) async {
final confirm = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('Delete Service?'),
content: Text(
'Are you sure you want to delete "${service.name}"? '
'This action cannot be undone.',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Cancel'),
),
FilledButton(
style: FilledButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
),
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text('Delete'),
),
],
);
},
);

if (confirm != true || !mounted) return;

try {
await _repository.deleteService(service.id);

if (!mounted) return;

setState(_loadServices);

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Service deleted successfully!'),
backgroundColor: Colors.green,
),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
e.toString().contains('permission-denied')
? 'Permission denied. Check Firestore rules.'
    : 'Unable to delete service. Please try again.',
),
),
);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('My Services'),
actions: [
IconButton(
tooltip: 'Refresh services',
onPressed: _refresh,
icon: const Icon(Icons.refresh_rounded),
),
],
),
body: SafeArea(
child: FutureBuilder<List<ServiceModel>>(
future: _servicesFuture,
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting &&
!snapshot.hasData) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return _MessageView(
icon: Icons.error_outline_rounded,
message: 'Could not load services. Please try again.',
onRetry: _refresh,
);
}

final services = snapshot.data ?? [];

if (services.isEmpty) {
return const _MessageView(
icon: Icons.home_repair_service_outlined,
message: 'You have not added any services yet.',
);
}

return RefreshIndicator(
onRefresh: _refresh,
child: ListView(
padding: const EdgeInsets.all(20),
children: [
Text(
'Your Services (${services.length})',
style: const TextStyle(
fontSize: 21,
fontWeight: FontWeight.bold,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 16),
...services.map(
(service) => Padding(
padding: const EdgeInsets.only(bottom: 14),
child: _ServiceItem(
service: service,
onEdit: () => _editService(service),
onDelete: () => _deleteService(service),
),
),
),
],
),
);
},
),
),
);
}
}

class _ServiceItem extends StatelessWidget {
const _ServiceItem({
required this.service,
required this.onEdit,
required this.onDelete,
});

final ServiceModel service;
final VoidCallback onEdit;
final VoidCallback onDelete;

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: AppColors.divider),
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
size: 26,
),
),
const SizedBox(width: 14),

// Service details
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
service.name,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 5),
Text(
service.category,
style: const TextStyle(
fontSize: 13,
color: AppColors.textSecondary,
),
),
const SizedBox(height: 10),
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
'${service.durationMinutes} minutes',
style: const TextStyle(
fontSize: 12,
color: AppColors.textSecondary,
),
),
const SizedBox(height: 8),
Row(
children: [
Icon(
service.isActive
? Icons.check_circle_rounded
    : Icons.pause_circle_outline_rounded,
size: 17,
color: service.isActive
? Colors.green
    : AppColors.textSecondary,
),
const SizedBox(width: 5),
Text(
service.isActive ? 'Active' : 'Inactive',
style: TextStyle(
fontSize: 12,
color: service.isActive
? Colors.green
    : AppColors.textSecondary,
),
),
],
),
],
),
),

// Three-dot menu on the right
PopupMenuButton<String>(
tooltip: 'More options',
icon: const Icon(
Icons.more_vert_rounded,
color: AppColors.textSecondary,
size: 25,
),
padding: EdgeInsets.zero,
onSelected: (value) {
if (value == 'edit') {
onEdit();
} else if (value == 'delete') {
onDelete();
}
},
itemBuilder: (context) => [
const PopupMenuItem<String>(
value: 'edit',
child: Row(
children: [
Icon(
Icons.edit_outlined,
size: 20,
color: Color(0xFF6653E8),
),
SizedBox(width: 12),
Text('Edit'),
],
),
),
const PopupMenuItem<String>(
value: 'delete',
child: Row(
children: [
Icon(
Icons.delete_outline_rounded,
size: 20,
color: Colors.red,
),
SizedBox(width: 12),
Text(
'Delete',
style: TextStyle(color: Colors.red),
),
],
),
),
],
),
],
),
],
),
);
}
}

class _MessageView extends StatelessWidget {
const _MessageView({
required this.icon,
required this.message,
this.onRetry,
});

final IconData icon;
final String message;
final VoidCallback? onRetry;

@override
Widget build(BuildContext context) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 44,
color: AppColors.primary,
),
const SizedBox(height: 14),
Text(
message,
textAlign: TextAlign.center,
style: const TextStyle(
color: AppColors.textSecondary,
),
),
if (onRetry != null) ...[
const SizedBox(height: 12),
FilledButton(
onPressed: onRetry,
child: const Text('Try Again'),
),
],
],
),
),
);
}
}
