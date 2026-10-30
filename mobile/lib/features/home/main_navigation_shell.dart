import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../sanctuary/sanctuary_home_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../carbon/carbon_impact_screen.dart';
import '../activity/activity_feed_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SanctuaryHomeScreen(),
    CarbonImpactDashboardScreen(),
    LeaderboardScreen(),
    ActivityFeedScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UrjaColors.emeraldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: UrjaColors.cardSurface,
          border: Border(
            top: BorderSide(color: UrjaColors.borderGreen, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: UrjaColors.cardSurface,
          selectedItemColor: UrjaColors.primaryGreen,
          unselectedItemColor: UrjaColors.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.yard_rounded),
              label: 'Sanctuary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.co2_rounded),
              label: 'Carbon',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_rounded),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}
