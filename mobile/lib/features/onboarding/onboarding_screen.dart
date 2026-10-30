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

  final List<OnboardingItem> _pages = const [
    OnboardingItem(
      title: 'Conserve Energy,\nProtect Earth',
      subtitle: 'Track and optimize your household electricity consumption in real-time under Gujarat Mission LiFE.',
      icon: Icons.electric_bolt_rounded,
      badgeText: 'Mission LiFE · Urja',
      gradient: [Color(0xFF065F46), Color(0xFF10B981)],
      accentEmoji: '⚡',
    ),
    OnboardingItem(
      title: 'Rooftop Solar &\nCarbon Savings',
      subtitle: 'Discover your PM Surya Ghar feasibility, monitor rooftop power generation, and slash state emissions.',
      icon: Icons.solar_power_rounded,
      badgeText: 'PM Surya Ghar Muft Bijli',
      gradient: [Color(0xFF92400E), Color(0xFFF59E0B)],
      accentEmoji: '☀️',
    ),
    OnboardingItem(
      title: 'Build Your\nLiving Sanctuary',
      subtitle: 'Earn Urja Mudra coins through daily micro-habits, level up your 3D sparrow companion, and expand your garden.',
      icon: Icons.eco_rounded,
      badgeText: 'Gamified Eco-Habitat',
      gradient: [Color(0xFF047857), Color(0xFF34D399)],
      accentEmoji: '🌿',
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
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
      backgroundColor: UrjaColors.emeraldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Brand + Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [UrjaColors.primaryGreen, UrjaColors.darkGreen],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🕊️', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'URJA ONE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: UrjaColors.textMuted,
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
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hero Art Visual
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    item.gradient[1].withValues(alpha: 0.35),
                                    item.gradient[0].withValues(alpha: 0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: item.gradient[1].withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: item.gradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: item.gradient[1].withValues(alpha: 0.4),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 52,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Positioned(
                                    top: 24,
                                    right: 28,
                                    child: Text(
                                      item.accentEmoji,
                                      style: const TextStyle(fontSize: 26),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: item.gradient[1].withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: item.gradient[1].withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                item.badgeText,
                                style: TextStyle(
                                  color: item.gradient[1],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              item.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: UrjaColors.textMuted,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(_pages.length, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 8),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? UrjaColors.primaryGreen : UrjaColors.borderGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UrjaColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: UrjaColors.primaryGreen.withValues(alpha: 0.4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
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
}

class OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;
  final List<Color> gradient;
  final String accentEmoji;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
    required this.gradient,
    required this.accentEmoji,
  });
}
