import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/colors.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: UrjaColors.emeraldBg,
        primaryColor: UrjaColors.primaryGreen,
        colorScheme: const ColorScheme.dark(
          primary: UrjaColors.primaryGreen,
          secondary: UrjaColors.amberGold,
          surface: UrjaColors.cardSurface,
        ),
        fontFamily: 'Roboto',
      ),
      home: const OnboardingScreen(),
    );
  }
}
