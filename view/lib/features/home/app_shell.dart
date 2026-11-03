import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../community/community_screen.dart';
import '../garden/garden_screen.dart';
import '../learning/learning_screen.dart';
import '../tracking/tracking_screen.dart';
import 'today_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _openLearning() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LearningScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        TodayScreen(
          isActive: _index == 0,
          onOpenDevices: () => setState(() => _index = 2),
          onOpenGarden: () => setState(() => _index = 1),
          onOpenCommunity: () => setState(() => _index = 3),
          onOpenLearning: _openLearning,
        ),
        GardenScreen(isActive: _index == 1),
        const TrackingScreen(),
        const CommunityScreen(),
      ],
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E583D), Color(0xFF12392F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFB7DD8D), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5530472A),
                offset: Offset(0, 5),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              _NavigationDockItem(
                selected: _index == 0,
                icon: Icons.wb_sunny_rounded,
                label: 'Home',
                onTap: () => setState(() => _index = 0),
              ),
              _NavigationDockItem(
                selected: _index == 1,
                icon: Icons.park_rounded,
                label: 'Garden',
                onTap: () => setState(() => _index = 1),
              ),
              _NavigationDockItem(
                selected: _index == 2,
                icon: Icons.bolt_rounded,
                label: 'Track',
                onTap: () => setState(() => _index = 2),
              ),
              _NavigationDockItem(
                selected: _index == 3,
                icon: Icons.groups_rounded,
                label: 'Community',
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NavigationDockItem extends StatelessWidget {
  const _NavigationDockItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? const Color(0xFFE7F7C9) : Colors.transparent,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(19),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: selected
                        ? UrjaColors.forest
                        : Colors.white.withValues(alpha: .82),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? UrjaColors.forest
                          : Colors.white.withValues(alpha: .82),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
