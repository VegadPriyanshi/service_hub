
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../auth/presentation/screens/delete_account_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
const CustomerProfileScreen({super.key});

@override
State<CustomerProfileScreen> createState() =>
_CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
final _formKey = GlobalKey<FormState>();

final _nameController = TextEditingController();
final _emailController = TextEditingController();
final _phoneController = TextEditingController();
final _addressController = TextEditingController();

bool _isLoading = true;
bool _isSaving = false;
bool _isEditing = false;

String? _errorMessage;

User? get _user => FirebaseAuth.instance.currentUser;

DocumentReference<Map<String, dynamic>>? get _userDocument {
final user = _user;

if (user == null) return null;

return FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid);
}

@override
void initState() {
super.initState();
_loadProfile();
}

@override
void dispose() {
_nameController.dispose();
_emailController.dispose();
_phoneController.dispose();
_addressController.dispose();
super.dispose();
}

Future<void> _loadProfile() async {
if (mounted) {
setState(() {
_isLoading = true;
_errorMessage = null;
});
}

try {
final user = _user;
final document = _userDocument;

if (user == null || document == null) {
throw Exception('Please log in to view your profile.');
}

final snapshot = await document.get();
final data = snapshot.data() ?? <String, dynamic>{};

_nameController.text =
(data['name'] as String?) ?? user.displayName ?? '';

_emailController.text =
(data['email'] as String?) ?? user.email ?? '';

_phoneController.text = (data['phone'] as String?) ?? '';
_addressController.text = (data['address'] as String?) ?? '';
} catch (_) {
_errorMessage = 'Unable to load profile. Please try again.';
} finally {
if (mounted) {
setState(() => _isLoading = false);
}
}
}

Future<void> _saveProfile() async {
if (!(_formKey.currentState?.validate() ?? false)) return;

final user = _user;
final document = _userDocument;

if (user == null || document == null) {
_showMessage('Please log in again.');
return;
}

setState(() => _isSaving = true);

try {
final updatedPhone = _phoneController.text.trim();
final updatedAddress = _addressController.text.trim();
final updatedName = _nameController.text.trim();

await document.update({
'phone': updatedPhone,
'address': updatedAddress,
});

final bookingsSnapshot = await FirebaseFirestore.instance
    .collection('bookings')
    .where('customerId', isEqualTo: user.uid)
    .get();

final bookingDocs = bookingsSnapshot.docs;

for (var start = 0; start < bookingDocs.length; start += 400) {
final end = (start + 400 < bookingDocs.length)
? start + 400
    : bookingDocs.length;

final batch = FirebaseFirestore.instance.batch();

for (final booking in bookingDocs.sublist(start, end)) {
batch.update(booking.reference, {
'customerName': updatedName,
'customerPhone': updatedPhone,
'customerProfileAddress': updatedAddress,
});
}

await batch.commit();
}

if (!mounted) return;

setState(() {
_isEditing = false;
});

_showMessage(
bookingDocs.isEmpty
? 'Profile updated successfully!'
    : 'Profile and ${bookingDocs.length} booking(s) updated successfully!',
);
} on FirebaseException catch (e) {
if (!mounted) return;

final message = e.code == 'permission-denied'
? 'Permission denied. Firestore rules must allow '
'customers to update contact snapshots in their own bookings.'
    : 'Unable to save all changes. Please try again.';

_showMessage(message);
} catch (_) {
if (!mounted) return;

_showMessage(
'Unable to save all changes. Please check your connection and try again.',
);
} finally {
if (mounted) {
setState(() => _isSaving = false);
}
}
}

Future<void> _cancelEditing() async {
FocusScope.of(context).unfocus();

setState(() {
_isEditing = false;
});

await _loadProfile();
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

Widget _buildReadOnlyField({
required String label,
required String value,
required IconData icon,
}) {
return Padding(
padding: const EdgeInsets.only(bottom: 16),
child: TextFormField(
key: ValueKey('$label-$value'),
initialValue: value,
readOnly: true,
decoration: InputDecoration(
labelText: label,
prefixIcon: Icon(icon),
),
),
);
}

Widget _buildEditableField({
required String label,
required TextEditingController controller,
required IconData icon,
int maxLines = 1,
TextInputType keyboardType = TextInputType.text,
String? Function(String?)? validator,
}) {
final isPhoneField = label == 'Phone Number';

return Padding(
padding: const EdgeInsets.only(bottom: 16),
child: TextFormField(
controller: controller,
readOnly: !_isEditing,
maxLines: maxLines,
keyboardType: isPhoneField ? TextInputType.number : keyboardType,
inputFormatters: isPhoneField
? [
FilteringTextInputFormatter.digitsOnly,
LengthLimitingTextInputFormatter(10),
]
    : null,
validator: validator,
decoration: InputDecoration(
labelText: label,
prefixIcon: Icon(icon),
),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('My Profile'),
),
body: SafeArea(
child: _isLoading
? const Center(
child: CircularProgressIndicator(),
)
    : _errorMessage != null
? Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
size: 48,
color: AppColors.primary,
),
const SizedBox(height: 12),
Text(
_errorMessage!,
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
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Center(
child: Container(
width: 92,
height: 92,
decoration: BoxDecoration(
color: AppColors.primary.withValues(
alpha: 0.12,
),
shape: BoxShape.circle,
),
child: const Icon(
Icons.person_rounded,
size: 52,
color: AppColors.primary,
),
),
),
const SizedBox(height: 16),
Text(
_nameController.text.isEmpty
? 'Customer'
    : _nameController.text,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 23,
fontWeight: FontWeight.bold,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 6),
const Text(
'Manage your personal information',
textAlign: TextAlign.center,
style: TextStyle(
color: AppColors.textSecondary,
),
),
const SizedBox(height: 28),
_buildReadOnlyField(
label: 'Full Name',
value: _nameController.text,
icon: Icons.person_outline,
),
_buildReadOnlyField(
label: 'Email Address',
value: _emailController.text,
icon: Icons.email_outlined,
),
_buildEditableField(
label: 'Phone Number',
controller: _phoneController,
icon: Icons.phone_outlined,
keyboardType: TextInputType.number,
validator: (value) {
final phone = value?.trim() ?? '';

if (phone.isEmpty) {
return 'Please enter your phone number.';
}

if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
return 'Phone number must be exactly 10 digits.';
}

return null;
},
),
_buildEditableField(
label: 'Address',
controller: _addressController,
icon: Icons.location_on_outlined,
maxLines: 3,
validator: (value) {
if ((value ?? '').trim().length > 300) {
return 'Address is too long.';
}

return null;
},
),
const SizedBox(height: 12),
if (!_isEditing) ...[
FilledButton.icon(
onPressed: () {
setState(() => _isEditing = true);
},
icon: const Icon(Icons.edit_outlined),
label: const Text('Edit Profile'),
),
const SizedBox(height: 12),
OutlinedButton.icon(
onPressed: _openChangePassword,
icon: const Icon(Icons.lock_reset_rounded),
label: const Text('Change Password'),
),
const SizedBox(height: 12),
OutlinedButton.icon(
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
),
),
] else ...[
FilledButton.icon(
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
    : const Icon(Icons.save_outlined),
label: Text(
_isSaving ? 'Saving...' : 'Save Changes',
),
),
const SizedBox(height: 10),
OutlinedButton(
onPressed: _isSaving ? null : _cancelEditing,
child: const Text('Cancel'),
),
],
],
),
),
),
),
);
}
}
