import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/auth_session.dart';
import '../home/app_shell.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    AuthSession.instance.initialize();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AuthSession.instance,
    builder: (context, _) {
      if (!AuthSession.instance.isReady) {
        return const _LaunchScreen();
      }
      if (AuthSession.instance.startupError != null) {
        return _LaunchScreen(
          error: AuthSession.instance.startupError,
          onRetry: AuthSession.instance.retryInitialization,
        );
      }
      if (!AuthSession.instance.isSignedIn) return const LoginScreen();
      if (!AuthSession.instance.profileComplete) {
        return const ProfileSetupScreen();
      }
      return const AppShell();
    },
  );
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen({this.error, this.onRetry});

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: UrjaColors.canvas,
    body: error == null
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BrandMark(size: 66),
                SizedBox(height: 16),
                Text(
                  'URJA',
                  style: TextStyle(
                    color: UrjaColors.forest,
                    fontSize: 19,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 22),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ),
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 40,
                    color: UrjaColors.forest,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not restore your session.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: UrjaColors.mint,
      borderRadius: BorderRadius.circular(size * .32),
    ),
    padding: const EdgeInsets.all(8),
    child: Image.asset('assets/images/app_icon.png', fit: BoxFit.contain),
  );
}
