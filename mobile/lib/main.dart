import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const UrjaApp());
}

class UrjaApp extends StatelessWidget {
  const UrjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URJA ONE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F8F5),
        primaryColor: const Color(0xFF1B6B44),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1B6B44),
          secondary: Color(0xFFF59E0B),
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
      home: const OnboardingScreen(),
    );
  }
}
