import 'package:flutter/material.dart';
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
class SanctuaryPlayShell extends StatefulWidget {
  const SanctuaryPlayShell({super.key, required this.onOpenDashboard});

  final VoidCallback onOpenDashboard;

  @override
  State<SanctuaryPlayShell> createState() => _SanctuaryPlayShellState();
}

class _SanctuaryPlayShellState extends State<SanctuaryPlayShell> {
  final PageController _verticalController = PageController();
  final PageController _horizontalController = PageController(initialPage: 1);

  int _verticalPage = 0;

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
                        onOpenDashboard: widget.onOpenDashboard,
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
        ],
      ),
    );
  }
}
