import 'package:flutter/material.dart';
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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

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
                    final shift = disableAnimations
                        ? 0.0
                        : (_ambientController.value - 0.5) * 5;
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFDCEADE),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x220C2819),
                                  blurRadius: 16,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco_rounded,
                                  color: Color(0xFF176B43),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'URJA',
                                  style: TextStyle(
                                    color: Color(0xFF174B35),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'GUJARAT',
                                  style: TextStyle(
                                    color: Color(0xFF718174),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.22,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
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
                          (index) => _buildAdventurePage(
                            index,
                            disableAnimations,
                            isCompact,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        isCompact ? 6 : 10,
                        20,
                        isCompact ? 8 : 16,
                      ),
                      child: _currentPage == 2
                          ? SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _navigateToLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF176B43),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color(0xAA0F3E2E),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Start your green journey',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
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
                                  OutlinedButton.icon(
                                    onPressed: _onBack,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                      backgroundColor: Colors.black.withValues(
                                        alpha: 0.16,
                                      ),
                                      minimumSize: const Size(104, 48),
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Back'),
                                  )
                                else
                                  const SizedBox(width: 104),
                                Row(
                                  children: List.generate(3, (idx) {
                                    final active = idx == _currentPage;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: active ? 22 : 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.55,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    );
                                  }),
                                ),
                                FilledButton(
                                  onPressed: _onNext,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF176B43),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(104, 48),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Next'),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
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

  Widget _buildAdventurePage(
    int index,
    bool disableAnimations,
    bool isCompact,
  ) {
    const messages = [
      (
        'MAKE EVERYDAY CHOICES COUNT',
        'Turn small changes at home into a healthier, greener Gujarat.',
      ),
      (
        'UNDERSTAND YOUR HOME',
        'Track the energy, water, and travel behind your daily routine.',
      ),
      (
        'PLAY. PROGRESS. PROTECT.',
        'Complete real-life missions, earn rewards, and grow your sparrow.',
      ),
    ];
    final (eyebrow, message) = messages[index];
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, isCompact ? 4 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              if (index == 1)
                _applianceStatus(disableAnimations, isCompact)
              else if (index == 2)
                _impactRewards(disableAnimations)
              else
                Align(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2EBDD)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33071C0E),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WelcomeBenefit(
                          icon: Icons.bolt_rounded,
                          label: 'Save',
                        ),
                        SizedBox(width: 16),
                        _WelcomeBenefit(
                          icon: Icons.cloud_outlined,
                          label: 'Measure',
                        ),
                        SizedBox(width: 16),
                        _WelcomeBenefit(
                          icon: Icons.emoji_events_outlined,
                          label: 'Grow',
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(flex: 2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FCF6).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44071C0E),
                      blurRadius: 26,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F2E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '0${index + 1}  /  03   •   ${index == 2 ? 'YOUR IMPACT' : 'THE URJA WAY'}',
                        style: const TextStyle(
                          color: Color(0xFF176B43),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      eyebrow,
                      style: TextStyle(
                        color: const Color(0xFF174B35),
                        fontSize: isCompact ? 21 : 24,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFF617168),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameGlass({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xEAF8F4DF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.86),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66071C0E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
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
    return _gameGlass(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isCompact ? 4 : 7,
      ),
      child: Column(
        children: appliances
            .map(
              (item) => Padding(
                padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 5),
                child: Row(
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 23)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: const TextStyle(
                          color: Color(0xFF244233),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) => Transform.scale(
                        scale: disableAnimations
                            ? 1
                            : 0.88 + _pulseController.value * 0.18,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: item.$3,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.$3.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _impactRewards(bool disableAnimations) {
    return Column(
      children: [
        _gameGlass(
          child: Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 25)),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: disableAnimations ? 0.7 : _progressAnimation.value,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFCCD1B2),
                      color: const Color(0xFF08A83C),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '70%',
                style: TextStyle(
                  color: Color(0xFF20633B),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final reward in [
              ('🪙', 'COINS'),
              ('☁️', 'CARBON'),
              ('⭐', 'STREAK'),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _gameGlass(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Column(
                      children: [
                        Text(reward.$1, style: const TextStyle(fontSize: 23)),
                        Text(
                          reward.$2,
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.8,
                            color: Color(0xFF46604B),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // SCREEN 1: Welcome to URJA ONE
  // ===========================================================================

  // ===========================================================================
  // SCREEN 2: Understand your energy use
  // ===========================================================================

  // ===========================================================================
  // SCREEN 3: Take action and make an impact
  // ===========================================================================
}

// =============================================================================
// SUB-WIDGETS & MODULAR COMPONENTS
// =============================================================================

class _WelcomeBenefit extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WelcomeBenefit({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF176B43), size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF44544A),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
