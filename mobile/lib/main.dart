import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'constants/urja_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.instance.requestPermission();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const UrjaApp());
}

class UrjaApp extends StatelessWidget {
  final Widget? home;
  const UrjaApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URJA ONE',
      debugShowCheckedModeBanner: false,
      theme: UrjaTheme.light,
      home: home ?? const OnboardingScreen(),
    );
  }
}
