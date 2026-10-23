
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../auth/presentation/screens/change_password_screen.dart';
import '../auth/presentation/screens/delete_account_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
const BusinessProfileScreen({super.key});

@override
State<BusinessProfileScreen> createState() =>
_BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
final _formKey = GlobalKey<FormState>();

final _businessNameController = TextEditingController();
final _phoneController = TextEditingController();
final _addressController = TextEditingController();
final _experienceController = TextEditingController();
final _descriptionController = TextEditingController();
final _workingHoursController = TextEditingController();

bool _isLoading = true;
bool _isSaving = false;

String? _loadError;

DocumentReference<Map<String, dynamic>>? get _profileRef {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return null;

return FirebaseFirestore.instance.collection('users').doc(uid);
}

@override
void initState() {
super.initState();
_loadProfile();
}

Future<void> _loadProfile() async {
if (mounted) {
setState(() {
_isLoading = true;
_loadError = null;
});
}

try {
final ref = _profileRef;

if (ref == null) {
throw Exception('Please sign in again.');
}

final snapshot = await ref.get();
final data = snapshot.data() ?? <String, dynamic>{};

_businessNameController.text =
(data['businessName'] as String?) ?? '';

_phoneController.text =
(data['businessPhone'] as String?) ?? '';

_addressController.text =
(data['businessAddress'] as String?) ?? '';

_experienceController.text =
(data['experienceYears'] ?? '').toString();

_descriptionController.text =
(data['businessDescription'] as String?) ?? '';

_workingHoursController.text =
(data['workingHours'] as String?) ?? '9:00 AM - 6:00 PM';
} catch (_) {
_loadError = 'Could not load your profile. Please try again.';
} finally {
if (mounted) {
setState(() => _isLoading = false);
}
}
}

Future<void> _saveProfile() async {
if (!(_formKey.currentState?.validate() ?? false)) return;

final ref = _profileRef;

if (ref == null) {
_showMessage('Please sign in again.');
return;
}

setState(() => _isSaving = true);

try {
await ref.set({
'businessName': _businessNameController.text.trim(),
'businessPhone': _phoneController.text.trim(),
'businessAddress': _addressController.text.trim(),
'experienceYears':
int.tryParse(_experienceController.text.trim()) ?? 0,
'businessDescription': _descriptionController.text.trim(),
'workingHours': _workingHoursController.text.trim(),
'businessProfileUpdatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

if (!mounted) return;

_showMessage('Business profile saved successfully!');
} on FirebaseException catch (e) {
if (!mounted) return;

_showMessage(
e.code == 'permission-denied'
? 'Permission denied. Please check Firestore rules.'
    : 'Could not save profile. Please try again.',
);
} catch (_) {
if (!mounted) return;
_showMessage('Something went wrong. Please try again.');
} finally {
if (mounted) {
setState(() => _isSaving = false);
}
}
}

void _openChangePassword() {
Navigator.of(context).push(
MaterialPageRoute<void>(
builder: (_) => const ChangePasswordScreen(),
),
);
}

void _openDeleteAccount() {
Navigator.of(context).push(
MaterialPageRoute<void>(
builder: (_) => const DeleteAccountScreen(),
),
);
}

void _showMessage(String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(message)),
);
}

@override
void dispose() {
_businessNameController.dispose();
_phoneController.dispose();
_addressController.dispose();
_experienceController.dispose();
_descriptionController.dispose();
_workingHoursController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Business Profile'),
actions: [
IconButton(
onPressed: _isLoading ? null : _loadProfile,
tooltip: 'Reload profile',
icon: const Icon(Icons.refresh_rounded),
),
],
),
body: SafeArea(
child: _isLoading
? const Center(child: CircularProgressIndicator())
    : _loadError != null
? Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline_rounded,
size: 44,
color: AppColors.primary,
),
const SizedBox(height: 12),
Text(
_loadError!,
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
FilledButton(
onPressed: _loadProfile,
child: const Text('Try Again'),
),
],
),
),
)
    : SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: double.infinity,
padding: const EdgeInsets.all(22),
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
child: const Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.storefront_rounded,
color: Colors.white,
size: 36,
),
SizedBox(height: 14),
Text(
'Build Your Business Profile',
style: TextStyle(
color: Colors.white,
fontSize: 21,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 8),
Text(
'Help customers learn about your business and services.',
style: TextStyle(
color: Colors.white,
height: 1.5,
),
),
],
),
),

const SizedBox(height: 26),

const Text(
'Business Information',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
color: AppColors.textPrimary,
),
),

const SizedBox(height: 16),

_ProfileField(
controller: _businessNameController,
label: 'Business Name',
icon: Icons.store_rounded,
validator: (value) =>
value == null || value.trim().isEmpty
? 'Enter your business name'
    : null,
),

const SizedBox(height: 14),

_ProfileField(
controller: _phoneController,
label: 'Business Phone',
icon: Icons.phone_rounded,
keyboardType: TextInputType.phone,
inputFormatters: [
FilteringTextInputFormatter.digitsOnly,
LengthLimitingTextInputFormatter(10),
],
validator: (value) {
final phone = value?.trim() ?? '';

if (phone.isEmpty) {
return 'Enter a phone number';
}

if (!RegExp(r'^[0-9]{10}$')
    .hasMatch(phone)) {
return 'Phone number must contain exactly 10 digits';
}

return null;
},
),

const SizedBox(height: 14),

_ProfileField(
controller: _addressController,
label: 'Business Address',
icon: Icons.location_on_rounded,
maxLines: 2,
validator: (value) =>
value == null || value.trim().isEmpty
? 'Enter your business address'
    : null,
),

const SizedBox(height: 24),

const Text(
'Professional Details',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
color: AppColors.textPrimary,
),
),

const SizedBox(height: 16),

_ProfileField(
controller: _experienceController,
label: 'Experience (years)',
icon: Icons.workspace_premium_rounded,
keyboardType: TextInputType.number,
inputFormatters: [
FilteringTextInputFormatter.digitsOnly,
],
validator: (value) {
final years = int.tryParse(
value?.trim() ?? '',
);

if (years == null || years < 0) {
return 'Enter valid years of experience';
}

return null;
},
),

const SizedBox(height: 14),

_ProfileField(
controller: _descriptionController,
label: 'About Your Business',
icon: Icons.description_outlined,
maxLines: 4,
validator: (value) =>
value == null || value.trim().isEmpty
? 'Describe your business'
    : null,
),

const SizedBox(height: 14),

_ProfileField(
controller: _workingHoursController,
label: 'Working Hours',
icon: Icons.access_time_rounded,
validator: (value) =>
value == null || value.trim().isEmpty
? 'Enter your working hours'
    : null,
),

const SizedBox(height: 28),

SizedBox(
width: double.infinity,
height: 54,
child: FilledButton.icon(
onPressed: _isSaving ? null : _saveProfile,
icon: _isSaving
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Icon(Icons.save_rounded),
label: Text(
_isSaving
? 'Saving...'
    : 'Save Business Profile',
),
style: FilledButton.styleFrom(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
),
),

const SizedBox(height: 14),

SizedBox(
width: double.infinity,
height: 54,
child: OutlinedButton.icon(
onPressed: _openChangePassword,
icon: const Icon(Icons.lock_reset_rounded),
label: const Text('Change Password'),
style: OutlinedButton.styleFrom(
foregroundColor: AppColors.primary,
side: const BorderSide(
color: AppColors.primary,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
),
),

const SizedBox(height: 12),

SizedBox(
width: double.infinity,
height: 54,
child: OutlinedButton.icon(
onPressed: _openDeleteAccount,
icon: const Icon(
Icons.delete_forever_rounded,
color: Colors.red,
),
label: const Text(
'Delete Account',
style: TextStyle(color: Colors.red),
),
style: OutlinedButton.styleFrom(
side: const BorderSide(color: Colors.red),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
),
),

const SizedBox(height: 20),
],
),
),
),
),
);
}
}

class _ProfileField extends StatelessWidget {
const _ProfileField({
required this.controller,
required this.label,
required this.icon,
this.keyboardType,
this.maxLines = 1,
this.validator,
this.inputFormatters,
});

final TextEditingController controller;
final String label;
final IconData icon;
final TextInputType? keyboardType;
final int maxLines;
final String? Function(String?)? validator;
final List<TextInputFormatter>? inputFormatters;

@override
Widget build(BuildContext context) {
return TextFormField(
controller: controller,
keyboardType: keyboardType,
inputFormatters: inputFormatters,
maxLines: maxLines,
validator: validator,
decoration: InputDecoration(
labelText: label,
prefixIcon: Icon(
icon,
color: AppColors.primary,
),
filled: true,
fillColor: AppColors.surface,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide(color: AppColors.divider),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide(color: AppColors.divider),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: AppColors.primary,
width: 1.5,
),
),
),
);
}
}
