import 'package:flutter/material.dart';
import '../models/wardrobe_models.dart';
import 'weather_fx_painter.dart';

class InteractiveMascotStage extends StatefulWidget {
  final Map<String, String?> equipped;
  final MascotPoseDef currentPose;
  final VoidCallback onPet;
  final double height;
  final bool showBackground;

  const InteractiveMascotStage({
    super.key,
    required this.equipped,
    required this.currentPose,
    required this.onPet,
    this.height = 320,
    this.showBackground = true,
  });

  @override
  State<InteractiveMascotStage> createState() => _InteractiveMascotStageState();
}

class _InteractiveMascotStageState extends State<InteractiveMascotStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _breatheAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _tiltAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _breatheAnim = Tween<double>(begin: 0.985, end: 1.025).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    _tiltAnim = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: widget.showBackground
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 0.85,
                colors: [Color(0xFFFDF8EC), Color(0xFFEFE6CF)],
              ),
              border: Border.all(color: const Color(0xFFE3D8BD), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A2F4A2A),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Weather / Ambient FX Background layer
            AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return WeatherFxOverlay(
                  activeFx: widget.equipped['fx'],
                  activeProp: widget.currentPose.prop,
                  animationValue: _animController.value,
                );
              },
            ),

            // 2. Interactive Mascot & Accessories
            GestureDetector(
              onTap: widget.onPet,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: Transform.rotate(
                      angle: _tiltAnim.value,
                      child: Transform.scale(
                        scale: _breatheAnim.value,
                        child: _buildMascotComposite(),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Pose-specific text badges (Level Up or Gift announcement)
            if (widget.currentPose.id == 'levelup')
              Positioned(
                top: 16,
                child: _buildLevelUpBanner(),
              ),

            if (widget.currentPose.id == 'announce')
              Positioned(
                top: 16,
                right: 20,
                child: _buildNewBadge(),
              ),

            // 4. Tap-to-Pet subtle pill at bottom
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE3D8BD)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💖', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      widget.currentPose.id == 'petted'
                          ? 'Chirpy loves your affection! 🥰'
                          : 'Tap Chirpy to pet',
                      style: const TextStyle(
                        color: Color(0xFF2F4A2A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotComposite() {
    final head = widget.equipped['head'];
    final face = widget.equipped['face'];
    final neck = widget.equipped['neck'];
    final held = widget.equipped['held'];
    final hasBlush = widget.currentPose.hasBlush;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Fluffy Sparrow Mascot
          Image.asset(
            'assets/images/onboarding/hero_1.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/sparrow_branch_hero.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/cheerful_bird_512.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // BLUSH Overlay (if petted or blushing pose)
          if (hasBlush)
            Positioned(
              top: 96,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCheekBlush(-1),
                  const SizedBox(width: 76),
                  _buildCheekBlush(1),
                ],
              ),
            ),

          // NECK Accessory
          if (neck != null)
            Positioned(
              top: 108,
              child: _buildNeckAccessory(neck),
            ),

          // FACE Accessory (Glasses / Sunglasses)
          if (face != null)
            Positioned(
              top: 72,
              child: _buildFaceAccessory(face),
            ),

          // HEAD Accessory (Hats / Caps / Crowns)
          if (head != null)
            Positioned(
              top: 10,
              child: _buildHeadAccessory(head),
            ),

          // HELD Accessory (Umbrella / Leafbrella)
          if (held != null)
            Positioned(
              bottom: 24,
              right: 10,
              child: _buildHeldAccessory(held),
            ),
        ],
      ),
    );
  }

  Widget _buildCheekBlush(double dir) {
    return Container(
      width: 22,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFFF7F9A).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7F9A).withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildHeadAccessory(String id) {
    switch (id) {
      case 'beanie':
        return _buildAccessoryPill(
          icon: '🧶',
          label: 'Wool Beanie',
          bgColor: const Color(0xFF3F7FB5),
          fgColor: Colors.white,
        );
      case 'santa':
        return _buildAccessoryPill(
          icon: '🎅',
          label: 'Santa Cap',
          bgColor: const Color(0xFFC62828),
          fgColor: Colors.white,
        );
      case 'straw':
        return _buildAccessoryPill(
          icon: '👒',
          label: 'Straw Hat',
          bgColor: const Color(0xFFE6C57A),
          fgColor: const Color(0xFF5A3615),
        );
      case 'flowers':
        return _buildAccessoryPill(
          icon: '🌸',
          label: 'Flower Crown',
          bgColor: const Color(0xFFF48FB1),
          fgColor: Colors.white,
        );
      case 'acorn':
        return _buildAccessoryPill(
          icon: '🌰',
          label: 'Acorn Beret',
          bgColor: const Color(0xFF8A5A2B),
          fgColor: Colors.white,
        );
      case 'rainhat':
        return _buildAccessoryPill(
          icon: '🌧️',
          label: 'Yellow Rainhat',
          bgColor: const Color(0xFFF6C90E),
          fgColor: const Color(0xFF3A2014),
        );
      case 'gujarati_paghdi':
        return _buildAccessoryPill(
          icon: '👑',
          label: 'Royal Paghdi',
          bgColor: const Color(0xFFEA580C),
          fgColor: Colors.white,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFaceAccessory(String id) {
    switch (id) {
      case 'sunnies':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2A4A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🕶️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 4),
              Text(
                'Solar Sunnies',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      case 'readers':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF6D4C2A), width: 1.8),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('👓', style: TextStyle(fontSize: 16)),
              SizedBox(width: 4),
              Text(
                'Round Readers',
                style: TextStyle(color: Color(0xFF6D4C2A), fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNeckAccessory(String id) {
    Color bg = const Color(0xFFC62828);
    String label = 'Scarf';
    String icon = '🧣';

    switch (id) {
      case 'knit':
        bg = const Color(0xFFC62828);
        label = 'Knit Scarf';
        icon = '🧣';
        break;
      case 'xmas':
        bg = const Color(0xFF2E7D32);
        label = 'Holiday Scarf';
        icon = '🎄';
        break;
      case 'plaid':
        bg = const Color(0xFFC8691F);
        label = 'Plaid Scarf';
        icon = '🟤';
        break;
      case 'lei':
        bg = const Color(0xFFE91E63);
        label = 'Flower Lei';
        icon = '🌺';
        break;
      case 'bow':
        bg = const Color(0xFFF06292);
        label = 'Pink Bow';
        icon = '🎀';
        break;
      case 'collar':
        bg = const Color(0xFFF6C90E);
        label = 'Rain Collar';
        icon = '🟡';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildHeldAccessory(String id) {
    final isLeaf = id == 'leafbrella';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLeaf ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isLeaf ? '🍃' : '☂️', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            isLeaf ? 'Leaf Parasol' : 'Umbrella',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoryPill({
    required String icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelUpBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3A0), Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7A4A00), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x66FFB300), blurRadius: 14, spreadRadius: 2),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌟', style: TextStyle(fontSize: 18)),
          SizedBox(width: 6),
          Text(
            'LEVEL UP! Lv 7',
            style: TextStyle(
              color: Color(0xFF7A4A00),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: const Text(
        'NEW!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
