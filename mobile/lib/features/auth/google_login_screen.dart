import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';
import '../home/main_two_screen_shell.dart';
import '../onboarding/citizen_profile_setup_screen.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _isLoading = false;
  bool _isRestoringSession = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSession();
    });
  }

  Future<void> _restoreSession() async {
    final auth = AuthService.instance;
    final restored = auth.refreshToken != null
        ? await auth.restoreSession()
        : false;
    if (!mounted) return;
    setState(() {
      _isRestoringSession = false;
      if (!restored && auth.refreshToken != null) {
        _errorMessage = auth.lastAuthError;
      }
    });
    if (restored) _continueToApp(auth);
  }

  void _continueToApp(AuthService auth) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => auth.isProfileComplete
            ? const MainTwoScreenShell()
            : const CitizenProfileSetupScreen(),
      ),
    );
  }

  String _googleErrorText(String? error) {
    final detail = error?.toLowerCase() ?? '';
    if (detail.contains('network') || detail.contains('socket')) {
      return 'Could not reach Google or URJA. Check your internet connection and try again.';
    }
    if (detail.contains('10') ||
        detail.contains('developer_error') ||
        detail.contains('sign_in_failed')) {
      return 'Google sign-in configuration was rejected. Check this Android app’s package name and SHA-1 in Google Cloud Console.';
    }
    if (detail.contains('id token') ||
        detail.contains('idtoken') ||
        detail.contains('audience')) {
      return 'Google did not provide a valid sign-in token. Set the Web OAuth client ID for both app and backend.';
    }
    return 'Google sign-in failed. Please try again or use guest demo mode.';
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isRestoringSession) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    // Triggers real Google Sign-In with Google account picker sheet
    final auth = AuthService.instance;
    var success = false;
    try {
      success = await auth.signInWithGoogle();
    } catch (error) {
      _errorMessage = error.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        setState(() {
          _errorMessage = auth.lastAuthError == null
              ? null
              : _googleErrorText(auth.lastAuthError);
        });
        return;
      }
      _continueToApp(auth);
    }
  }

  void _skipAsGuest() {
    if (_isLoading || _isRestoringSession) return;
    HapticFeedback.lightImpact();
    AuthService.instance.signInAsGuest();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainTwoScreenShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.27).clamp(
      170.0,
      280.0,
    );
    return Scaffold(
      backgroundColor: const Color(
        0xFFDFF0FE,
      ), // Atmospheric Sky to Forest Gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDFF0FE), Color(0xFFE8F5E9), Color(0xFFF1F8F5)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),

                // Top 3D Claymorphic Brand Header: URJA ONE
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0x331B6B44),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x141B6B44),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B6B44),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'URJA ONE',
                          style: TextStyle(
                            color: Color(0xFF1B6B44),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GUJARAT',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 4),
                const Text(
                  'Small steps. A greener tomorrow.',
                  style: TextStyle(
                    color: UrjaColors.textSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                // 3D Smiling Sparrow Hero Image (with soft claymorphic floating effect)
                SizedBox(
                  height: heroHeight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/images/sparrow_login_hero.png',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // Bottom 3D Claymorphic Login Sheet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border.all(
                      color: const Color(0xFFE2EBE5),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F1B6B44),
                        blurRadius: 24,
                        offset: Offset(0, -6),
                      ),
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Start your green journey',
                        style: TextStyle(
                          color: UrjaColors.textMain,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Create an account or sign in with Google',
                            style: TextStyle(
                              color: UrjaColors.textSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text('🌱', style: TextStyle(fontSize: 13)),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Feature highlights pill chips
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildFeaturePill('🕊️ 3D Sanctuary'),
                          _buildFeaturePill('⏱️ Real Logger'),
                          _buildFeaturePill('🏆 Duolingo Leagues'),
                        ],
                      ),

                      const SizedBox(height: 18),
                      if (_isRestoringSession)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Checking your saved session…',
                                  style: TextStyle(
                                    color: UrjaColors.textSub,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF9C3427),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFF9C3427),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 1-Click 3D Google Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: GestureDetector(
                          onTap: _isLoading || _isRestoringSession
                              ? null
                              : _handleGoogleSignIn,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF94A3B8),
                                  offset: Offset(0, 4),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFF1B6B44),
                                      ),
                                    )
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.08),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'G',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF4285F4),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: UrjaColors.textMain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 3D Skip / Dev Guest Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: GestureDetector(
                          onTap: _isLoading || _isRestoringSession
                              ? null
                              : _skipAsGuest,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B6B44),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFF4ADE80),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF0F3D24),
                                  offset: Offset(0, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 18,
                                  color: Color(0xFFFBBF24),
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Explore as Guest · Demo only',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Guest progress is stored only on this device and will not sync.\nBy continuing with Google, you agree to our Terms and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2EBE5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1B6B44),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
