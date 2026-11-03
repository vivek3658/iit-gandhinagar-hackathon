import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/urja_theme.dart';
import 'features/auth/google_login_screen.dart';
import 'features/home/main_two_screen_shell.dart';
import 'features/onboarding/citizen_profile_setup_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

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
      home: home ?? const _InitialRouteScreen(),
    );
  }
}

class _InitialRouteScreen extends StatefulWidget {
  const _InitialRouteScreen();

  @override
  State<_InitialRouteScreen> createState() => _InitialRouteScreenState();
}

class _InitialRouteScreenState extends State<_InitialRouteScreen> {
  @override
  void initState() {
    super.initState();
    _restoreAndRoute();
  }

  Future<void> _restoreAndRoute() async {
    final auth = AuthService.instance;
    final hadSavedSession = auth.isLoggedIn && !auth.isGuestMode;

    if (auth.isLoggedIn && !auth.isGuestMode && auth.refreshToken != null) {
      await auth.restoreSession();
    }

    if (!mounted) return;

    final Widget destination;
    if (auth.isGuestMode) {
      destination = const MainTwoScreenShell();
    } else if (auth.isLoggedIn) {
      destination = auth.isProfileComplete
          ? const MainTwoScreenShell()
          : const CitizenProfileSetupScreen();
    } else if (hadSavedSession) {
      destination = const GoogleLoginScreen();
    } else {
      destination = const OnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => destination,
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: UrjaTheme.mint,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Icon(
                  Icons.eco_rounded,
                  color: UrjaTheme.forest,
                  size: 38,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'URJA',
              style: TextStyle(
                color: UrjaTheme.forest,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
