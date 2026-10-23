
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';

class ServiceHubApp extends StatelessWidget {
  const ServiceHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServiceHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiceHub'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE7FF),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.home_repair_service_rounded,
                  size: 46,
                  color: Color(0xFF6254E8),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Home, Our Care',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF20243A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Book trusted professionals for all your home service needs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF777D91),
                ),
              ),
              const SizedBox(height: 28),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text(
                'Getting everything ready...',
                style: TextStyle(
                  color: Color(0xFF777D91),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
