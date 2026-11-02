import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';
import '../activity/activity_feed_notifications_screen.dart';
import '../game/mascot_sanctuary_screen.dart';
import '../game/garden_island_screen.dart';
import '../wardrobe/wardrobe_fitting_screen.dart';

/// Main Multi-Axis Navigation Shell for URJA ONE Game Universe:
/// - Horizontal Axis:
///   - Page 0 (Slide Left): Activity Feed & System Notification Center.
///   - Page 1 (Center Hub): Main Realm (3D Sanctuary <-> 3D Garden Island).
///   - Page 2 (Slide Right): Dedicated 3D Wardrobe Fitting Room.
/// - Vertical Axis:
///   - Page 0: 3D Sparrow Mascot Sanctuary.
///   - Page 1: 3D Floating Garden Island.
class MainTwoScreenShell extends StatefulWidget {
  const MainTwoScreenShell({super.key});

  @override
  State<MainTwoScreenShell> createState() => _MainTwoScreenShellState();
}

class _MainTwoScreenShellState extends State<MainTwoScreenShell> {
  final PageController _verticalController = PageController();
  final PageController _horizontalController = PageController(initialPage: 1);

  int _verticalPage = 0;
  int _horizontalPage = 1;

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _scrollToGarden() {
    _verticalController.animateToPage(
      1,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  void _scrollToSanctuary() {
    _verticalController.animateToPage(
      0,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  void _slideToActivity() {
    _horizontalController.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _slideToSanctuary() {
    _horizontalController.animateToPage(
      1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _slideToWardrobe() {
    _horizontalController.animateToPage(
      2,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Horizontal PageView:
          // [0: Activity Feed] <-> [1: Center Hub (Sanctuary / Garden)] <-> [2: Wardrobe Studio]
          PageView(
            controller: _horizontalController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (page) => setState(() => _horizontalPage = page),
            children: [
              // Screen 0: Activity Feed & System Notification Center (Slide Left)
              ActivityFeedNotificationsScreen(
                onBackToSanctuary: _slideToSanctuary,
              ),

              // Screen 1: Center Hub: Mascot Sanctuary <-> 3D Garden Island
              ListenableBuilder(
                listenable: GameStateService.instance,
                builder: (context, _) {
                  final isGardenPage = _verticalPage == 1;
                  final isScrollLocked =
                      GameStateService.instance.gardenScrollLocked;
                  return PageView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    // When on Garden and scroll lock is active, harden the gesture physics
                    // to prevent accidental page switching during 3D garden manipulation!
                    physics: (isGardenPage && isScrollLocked)
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _verticalPage = page),
                    children: [
                      MascotSanctuaryScreen(
                        onScrollToGarden: _scrollToGarden,
                        onSlideToWardrobe: _slideToWardrobe,
                        onSlideToActivity: _slideToActivity,
                      ),
                      GardenIslandScreen(
                        onScrollToSanctuary: _scrollToSanctuary,
                      ),
                    ],
                  );
                },
              ),

              // Screen 2: Dedicated Wardrobe Fitting Room Screen (Slide Right)
              WardrobeFittingScreen(onBackToSanctuary: _slideToSanctuary),
            ],
          ),

          // Floating Edge Game Universe Navigation Indicators (Right edge in Center Hub)
          if (_horizontalPage == 1 && _verticalPage == 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 88,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFDCE8DF)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x160F172A),
                        blurRadius: 18,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIndicator(
                        isActive: _verticalPage == 0,
                        icon: Icons.flutter_dash_rounded,
                        label: 'Sanctuary',
                        tooltip: 'Mascot Sanctuary',
                        onTap: _scrollToSanctuary,
                      ),
                      _buildIndicator(
                        isActive: _verticalPage == 1,
                        icon: Icons.park_rounded,
                        label: 'Garden',
                        tooltip: 'Floating Island',
                        onTap: _scrollToGarden,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required bool isActive,
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 14 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF16834A) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : const Color(0xFF64756A),
              ),
              if (isActive) ...[
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
