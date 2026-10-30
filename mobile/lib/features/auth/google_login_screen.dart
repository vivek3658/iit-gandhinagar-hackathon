import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../home/main_navigation_shell.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    // Simulate backend /api/v1/auth/google verification call
    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UrjaColors.emeraldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(),

              // Brand Icon Visual
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF34D399), Color(0xFF065F46)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: UrjaColors.primaryGreen.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🕊️', style: TextStyle(fontSize: 54)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // App Name & Tagline
              const Text(
                'URJA ONE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gujarat Mission LiFE Citizen Portal',
                style: TextStyle(
                  color: UrjaColors.primaryGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Join thousands of Gujarat households reducing peak grid load, earning clean energy mudras, and nurturing wildlife.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: UrjaColors.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // 50 Bonus Coins Callout Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: UrjaColors.amberGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: UrjaColors.amberGold.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: UrjaColors.amberGold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🪙', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '50 Bonus Urja Mudra',
                            style: TextStyle(
                              color: UrjaColors.sunnyYellow,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Granted automatically to new citizens upon 1-click Google verification!',
                            style: TextStyle(
                              color: UrjaColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Single 1-Click Google Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: UrjaColors.primaryGreen,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google Logo icon representation
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('G',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: Color(0xFF4285F4),
                                    )),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Disclaimer
              const Text(
                'By signing in, you agree to Mission LiFE Community Guidelines.\nNo passwords required. Instant secure OAuth 2.0 login.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
