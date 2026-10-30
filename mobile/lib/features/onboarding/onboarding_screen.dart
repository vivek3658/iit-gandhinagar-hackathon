import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../auth/google_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GoogleLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF0FE), // Nature sky blue from mockup
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Spacer
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: UrjaColors.textSub,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page Carousel
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: _currentPage == 2
                  ? SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _navigateToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3E2E), // Exact dark green
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          GestureDetector(
                            onTap: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            ),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F3E2E)),
                            ),
                          )
                        else
                          const SizedBox(width: 52),

                        // Dot Indicators
                        Row(
                          children: List.generate(3, (idx) {
                            final isActive = idx == _currentPage;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 10 : 8,
                              height: isActive ? 10 : 8,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF0F3E2E) : Colors.black26,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),

                        // Circular Next Button
                        GestureDetector(
                          onTap: _onNext,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F3E2E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Page 1: Welcome to URJA ONE ---
  Widget _buildPage1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const Text(
            'Welcome to',
            style: TextStyle(
              color: UrjaColors.textMain,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'URJA ONE',
                style: TextStyle(
                  color: Color(0xFF1B6B44),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 4),
              Text('🌿', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Small actions, a greener tomorrow.',
            style: TextStyle(
              color: UrjaColors.textSub,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // 3D Flying Sparrow Hero Image from exact mockup!
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: AssetImage('assets/images/hero_onboarding_1.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bottom Feature Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _FeaturePill(icon: '🍃', label: 'Save\nEnergy'),
                _FeaturePill(icon: '☁️', label: 'Reduce\nCarbon'),
                _FeaturePill(icon: '🌱', label: 'Build\nGreener Habits'),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- Page 2: Understand your energy use ---
  Widget _buildPage2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Understand\n',
                  style: TextStyle(
                    color: UrjaColors.textMain,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: 'your energy use',
                  style: TextStyle(
                    color: Color(0xFF1B6B44),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Detect devices around you and get insights automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: UrjaColors.textSub,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // 3D Sparrow on Smart Plug + Floating Appliance Pills Hero Image
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: AssetImage('assets/images/hero_onboarding_2.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- Page 3: Take action and make an impact ---
  Widget _buildPage3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Take action\n',
                  style: TextStyle(
                    color: UrjaColors.textMain,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: 'and make an impact',
                  style: TextStyle(
                    color: Color(0xFF1B6B44),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Follow simple suggestions, earn rewards, and grow your green companion.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: UrjaColors.textSub,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // 3D Cheering Sparrow with Glowing Green Sprout Hero Image
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: AssetImage('assets/images/hero_onboarding_3.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3 Frosted Action Cards
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionMiniCard(icon: '₹', label: 'Lower\nElectricity Bill', isRupee: true),
              _ActionMiniCard(icon: '☁️', label: 'Reduce\nCarbon Emission'),
              _ActionMiniCard(icon: '⭐', label: 'Earn\nRewards'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: UrjaColors.textMain,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ActionMiniCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool isRupee;

  const _ActionMiniCard({required this.icon, required this.label, this.isRupee = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isRupee ? const Color(0xFFFBBF24) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isRupee ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: UrjaColors.textMain,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
