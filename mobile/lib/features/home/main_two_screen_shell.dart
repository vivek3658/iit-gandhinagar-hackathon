import 'package:flutter/material.dart';

import '../../constants/urja_theme.dart';
import '../activity/activity_feed_notifications_screen.dart';
import '../appliances/device_time_log_sheet.dart';
import '../appliances/registered_devices_screen.dart';
import '../carbon/carbon_impact_screen.dart';
import '../dashboard/citizen_learning_screen.dart';
import '../dashboard/citizen_records_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../settings/user_settings_screen.dart';
import 'citizen_home_screen.dart';
import 'sanctuary_play_shell.dart';

class MainTwoScreenShell extends StatefulWidget {
  const MainTwoScreenShell({super.key});

  @override
  State<MainTwoScreenShell> createState() => _MainTwoScreenShellState();
}

class _MainTwoScreenShellState extends State<MainTwoScreenShell> {
  int _currentIndex = 1;

  void _selectTab(int index) => setState(() => _currentIndex = index);

  void _openActivity() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActivityFeedNotificationsScreen(
          onBackToSanctuary: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const UserSettingsScreen()));
  }

  void _openLearning() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CitizenLearningScreen()),
    );
  }

  void _openRecords() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CitizenRecordsScreen()),
    );
  }

  void _openImpact() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CarbonImpactDashboardScreen(),
      ),
    );
  }

  void _openCommunity() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LeaderboardScreen()));
  }

  void _openDeviceLog() => DeviceTimeLogSheet.show(context);

  void _openRegisteredDevices() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegisteredDevicesScreen()),
    );
  }

  late final List<Widget> _screens = [
    CitizenHomeScreen(
      onOpenActivity: _openActivity,
      onOpenSettings: _openSettings,
      onOpenRecords: _openRecords,
      onOpenImpact: _openImpact,
      onOpenDeviceLog: _openDeviceLog,
      onOpenRegisteredDevices: _openRegisteredDevices,
      onOpenLearning: _openLearning,
      onOpenCommunity: _openCommunity,
      onOpenPlay: () => _selectTab(1),
    ),
    SanctuaryPlayShell(onOpenDashboard: () => _selectTab(0)),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: UrjaTheme.canvas,
    body: IndexedStack(index: _currentIndex, children: _screens),
  );
}
