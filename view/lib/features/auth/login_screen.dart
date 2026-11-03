import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/auth_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _error;

  Future<void> _signIn() async {
    setState(() => _error = null);
    try {
      await AuthSession.instance.signInWithGoogle();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.toLowerCase().contains('apiexception: 10')) {
      return 'Google sign-in needs setup for this build. Register the Android package and signing certificate in Google Cloud, and provide the Web OAuth client ID as GOOGLE_SERVER_CLIENT_ID.';
    }
    if (message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('socket')) {
      return 'We could not connect. Check your internet and try again.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final busy = AuthSession.instance.isBusy;
    return Scaffold(
      backgroundColor: UrjaColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 46,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: UrjaColors.mint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset('assets/images/app_icon.png'),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'URJA',
                        style: TextStyle(
                          fontSize: 15,
                          letterSpacing: 2.4,
                          color: UrjaColors.forest,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: (constraints.maxHeight * .42)
                        .clamp(275.0, 360.0)
                        .toDouble(),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 275),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2DF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 17,
                            left: 18,
                            child: _floatBadge('🌱', -0.07),
                          ),
                          Positioned(
                            right: 20,
                            top: 38,
                            child: _floatBadge('☀️', 0.06),
                          ),
                          Positioned(
                            left: 24,
                            bottom: 32,
                            child: _floatBadge('💧', 0.04),
                          ),
                          Image.asset(
                            'assets/images/sparrow_login_hero.png',
                            fit: BoxFit.contain,
                            width: 260,
                          ),
                          Positioned(
                            right: 18,
                            bottom: 22,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x18000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Text('Your green buddy'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Small habits.\nA greener Gujarat.',
                    style: TextStyle(
                      color: UrjaColors.ink,
                      fontSize: 34,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Make everyday choices count. Complete missions, grow your sparrow, and build a garden that is yours.',
                    style: TextStyle(
                      color: UrjaColors.muted,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 23),
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: busy ? null : _signIn,
                    child: busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleMark(),
                              SizedBox(width: 10),
                              Text('Continue with Google'),
                            ],
                          ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Your progress is saved to your account. You choose what data to share.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: UrjaColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _floatBadge(String label, double rotate) => Transform.rotate(
    angle: rotate,
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(fontSize: 20)),
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      color: Color(0xFF4285F4),
      fontWeight: FontWeight.w900,
      fontSize: 20,
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9E5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFF9D3429))),
  );
}
