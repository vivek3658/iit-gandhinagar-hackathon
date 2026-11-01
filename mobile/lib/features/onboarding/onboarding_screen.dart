import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../auth/google_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation Controllers
  late final AnimationController _ambientController;
  late final AnimationController _entranceController;
  late final AnimationController _progressController;
  late final AnimationController _pulseController;

  // Staggered Entrance Animations
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Continuous Ambient Controller (Sparrow bobbing, leaves drifting, sparkles)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // 2. Page Entrance Stagger Controller
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    // 3. Impact Progress Bar Controller (Page 3: 0 -> 70%)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.70).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutQuart),
    );

    // 4. Status Dot Pulsing Controller (Device statuses on Page 2)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ambientController.dispose();
    _entranceController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _entranceController.reset();
    _entranceController.forward();

    if (index == 2) {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _onBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GoogleLoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 700;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) {
                    final shift = disableAnimations ? 0.0 : (_ambientController.value - 0.5) * 5;
                    return Transform.translate(
                      offset: Offset(shift, 0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 480),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: Image.asset(
                          'assets/images/onboarding/adventure_${_currentPage + 1}.png',
                          key: ValueKey(_currentPage),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    );
                  },
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                      const Color(0xE6122015),
                    ],
                    stops: const [0, 0.34, 0.58, 1],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('🌿', style: TextStyle(fontSize: 13)),
                              SizedBox(width: 4),
                              Text('URJA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                            ]),
                          ),
                          AnimatedOpacity(
                            opacity: _currentPage == 2 ? 0 : 1,
                            duration: const Duration(milliseconds: 250),
                            child: IgnorePointer(
                              ignoring: _currentPage == 2,
                              child: TextButton(
                                onPressed: _navigateToLogin,
                                style: TextButton.styleFrom(foregroundColor: Colors.white),
                                child: const Text('Skip', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        physics: const BouncingScrollPhysics(),
                        children: List.generate(
                          3,
                          (index) => _buildAdventurePage(index, disableAnimations, isCompact),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, isCompact ? 6 : 10, 20, isCompact ? 8 : 16),
                      child: _currentPage == 2
                          ? SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _navigateToLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF087B3B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                  elevation: 10,
                                  shadowColor: const Color(0xAA0F3E2E),
                                ),
                                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text('Begin your adventure', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ]),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_currentPage > 0)
                                  Material(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: _onBack,
                                      customBorder: const CircleBorder(),
                                      child: const SizedBox(width: 50, height: 50, child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22)),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 50),
                                Row(children: List.generate(3, (idx) {
                                  final active = idx == _currentPage;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: active ? 26 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.48),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                    ),
                                  );
                                })),
                                Material(
                                  color: const Color(0xFF087B3B),
                                  shape: const CircleBorder(),
                                  elevation: 8,
                                  child: InkWell(
                                    onTap: _onNext,
                                    customBorder: const CircleBorder(),
                                    child: const SizedBox(width: 50, height: 50, child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22)),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdventurePage(int index, bool disableAnimations, bool isCompact) {
    const messages = [
      ('A GREENER WORLD STARTS AT HOME', 'Small choices at home can make a big difference.'),
      ('MEET YOUR ENERGY', 'Discover what your everyday devices are using.'),
      ('GROW YOUR IMPACT', 'Make greener choices, earn rewards, and grow your companion.'),
    ];
    final (eyebrow, message) = messages[index];
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.fromLTRB(26, 16, 26, isCompact ? 4 : 16),
          child: Column(
            children: [
              const Spacer(flex: 7),
              if (index == 0) ...[
                const Text(
                  'URJA ONE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 18)],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (index == 1) _applianceStatus(disableAnimations, isCompact),
              if (index == 2) _impactRewards(disableAnimations),
              SizedBox(height: isCompact ? 8 : 16),
              Text(
                eyebrow,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: 12,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 12)],
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 14)],
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameGlass({required Widget child, EdgeInsets padding = const EdgeInsets.all(12)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xEAF8F4DF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86), width: 1.4),
        boxShadow: const [
          BoxShadow(color: Color(0x66071C0E), blurRadius: 20, offset: Offset(0, 8)),
          BoxShadow(color: Colors.white70, blurRadius: 0, offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }

  Widget _applianceStatus(bool disableAnimations, bool isCompact) {
    const appliances = [
      ('❄️', 'Air conditioning', Color(0xFF22C55E)),
      ('🧊', 'Refrigerator', Color(0xFF22C55E)),
      ('📺', 'Television', Color(0xFFFBBF24)),
      ('🍲', 'Kitchen', Color(0xFFFB6A57)),
    ];
    return _gameGlass(padding: EdgeInsets.symmetric(horizontal: 12, vertical: isCompact ? 4 : 7), child: Column(
      children: appliances.map((item) => Padding(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 5),
        child: Row(children: [
          Text(item.$1, style: const TextStyle(fontSize: 23)),
          const SizedBox(width: 10),
          Expanded(child: Text(item.$2, style: const TextStyle(color: Color(0xFF244233), fontSize: 13, fontWeight: FontWeight.w700))),
          AnimatedBuilder(animation: _pulseController, builder: (context, _) => Transform.scale(
            scale: disableAnimations ? 1 : 0.88 + _pulseController.value * 0.18,
            child: Container(width: 11, height: 11, decoration: BoxDecoration(color: item.$3, shape: BoxShape.circle, boxShadow: [BoxShadow(color: item.$3.withValues(alpha: 0.6), blurRadius: 8)])),
          )),
        ]),
      )).toList(),
    ));
  }

  Widget _impactRewards(bool disableAnimations) {
    return Column(children: [
      _gameGlass(child: Row(children: [
        const Text('🌱', style: TextStyle(fontSize: 25)),
        const SizedBox(width: 8),
        Expanded(child: AnimatedBuilder(animation: _progressAnimation, builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: disableAnimations ? 0.7 : _progressAnimation.value, minHeight: 12, backgroundColor: const Color(0xFFCCD1B2), color: const Color(0xFF08A83C)),
        ))),
        const SizedBox(width: 8),
        const Text('70%', style: TextStyle(color: Color(0xFF20633B), fontWeight: FontWeight.w900)),
      ])),
      const SizedBox(height: 10),
      Row(children: [
        for (final reward in [('🪙', 'COINS'), ('☁️', 'CARBON'), ('⭐', 'STREAK')])
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _gameGlass(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Column(children: [
              Text(reward.$1, style: const TextStyle(fontSize: 23)),
              Text(reward.$2, style: const TextStyle(fontSize: 9, letterSpacing: 0.8, color: Color(0xFF46604B), fontWeight: FontWeight.w900)),
            ]),
          ))),
      ]),
    ]);
  }

  // ===========================================================================
  // SCREEN 1: Welcome to URJA ONE
  // ===========================================================================
  Widget _buildScreen1(bool disableAnimations) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 6),
              // Heading
              const Text(
                'Welcome to',
                style: TextStyle(
                  color: UrjaColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
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
                  SizedBox(width: 6),
                  Text('🌿', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Small actions, a greener tomorrow.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: UrjaColors.textSub,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              // Animated 3D Floating Sparrow & Solar House Card
              AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  final t = _ambientController.value;
                  final floatY = disableAnimations ? 0.0 : math.sin(t * math.pi) * 6.0;
                  final rotateZ = disableAnimations ? 0.0 : math.sin(t * math.pi) * 0.015;
                  final breatheScale = disableAnimations ? 1.0 : 1.0 + (math.sin(t * math.pi) * 0.015);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Main Scenic Hero Container
                      Container(
                        height: 285,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A0F291E),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Transform.translate(
                          offset: Offset(0, floatY),
                          child: Transform.rotate(
                            angle: rotateZ,
                            child: Transform.scale(
                              scale: breatheScale,
                              child: Image.asset(
                                'assets/images/onboarding/hero_1.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/hero_onboarding_1.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Floating Independent Leaves
                      if (!disableAnimations) ...[
                        Positioned(
                          top: 18 + math.sin(t * math.pi * 1.2) * 8,
                          left: 20 + math.cos(t * math.pi * 0.8) * 6,
                          child: Transform.rotate(
                            angle: -0.2 + (t * 0.3),
                            child: const Text('🍃', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        Positioned(
                          top: 80 + math.sin(t * math.pi * 0.9) * 10,
                          right: 24 - math.cos(t * math.pi * 1.1) * 8,
                          child: Transform.rotate(
                            angle: 0.3 - (t * 0.25),
                            child: const Text('🌱', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        Positioned(
                          bottom: 35 + math.cos(t * math.pi) * 7,
                          left: 32 + math.sin(t * math.pi) * 6,
                          child: Transform.rotate(
                            angle: t * 0.2,
                            child: const Text('🌿', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Translucent Cream Feature Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x33A5D6A7)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120F291E),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _FeatureTile(
                      emoji: '⚡',
                      title: 'Save Energy',
                      subtitle: 'Cut power waste',
                      accentColor: Color(0xFFF59E0B),
                    ),
                    _VerticalDivider(),
                    _FeatureTile(
                      emoji: '☁️',
                      title: 'Reduce Carbon',
                      subtitle: 'Track kg CO₂e',
                      accentColor: Color(0xFF10B981),
                    ),
                    _VerticalDivider(),
                    _FeatureTile(
                      emoji: '🌱',
                      title: 'Build Habits',
                      subtitle: 'Daily green steps',
                      accentColor: Color(0xFF22C55E),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 2: Understand your energy use
  // ===========================================================================
  Widget _buildScreen2(bool disableAnimations) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 6),
              // Heading
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Understand ',
                      style: TextStyle(
                        color: UrjaColors.textMain,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'your energy use',
                      style: TextStyle(
                        color: Color(0xFF1B6B44),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Detect devices around you and get insights automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: UrjaColors.textSub,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Animated 3D Sparrow Perched Hero + Device Cards Overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  // Center Hero Illustration
                  AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, child) {
                      final t = _ambientController.value;
                      final floatY = disableAnimations ? 0.0 : math.sin(t * math.pi) * 4.0;
                      return Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A0F291E),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Transform.translate(
                          offset: Offset(0, floatY),
                          child: Image.asset(
                            'assets/images/onboarding/hero_2.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/hero_onboarding_2.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Four Device Status Cards (2x2 Grid)
              Row(
                children: [
                  Expanded(
                    child: _DeviceStatusCard(
                      icon: '❄️',
                      name: 'Air Conditioner',
                      status: 'Running',
                      statusColor: const Color(0xFF10B981),
                      wattage: '1.4 kW',
                      pulseAnimation: _pulseController,
                      disableAnimations: disableAnimations,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DeviceStatusCard(
                      icon: '🧊',
                      name: 'Refrigerator',
                      status: 'Running',
                      statusColor: const Color(0xFF10B981),
                      wattage: '0.18 kW',
                      pulseAnimation: _pulseController,
                      disableAnimations: disableAnimations,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DeviceStatusCard(
                      icon: '📺',
                      name: 'Smart TV',
                      status: 'Standby',
                      statusColor: const Color(0xFFF59E0B),
                      wattage: '0.02 kW',
                      pulseAnimation: _pulseController,
                      disableAnimations: disableAnimations,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DeviceStatusCard(
                      icon: '📻',
                      name: 'Microwave',
                      status: 'Off',
                      statusColor: const Color(0xFF94A3B8),
                      wattage: '0.00 kW',
                      pulseAnimation: _pulseController,
                      disableAnimations: disableAnimations,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Glass-Style Energy Recommendation Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x33A5D6A7)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x100F291E),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('💡', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Smart Energy Recommendation',
                                style: TextStyle(
                                  color: Color(0xFF1B6B44),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Spacer(),
                              Text(
                                'Save ₹24/day',
                                style: TextStyle(
                                  color: Color(0xFFEA580C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Your AC has been running for 5 hours. Consider setting it to 26°C for lower bills and lower emissions.',
                            style: TextStyle(
                              color: UrjaColors.textMain,
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 3: Take action and make an impact
  // ===========================================================================
  Widget _buildScreen3(bool disableAnimations) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 6),
              // Heading
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Take action ',
                      style: TextStyle(
                        color: UrjaColors.textMain,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'and make an impact',
                      style: TextStyle(
                        color: Color(0xFF1B6B44),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Follow simple suggestions, earn rewards, and grow your green companion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: UrjaColors.textSub,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              // Animated Cheering Sparrow Hero on Mossy Rock with Sprout
              AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  final t = _ambientController.value;
                  final floatY = disableAnimations ? 0.0 : math.sin(t * math.pi) * 5.0;
                  final pulseSprout = disableAnimations ? 1.0 : 1.0 + (math.sin(t * math.pi * 2) * 0.08);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 235,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A0F291E),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Transform.translate(
                          offset: Offset(0, floatY),
                          child: Image.asset(
                            'assets/images/onboarding/hero_3.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/hero_onboarding_3.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // Glowing Pulsing Sprout Sparkles
                      if (!disableAnimations)
                        Positioned(
                          top: 14,
                          child: Transform.scale(
                            scale: pulseSprout,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33F59E0B),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('✨', style: TextStyle(fontSize: 13)),
                                  SizedBox(width: 4),
                                  Text(
                                    '+100 EXP',
                                    style: TextStyle(
                                      color: Color(0xFF1B6B44),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text('🌱', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // Animated Impact Card (Progress Bar from 0% -> 70%)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x33A5D6A7)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x100F291E),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        const Text(
                          'Daily Carbon Impact Goal',
                          style: TextStyle(
                            color: UrjaColors.textMain,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, _) {
                            final pct = (_progressAnimation.value * 100).round();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pct%',
                                style: const TextStyle(
                                  color: Color(0xFF1B6B44),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Custom Smooth Animated Progress Bar
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        return Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2EBE5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: disableAnimations ? 0.70 : _progressAnimation.value,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF34D399), Color(0xFF10B981)],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '350g of 500g CO₂ saved today · 1.2 kWh grid peak reduced',
                      style: TextStyle(
                        color: UrjaColors.textSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Three Reward Cards (Lower Bill, Reduce Carbon, Earn Rewards)
              const Row(
                children: [
                  Expanded(
                    child: _RewardCard(
                      icon: '₹',
                      title: 'Lower Electricity\nBill',
                      highlight: 'Save ₹320/mo',
                      badgeColor: Color(0xFFFBBF24),
                      iconColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _RewardCard(
                      icon: '🌳',
                      title: 'Reduce Carbon\nEmission',
                      highlight: '-12.5 kg CO₂',
                      badgeColor: Color(0xFFE8F5E9),
                      iconColor: Color(0xFF1B6B44),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _RewardCard(
                      icon: '⭐',
                      title: 'Earn Urja\nRewards',
                      highlight: '+150 Mudra',
                      badgeColor: Color(0xFFFEF3C7),
                      iconColor: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGETS & MODULAR COMPONENTS
// =============================================================================

class _FeatureTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _FeatureTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: UrjaColors.textMain,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: UrjaColors.textSub,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: const Color(0x221B6B44),
    );
  }
}

class _DeviceStatusCard extends StatelessWidget {
  final String icon;
  final String name;
  final String status;
  final Color statusColor;
  final String wattage;
  final Animation<double> pulseAnimation;
  final bool disableAnimations;

  const _DeviceStatusCard({
    required this.icon,
    required this.name,
    required this.status,
    required this.statusColor,
    required this.wattage,
    required this.pulseAnimation,
    required this.disableAnimations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x221B6B44)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F291E),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: UrjaColors.textMain,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // Pulsing Status Dot
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (context, _) {
                        final scale = disableAnimations ? 1.0 : 0.85 + (pulseAnimation.value * 0.3);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      wattage,
                      style: const TextStyle(
                        color: UrjaColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String icon;
  final String title;
  final String highlight;
  final Color badgeColor;
  final Color iconColor;

  const _RewardCard({
    required this.icon,
    required this.title,
    required this.highlight,
    required this.badgeColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x221B6B44)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F291E),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 18,
                  color: iconColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              color: UrjaColors.textMain,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              highlight,
              style: const TextStyle(
                color: Color(0xFF1B6B44),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
