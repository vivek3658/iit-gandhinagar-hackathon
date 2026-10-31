import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/geofence_departure_service.dart';
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

class SanctuaryMenuScreen extends StatefulWidget {
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

  @override
  State<SanctuaryMenuScreen> createState() => _SanctuaryMenuScreenState();
}

class _SanctuaryMenuScreenState extends State<SanctuaryMenuScreen> {
  final GeofenceDepartureService _geofence = GeofenceDepartureService.instance;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF102B1D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('🚪', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Sign Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from UrjaVatika? Your garden island and companion vitality are safely preserved.',
          style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 13, height: 1.4),
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

  void _triggerDepartureGeofenceTest() async {
    HapticFeedback.heavyImpact();
    await _geofence.simulateDeparture(350.0);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF15803D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Row(
            children: [
              Text('📍', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Simulated 350m Departure! Check your phone notification shade for the "Claim +10 🪙" action button.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateService.instance;
    final user = AuthService.instance.currentUser;
    final userName = user?.name ?? 'Gujarat Eco Citizen';
    final userWard = user?.ward ?? 'Navrangpura';
    final userDistrict = user?.district ?? 'Ahmedabad';

    return Scaffold(
      backgroundColor: const Color(0xFF06140D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06140D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Command Hub & Menu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0.5,
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
          // 1. Digital Citizen Passport Card (Modern Glassmorphic Card)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF143B23), Color(0xFF0D2818)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.8), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xFF051B0E), offset: Offset(0, 4), blurRadius: 0),
                BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Center(
                        child: Text('🕊️', style: TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF22C55E)),
                                ),
                                child: const Text(
                                  'CITIZEN VERIFIED',
                                  style: TextStyle(
                                    color: Color(0xFF86EFAC),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$userWard Ward • $userDistrict (Gujarat)',
                            style: const TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFF92400E), offset: Offset(0, 1.5)),
                                  ],
                                ),
                                child: Text(
                                  '🪙 ${state.coins} Mudra',
                                  style: const TextStyle(
                                    color: Color(0xFF92400E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFF15803D), offset: Offset(0, 1.5)),
                                  ],
                                ),
                                child: Text(
                                  '🌱 ${state.co2eSavedKg.toStringAsFixed(1)} kg Cut',
                                  style: const TextStyle(
                                    color: Color(0xFF05200E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. HERO FEATURE: 300m Home Departure Geofence Guardian
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3220), Color(0xFF0A2216)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xFF0284C7), offset: Offset(0, 4), blurRadius: 0),
                BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF38BDF8)),
                      ),
                      child: const Center(
                        child: Text('📍', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '300m HOME DEPARTURE GUARDIAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Reminds you to switch off AC, geysers & unplug wall sockets when leaving.',
                            style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Distance indicator bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _geofence.isOutsideGeofence ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_geofence.isOutsideGeofence ? const Color(0xFFEF4444) : const Color(0xFF22C55E)).withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _geofence.isOutsideGeofence
                                ? 'Status: Departed (> 300m)'
                                : 'Status: Inside Home (${_geofence.currentDistanceMeters.toInt()}m)',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        'Threshold: 300m',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons: Test Alert & Request Permission
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: GestureDetector(
                        onTap: _triggerDepartureGeofenceTest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Color(0xFF0369A1), offset: Offset(0, 3)),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('📲', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 6),
                              Text(
                                'Test 300m Notification',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          await _geofence.requestPermission();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Location Permission requested!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF143B23),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF22C55E)),
                          ),
                          child: const Center(
                            child: Text(
                              'Permission',
                              style: TextStyle(
                                color: Color(0xFF86EFAC),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
              widget.onSlideToWardrobe();
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
            icon: '💧',
            title: 'Water Conservation & Timed Supply',
            subtitle: 'Municipal water schedules, overhead tank flow & RO wastewater reuse',
            accentColor: const Color(0xFF0284C7),
            onTap: () {
              Navigator.pop(context);
              WaterConservationSheet.show(context);
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '📱',
            title: 'Household Appliance Registry',
            subtitle: 'Manage normalized appliances (AC, refrigerator, geyser, induction)',
            accentColor: const Color(0xFF10B981),
            onTap: () {
              Navigator.pop(context);
              ApplianceRegistrySheet.show(context);
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '🚴',
            title: 'Green Commute & Electric BRTS',
            subtitle: 'Log bicycle trips, Metro rides & EV 2-wheeler charging habits',
            accentColor: const Color(0xFFD97706),
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
            subtitle: 'Configure your 3.2 kW solar setup, battery storage & net metering savings',
            accentColor: const Color(0xFFEAB308),
            onTap: () {
              Navigator.pop(context);
              EnergySetupSheet.show(context);
            },
          ),
          const SizedBox(height: 18),

          // Section 4: System Settings & Sign Out
          _buildSectionHeader('SYSTEM PREFERENCES & ACCOUNT'),
          const SizedBox(height: 10),
          _buildMenuTile(
            context,
            icon: '⚙️',
            title: 'Sanctuary Settings & Behavior',
            subtitle: 'Sound effects, night dimming, idle timeouts & behavioral coach tone',
            accentColor: const Color(0xFF8B5CF6),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSettingsScreen()));
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: '🚪',
            title: 'Sign Out Account',
            subtitle: 'Safely disconnect from UrjaVatika cloud session',
            accentColor: const Color(0xFFEF4444),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF86EFAC),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF10361F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1F5435), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0xFF062312), offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.5)),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFA7F3D0),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: accentColor.withValues(alpha: 0.8), size: 20),
          ],
        ),
      ),
    );
  }
}
