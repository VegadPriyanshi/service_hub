
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/auth_repository.dart';
import 'register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../home/home_screen.dart';
import '../../../provider_dashboard/provider_dashboard_screen.dart';
import '../../../notifications/data/notification_service.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _authRepository = AuthRepository();

bool _isLoading = false;
bool _obscurePassword = true;

@override
void dispose() {
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}


Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final credential = await _authRepository.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Unable to retrieve the signed-in user.');
    }

    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDocument.exists) {
      await _authRepository.logout();

      throw Exception(
        'User profile not found. Please register again.',
      );
    }

    final data = userDocument.data();
    final role = data?['role'];

// Save this signed-in user's FCM token.
// A token-saving failure should not prevent login.
    try {
      await NotificationService.instance.saveDeviceToken();
    } catch (e) {
      debugPrint('Unable to register FCM token after login: $e');
    }

    if (!mounted) return;

    if (role == 'customer') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
        ),
            (route) => false,
      );
    } else if (role == 'provider') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const ProviderDashboardScreen(),
        ),
            (route) => false,
      );
    } else {
      await _authRepository.logout();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid user role. Please contact support.'),
        ),
      );
    }
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String message;

    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        message = 'Invalid email or password.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      default:
        message = e.message ?? 'Unable to login. Please try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } on FirebaseException catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.code == 'permission-denied'
              ? 'Unable to access your profile. Check Firestore rules.'
              : 'Unable to load your profile. Please try again.',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}



Future<void> _forgotPassword() async {
  final email = _emailController.text.trim();

  if (email.isEmpty ||
      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
          .hasMatch(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a valid email address first.'),
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    await _authRepository.sendPasswordResetEmail(
      email: email,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'If an account exists for this email, '
              'you may receive a password reset email.',
        ),
      ),
    );
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String message;

    switch (e.code) {
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'user-not-found':
        message = 'No account found for this email.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Check your internet connection.';
        break;
      default:
        message = 'Unable to send reset email. Please try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong. Please try again.'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


void _openRegisterScreen() {
Navigator.push(
context,
MaterialPageRoute<void>(
builder: (_) => const RegisterScreen(),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Center(
child: Container(
width: 76,
height: 76,
decoration: BoxDecoration(
color: AppColors.primary.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(24),
),
child: const Icon(
Icons.home_repair_service_rounded,
size: 42,
color: AppColors.primary,
),
),
),
const SizedBox(height: 28),
const Text(
'Welcome Back!',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 8),
const Text(
'Login to book trusted home services.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 15,
color: AppColors.textSecondary,
),
),
const SizedBox(height: 32),
const Text(
'Email Address',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 8),
TextFormField(
controller: _emailController,
keyboardType: TextInputType.emailAddress,
textInputAction: TextInputAction.next,
autofillHints: const [AutofillHints.email],
decoration: const InputDecoration(
hintText: 'Enter your email',
prefixIcon: Icon(Icons.email_outlined),
),
validator: (value) {
final email = value?.trim() ?? '';

if (email.isEmpty) {
return 'Email is required.';
}

if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
    .hasMatch(email)) {
return 'Enter a valid email address.';
}

return null;
},
),
const SizedBox(height: 20),
const Text(
'Password',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 8),
TextFormField(
controller: _passwordController,
obscureText: _obscurePassword,
textInputAction: TextInputAction.done,
autofillHints: const [AutofillHints.password],
onFieldSubmitted: (_) => _login(),
decoration: InputDecoration(
hintText: 'Enter your password',
prefixIcon: const Icon(Icons.lock_outline),
suffixIcon: IconButton(
onPressed: () {
setState(() {
_obscurePassword = !_obscurePassword;
});
},
icon: Icon(
_obscurePassword
? Icons.visibility_outlined
    : Icons.visibility_off_outlined,
),
),
),
validator: (value) {
if (value == null || value.isEmpty) {
return 'Password is required.';
}

return null;
},
),
Align(
alignment: Alignment.centerRight,
child: TextButton(
onPressed: _isLoading ? null : _forgotPassword,
child: const Text('Forgot Password?'),
),
),
const SizedBox(height: 12),
ElevatedButton(
onPressed: _isLoading ? null : _login,
child: _isLoading
? const SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Text('Login'),
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Flexible(
child: Text(
"Don't have an account? ",
style: TextStyle(
color: AppColors.textSecondary,
),
),
),
TextButton(
onPressed:
_isLoading ? null : _openRegisterScreen,
child: const Text('Register'),
),
],
),
],
),
),
),
),
),
);
}
}
