import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../appliances/appliance_registry_sheet.dart';
import '../appliances/device_time_log_sheet.dart';
import '../auth/google_login_screen.dart';
import '../calculator/carbon_calculator_screen.dart';
import '../commute/commute_travel_sheet.dart';
import '../dashboard/carbon_dashboard_sheet.dart';
import '../dashboard/daily_quests_sheet.dart';
import '../dashboard/monthly_electricity_tracker_sheet.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../onboarding/energy_setup_sheet.dart';
import '../settings/user_settings_screen.dart';
import '../water/water_conservation_sheet.dart';

class SanctuaryMenuScreen extends StatelessWidget {
  final VoidCallback onSlideToActivity;
  final VoidCallback onSlideToWardrobe;

  const SanctuaryMenuScreen({
    super.key,
    required this.onSlideToActivity,
    required this.onSlideToWardrobe,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onSlideToActivity,
    required VoidCallback onSlideToWardrobe,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SanctuaryMenuScreen(
          onSlideToActivity: onSlideToActivity,
          onSlideToWardrobe: onSlideToWardrobe,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF143522),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('🚪', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Sign Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from UrjaVatika? Your garden island and mascot vitality are safely stored.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AuthService.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const GoogleLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateService.instance;
    final user = AuthService.instance.currentUser;
    final userName = user?.name ?? 'Gujarat Eco Citizen';
    final userWard = user?.ward ?? 'Navrangpura';
    final userDistrict = user?.district ?? 'Ahmedabad';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1D13), // Deep 3D Forest Green
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1D13),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Command Hub & Menu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          // Top Citizen Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF10361F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Center(
                    child: Text('🕊️', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$userWard Ward • $userDistrict',
                        style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🪙 ${state.coins} Mudra',
                              style: const TextStyle(color: Color(0xFF92400E), fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🌱 ${state.co2eSavedKg.toStringAsFixed(1)} kg Cut',
                              style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Section 1: Core Gaming & Social Features
          _buildSectionHeader('GAME REALMS & COMPETITION'),
          const SizedBox(height: 10),
          _buildMenuTile(
            context,
            icon: '🏆',
            title: 'Multiplayer Leaderboards & Leagues',
            subtitle: 'Duolingo-style weekly leagues (Bronze to Diamond) & visit citizen islands',
            accentColor: const Color(0xFFF59E0B),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '👗',
            title: '3D Wardrobe Fitting Studio',
            subtitle: 'Dress your Indian Sparrow in hats, garlands, scarves & eco accessories',
            accentColor: const Color(0xFF38BDF8),
            onTap: () {
              Navigator.pop(context);
              onSlideToWardrobe();
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '🎯',
            title: 'Daily Mission LiFE Quests',
            subtitle: 'Complete rotating eco habits, maintain streaks & claim Urja Mudra rewards',
            accentColor: const Color(0xFF22C55E),
            onTap: () {
              Navigator.pop(context);
              DailyQuestsSheet.show(context);
            },
          ),
          const SizedBox(height: 18),

          // Section 2: Energy & Carbon Analytics
          _buildSectionHeader('ENERGY & CARBON ANALYTICS'),
          const SizedBox(height: 10),
          _buildMenuTile(
            context,
            icon: '🌱',
            title: 'Interactive Carbon Calculator',
            subtitle: '4-step household footprint questionnaire with Gujarat & India benchmarks',
            accentColor: const Color(0xFF4ADE80),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CarbonCalculatorScreen()));
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '📊',
            title: 'Senior Engineer Energy Dashboard',
            subtitle: '24-hour load curve, appliance consumption split & multi-domain CO₂e ledger',
            accentColor: const Color(0xFF10B981),
            onTap: () {
              Navigator.pop(context);
              CarbonDashboardSheet.show(context);
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '⏱️',
            title: 'Appliance Runtime Logger',
            subtitle: 'Log operating hours for AC, Geyser & Sump pump with high-hour warning alerts',
            accentColor: const Color(0xFFF97316),
            onTap: () {
              Navigator.pop(context);
              DeviceTimeLogSheet.show(context);
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '📈',
            title: 'Monthly Electricity Meter Tracker',
            subtitle: 'Analyze monthly DISCOM bill trends, units consumed & solar offset',
            accentColor: const Color(0xFFFBBF24),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => const MonthlyElectricityTrackerSheet(),
              );
            },
          ),
          const SizedBox(height: 18),

          // Section 3: Smart Household Domains & IoT
          _buildSectionHeader('HOUSEHOLD PILLARS & CONSERVATION'),
          const SizedBox(height: 10),
          _buildMenuTile(
            context,
            icon: '⚡',
            title: 'Activity Feed & System Alerts',
            subtitle: 'Real-time environmental event stream, notifications & audit records',
            accentColor: const Color(0xFFF59E0B),
            onTap: () {
              Navigator.pop(context);
              onSlideToActivity();
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '📱',
            title: 'Electronic Appliance Registry',
            subtitle: 'Catalog split ACs, refrigerators, water heaters & smart IoT devices',
            accentColor: const Color(0xFF60A5FA),
            onTap: () {
              Navigator.pop(context);
              ApplianceRegistrySheet.show(context);
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '💧',
            title: 'Water Conservation & Sump Pump',
            subtitle: 'Municipal piped schedule, rainwater recharge wells & overflow alerts',
            accentColor: const Color(0xFF38BDF8),
            onTap: () {
              Navigator.pop(context);
              WaterConservationSheet.show(context);
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '🚴',
            title: 'Daily Green Commute Garage',
            subtitle: 'Log EV 2-Wheeler rides, BRTS / Metro commutes, and bicycle trips',
            accentColor: const Color(0xFF34D399),
            onTap: () {
              Navigator.pop(context);
              CommuteTravelSheet.show(context);
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '☀️',
            title: 'PM Surya Ghar Rooftop Solar',
            subtitle: 'Configure grid-tied solar net metering, inverter capacity & DISCOM export',
            accentColor: const Color(0xFFFCD34D),
            onTap: () {
              Navigator.pop(context);
              EnergySetupSheet.show(context);
            },
          ),
          const SizedBox(height: 18),

          // Section 4: Citizen Preferences & Identity
          _buildSectionHeader('CITIZEN SETTINGS & ACCOUNT'),
          const SizedBox(height: 10),
          _buildMenuTile(
            context,
            icon: '⚙️',
            title: 'Citizen Settings Hub',
            subtitle: 'Ward selection, mascot bedtime schedule, touch sensitivity, audio & haptics',
            accentColor: const Color(0xFF94A3B8),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSettingsScreen()));
            },
          ),
          const SizedBox(height: 14),

          // Sign out button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF261010),
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Sign Out from Citizen Account',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF86EFAC),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF143522),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.35)),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }
}
