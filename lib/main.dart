
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/notifications/data/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.initialize();

  await LocalNotificationService.instance.initialize();

  runApp(const ServiceHubApp());

  // TEMPORARY TEST: Remove this after testing.

}
