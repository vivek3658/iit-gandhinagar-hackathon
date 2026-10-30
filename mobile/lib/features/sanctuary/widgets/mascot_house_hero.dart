import 'package:flutter/material.dart';

class MascotHouseHero extends StatefulWidget {
  final VoidCallback onSparrowTap;
  final VoidCallback onScrollDownTap;
  final String speechText;

  const MascotHouseHero({
    super.key,
    required this.onSparrowTap,
    required this.onScrollDownTap,
    this.speechText = 'Chirp! Welcome to your sanctuary! Scroll down to explore our floating garden! 🌱',
  });

  @override
  State<MascotHouseHero> createState() => _MascotHouseHeroState();
}

class _MascotHouseHeroState extends State<MascotHouseHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _breatheAnim;
  late final Animation<double> _hoverAnim;
  late final Animation<double> _arrowBounceAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _breatheAnim = Tween<double>(begin: 0.985, end: 1.025).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _hoverAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _arrowBounceAnim = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const RadialGradient(
          center: Alignment(0.0, -0.1),
          radius: 0.95,
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
        ),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F1B5E20),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. BEHIND THE MASCOT: The Eco Solar House
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Opacity(
                opacity: 0.95,
                child: Image.asset(
                  'assets/images/onboarding/onboarding_bg_1.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => _buildFallbackHouse(),
                ),
              ),
            ),

            // Soft atmospheric sunbeam & vignette over the house
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.transparent,
                      const Color(0xFF1B5E20).withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),

            // 2. AT CENTER: The Large Fluffy Sparrow Mascot
            GestureDetector(
              onTap: widget.onSparrowTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _hoverAnim.value),
                    child: Transform.scale(
                      scale: _breatheAnim.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft companion ground glow
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),

                          // Centered Sparrow Image
                          Image.asset(
                            'assets/images/onboarding/hero_1.png',
                            width: 220,
                            height: 220,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/sparrow_branch_hero.png',
                              width: 220,
                              height: 220,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Floating Speech Bubble (Top)
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Text(
                  widget.speechText,
                  style: const TextStyle(
                    color: Color(0xFF0F291E),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ),

            // 4. Tap prompt pill (Bottom Left)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⚡ ', style: TextStyle(fontSize: 12)),
                    Text(
                      'Tap Chirpy (+5 Vitality)',
                      style: TextStyle(
                        color: Color(0xFF1B6B44),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Scroll Down Invitation Button (Bottom Right)
            Positioned(
              bottom: 14,
              right: 16,
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, _) {
                  return Transform.translate(
                    offset: Offset(0, _arrowBounceAnim.value),
                    child: InkWell(
                      onTap: widget.onScrollDownTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B6B44),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x331B6B44), blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Floating Garden',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackHouse() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFE8CF9F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text('🏡 Sparrow Manor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
