import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/auth_config.dart';
import '../../services/notification_service.dart';
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
          // Section 4: GEDA & DISCOM Admin Command & Dispatch
          _buildSectionHeader('GEDA & DISCOM ADMIN DISPATCH'),
          const SizedBox(height: 10),
          _buildMenuTile(
            context,
            icon: '📢',
            title: 'Grid Advisory & Citizen Despatch',
            subtitle: 'Remind specific citizens by email or broadcast peak load shifts across Gujarat',
            accentColor: const Color(0xFFEF4444),
            onTap: () {
              Navigator.pop(context);
              _showAdminReminderDialog(context);
            },
          ),
          const SizedBox(height: 18),

          // Section 5: System Settings & Sign Out
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

  void _showAdminReminderDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AdminDispatchModal(),
    );
  }
}

class _AdminDispatchModal extends StatefulWidget {
  const _AdminDispatchModal();

  @override
  State<_AdminDispatchModal> createState() => _AdminDispatchModalState();
}

class _AdminDispatchModalState extends State<_AdminDispatchModal> {
  int _scopeMode = 0; // 0: Specific Citizen, 1: District, 2: Statewide
  final _emailController = TextEditingController();
  final _titleController = TextEditingController(text: 'Peak Grid Load Shift (18:00 - 22:00)');
  final _messageController = TextEditingController(
    text: 'Urgent Grid Notice: Gujarat transmission peak in progress. Please turn off ACs and shift heavy pumping or washing to post-22:00.',
  );
  String _selectedDistrict = 'Ahmedabad';
  String _urgency = 'HIGH';
  int _coins = 15;
  bool _isSending = false;

  final List<String> _districts = const [
    'Ahmedabad',
    'Surat',
    'Vadodara',
    'Rajkot',
    'Gandhinagar',
    'Bhavnagar',
    'Jamnagar',
  ];

  @override
  void initState() {
    super.initState();
    final userEmail = AuthService.instance.currentUser?.email;
    _emailController.text = (userEmail != null && userEmail.isNotEmpty) ? userEmail : 'citizen@urjavatika.in';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _applyTemplate(String title, String message, String urgency, int coins) {
    HapticFeedback.selectionClick();
    setState(() {
      _titleController.text = title;
      _messageController.text = message;
      _urgency = urgency;
      _coins = coins;
    });
  }

  Future<void> _sendDispatch() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    setState(() => _isSending = true);
    HapticFeedback.heavyImpact();

    final targetEmail = _scopeMode == 0 ? _emailController.text.trim() : null;
    final targetDistrict = _scopeMode == 1 ? _selectedDistrict : null;

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.postUrl(Uri.parse('${AuthConfig.apiBaseUrl}/admin/send-reminder'));
      req.headers.contentType = ContentType.json;
      final token = AuthService.instance.accessToken;
      if (token != null && token.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      req.write(jsonEncode({
        'title': title,
        'message': message,
        'category': 'ALERT',
        if (targetEmail != null && targetEmail.isNotEmpty) 'targetUserEmail': targetEmail,
        if (targetDistrict != null) 'targetDistrict': targetDistrict,
        'incentiveCoins': _coins,
        'urgency': _urgency,
      }));

      final resp = await req.close();
      final bodyStr = await resp.transform(utf8.decoder).join();
      client.close();

      String scopeDesc = 'State-wide Gujarat';
      if (_scopeMode == 0) scopeDesc = 'Citizen ($targetEmail)';
      if (_scopeMode == 1) scopeDesc = '$targetDistrict District';

      try {
        final parsed = jsonDecode(bodyStr) as Map<String, dynamic>;
        if (parsed['scope'] is String) {
          scopeDesc = parsed['scope'] as String;
        }
      } catch (_) {}

      await NotificationService.instance.showSystemNotification(
        title: '[DISCOM / GEDA] $title',
        message: message,
        id: 7001,
        actionButton: 'Claim +$_coins 🪙 Mudra',
      );

      GameStateService.instance.addNotification(
        title: '📢 [DISCOM / GEDA] $title',
        message: message,
        type: 'admin_reminder',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF15803D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                const Text('📢', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Despatched successfully to $scopeDesc! Push notification sent.',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      await NotificationService.instance.showSystemNotification(
        title: '[DISCOM / GEDA] $title',
        message: message,
        id: 7001,
        actionButton: 'Claim +$_coins 🪙 Mudra',
      );
      GameStateService.instance.addNotification(
        title: '📢 [DISCOM / GEDA] $title',
        message: message,
        type: 'admin_reminder',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF047857),
            content: Text('Notice despatched locally to notification shade ($e)'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0C2417),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -8)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: const Center(child: Text('📢', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GEDA & DISCOM Dispatch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Targeted citizen reminders & grid load shift advisory',
                        style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Scope Selector
            const Text(
              'RECIPIENT TARGET SCOPE',
              style: TextStyle(
                color: Color(0xFF86EFAC),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildScopeChip(0, '👤 Specific Citizen'),
                const SizedBox(width: 6),
                _buildScopeChip(1, '🏛️ District'),
                const SizedBox(width: 6),
                _buildScopeChip(2, '🌍 Statewide'),
              ],
            ),
            const SizedBox(height: 12),

            // Target input depending on scope
            if (_scopeMode == 0) ...[
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Citizen Registered Email',
                  labelStyle: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4ADE80), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF143B23),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1F5435)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF4ADE80), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
            ] else if (_scopeMode == 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF143B23),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1F5435)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    dropdownColor: const Color(0xFF143B23),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    items: _districts.map((d) => DropdownMenuItem(value: d, child: Text('$d District (Gujarat)'))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDistrict = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Quick Preset Templates
            const Text(
              'QUICK ADVISORY TEMPLATES',
              style: TextStyle(
                color: Color(0xFF86EFAC),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTemplateChip(
                    '⚡ Peak Load Shift',
                    'Peak Grid Load Shift (18:00 - 22:00)',
                    'Urgent Grid Notice: Gujarat transmission peak in progress. Please turn off ACs and shift heavy pumping or washing to post-22:00.',
                    'HIGH',
                    20,
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    '🔌 Standby Unplug',
                    'Unplug Idle Chargers & Wall Plugs',
                    'Vampire Load Warning: Idle phone chargers left in active sockets drain standby power 24/7. Turn off wall switches now.',
                    'MEDIUM',
                    10,
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    '☀️ Midday Solar Peak',
                    'Midday Solar Peak Active (11:00 - 15:00)',
                    'PM Surya Ghar Alert: Solar generation is peaking. Run your overhead water pump and induction cooking now on 100% clean solar!',
                    'LOW',
                    25,
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    '💧 Water Pump Hours',
                    'Scheduled Municipal Water Supply Advisory',
                    'Municipal water release scheduled in your ward. Fill overhead storage tanks before 17:00 to optimize grid distribution.',
                    'MEDIUM',
                    15,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Title
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Advisory Headline / Title',
                labelStyle: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF143B23),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1F5435)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF4ADE80), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),

            // Message
            TextField(
              controller: _messageController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Despatch Message / Guidance',
                labelStyle: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF143B23),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1F5435)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF4ADE80), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Urgency & Incentive Coins Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'URGENCY PRIORITY',
                        style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildUrgencyChip('HIGH', const Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          _buildUrgencyChip('MEDIUM', const Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          _buildUrgencyChip('LOW', const Color(0xFF22C55E)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'INCENTIVE: +$_coins 🪙',
                      style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Slider(
                      value: _coins.toDouble(),
                      min: 0,
                      max: 50,
                      divisions: 10,
                      activeColor: const Color(0xFFF59E0B),
                      inactiveColor: Colors.white24,
                      onChanged: (v) => setState(() => _coins = v.round()),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Despatch Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendDispatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: const Color(0xFF05200E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Color(0xFF05200E), strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📢', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text(
                            'Dispatch Reminder to Citizen',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
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

  Widget _buildScopeChip(int mode, String label) {
    final selected = _scopeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _scopeMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF22C55E) : const Color(0xFF143B23),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? Colors.white : const Color(0xFF1F5435)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF05200E) : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateChip(String label, String title, String msg, String urgency, int coins) {
    return GestureDetector(
      onTap: () => _applyTemplate(title, msg, urgency, coins),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10361F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String level, Color color) {
    final selected = _urgency == level;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _urgency = level);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.3) : const Color(0xFF143B23),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Text(
          level,
          style: TextStyle(
            color: selected ? color : Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

