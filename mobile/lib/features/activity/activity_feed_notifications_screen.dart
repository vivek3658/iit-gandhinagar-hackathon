import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';
import '../../services/notification_service.dart';

/// Left Scroll Screen: Gamified Activity Feed & 3D Tactile Notification Center.
///
/// Features:
/// - Pure 3D Skeuomorphic Eco-Pop UI matching Sanctuary forest-green theme (#06140D, #0A1D13, #10361F).
/// - Real Android System Notification Test Hub: Triggers genuine system shade notifications on device.
/// - 3D tactile notification cards with beveled edges, deep shadows, and category color-coding.
/// - Evidence Tier Badges: Tier A (Verified Hardware), Tier B (Command Sent), Tier C (Estimated).
/// - Interactive 1-tap 3D action buttons inside cards that award Urja Mudra coins and log habits.
/// - Community LiFE feed with instant cheer/applause interactions (+2 Urja Mudra).
class ActivityFeedNotificationsScreen extends StatefulWidget {
  final VoidCallback onBackToSanctuary;

  const ActivityFeedNotificationsScreen({
    super.key,
    required this.onBackToSanctuary,
  });

  @override
  State<ActivityFeedNotificationsScreen> createState() =>
      _ActivityFeedNotificationsScreenState();
}

class _ActivityFeedNotificationsScreenState
    extends State<ActivityFeedNotificationsScreen> {
  final GameStateService _state = GameStateService.instance;
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'All Alerts',
    'System Shade',
    'Nudges',
    'Community LiFE',
    'Achievements'
  ];

  final Set<String> _cheeredEvents = {};

  final List<Map<String, dynamic>> _communityEvents = [
    {
      'id': 'comm_1',
      'title': 'Surat Solar Rooftop Initiative',
      'desc':
          'Surat citizen households installed 1.2 MW rooftop solar today, avoiding 42 tonnes CO₂e.',
      'tag': 'Community LiFE',
      'city': 'Surat',
      'time': '12m ago',
      'icon': '☀️',
      'cheers': 142,
    },
    {
      'id': 'comm_2',
      'title': 'Ahmedabad Green BRTS Commute',
      'desc':
          '14,200 electric bus rides recorded today, cutting peak diesel emissions.',
      'tag': 'Community LiFE',
      'city': 'Ahmedabad',
      'time': '1h ago',
      'icon': '🚌',
      'cheers': 98,
    },
    {
      'id': 'comm_3',
      'title': 'Vadodara Canal Solar Microgrid',
      'desc':
          'Over-canal solar panels generated 45,000 kWh of clean water-conserving power.',
      'tag': 'Community LiFE',
      'city': 'Vadodara',
      'time': '3h ago',
      'icon': '🌊',
      'cheers': 230,
    },
    {
      'id': 'comm_4',
      'title': 'Gandhinagar Zero Phantom Drain',
      'desc':
          'Government offices and citizen homes completed the 9:00 PM wall socket sweep.',
      'tag': 'Nudges',
      'city': 'Gandhinagar',
      'time': '5h ago',
      'icon': '🔌',
      'cheers': 77,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Ensure native Android notification permission is active
    NotificationService.instance.requestPermission();
  }

  void _onCheerCommunity(String eventId) {
    if (_cheeredEvents.contains(eventId)) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _cheeredEvents.add(eventId);
      final evt = _communityEvents.firstWhere((e) => e['id'] == eventId);
      evt['cheers'] = (evt['cheers'] as int) + 1;
    });
    _state.addCoins(2);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❤️ Cheered Gujarat Eco Community! +2 Urja Mudra 🪙'),
        backgroundColor: Color(0xFFD97706),
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  void _triggerNativeNotification({
    required String type,
    required String title,
    required String body,
    required int id,
  }) async {
    HapticFeedback.heavyImpact();
    if (type == 'charger') {
      await NotificationService.instance.triggerChargerUnplugNudge();
    } else if (type == 'departure') {
      await NotificationService.instance.triggerDepartureNotification(distance: 300.0);
    } else if (type == 'solar') {
      await NotificationService.instance.triggerLearningNotification('solar');
    } else if (type == 'phantom') {
      await NotificationService.instance.triggerLearningNotification('phantom');
    } else {
      await NotificationService.instance.showSystemNotification(
        title: title,
        message: body,
        id: id,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1B6B44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Text('🔔', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivered to Android System Shade: "$title"',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _executeNotificationAction(Map<String, dynamic> item) {
    HapticFeedback.heavyImpact();
    final type = item['type'] as String? ?? 'nudge';

    int awardCoins = 5;
    double co2Saved = 0.05;
    String feedback = 'Habit recorded!';

    if (type.contains('charger')) {
      awardCoins = 5;
      co2Saved = 0.01;
      feedback = '🔌 Wall switch confirmed OFF! Avoided phantom vampire load (+5 🪙)';
    } else if (type.contains('ac') || type.contains('temperature')) {
      awardCoins = 15;
      co2Saved = 1.97;
      feedback = '📡 IR Command: AC set to 24°C! Saved 2.4 kWh overnight (+15 🪙)';
    } else if (type.contains('water')) {
      awardCoins = 10;
      co2Saved = 0.12;
      feedback = '💧 Water conservation logged (+10 🪙, +0.12 kg CO₂e)';
    } else if (type.contains('system') || type.contains('welcome')) {
      awardCoins = 10;
      co2Saved = 0.02;
      feedback = '🕊️ Companion affection received! (+10 🪙)';
    }

    _state.recordEcoAction(
      actionName: item['title'] as String,
      co2Saved: co2Saved,
      coinsAwarded: awardCoins,
    );

    setState(() {
      item['read'] = true;
      item['actionTaken'] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF15803D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          feedback,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final notifications = _state.notificationHistory;
        final unreadCount = notifications.where((n) => n['read'] == false).length;

        return Scaffold(
          backgroundColor: const Color(0xFF06140D), // Deep Nature Forest
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Atmospheric 3D Forest Nature Green Gradient (Harmonized with Sanctuary)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF06140D),
                      Color(0xFF0A1D13),
                      Color(0xFF102B1D),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top 3D Claymorphic Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF143B23), Color(0xFF10361F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF062312),
                              offset: Offset(0, 4),
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 3D Feed Title
                            const Expanded(
                              child: Row(
                                children: [
                                  Text('⚡', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Eco-Feed & Alerts',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Unread Notifications Pill
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFF991B1B), offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Text(
                                  '$unreadCount New',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),

                            // Return to Sanctuary 3D Button
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.onBackToSanctuary();
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF86EFAC), width: 1),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFF15803D), offset: Offset(0, 3)),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'Sanctuary',
                                      style: TextStyle(
                                        color: Color(0xFF05200E),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF05200E), size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Filter Chips Bar (Tactile 3D Nature Buttons)
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final isSelected = _selectedFilterIndex == i;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedFilterIndex = i);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF10361F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF86EFAC) : const Color(0xFF1F5435),
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? const [BoxShadow(color: Color(0xFF15803D), offset: Offset(0, 3))]
                                    : const [BoxShadow(color: Color(0xFF062312), offset: Offset(0, 2))],
                              ),
                              child: Center(
                                child: Text(
                                  _filters[i],
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF05200E) : const Color(0xFFA7F3D0),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Combined Feed List (3D Claymorphic Forest Cards)
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        children: [
                          // SECTION: Real Android System Push Notifications Hub
                          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
                            _buildSystemShadeTestingSection(),
                            const SizedBox(height: 18),
                          ],

                          // Notifications Center Section
                          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Text('🔔', style: TextStyle(fontSize: 14)),
                                    SizedBox(width: 6),
                                    Text(
                                      'ACTIVE NUDGES & ALERTS',
                                      style: TextStyle(
                                        color: Color(0xFFFBBF24),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                if (unreadCount > 0)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _state.markAllNotificationsRead();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF143B23),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF1F5435)),
                                      ),
                                      child: const Text(
                                        'Mark all read',
                                        style: TextStyle(
                                          color: Color(0xFF86EFAC),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (notifications.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10361F),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF1F5435)),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0xFF062312), offset: Offset(0, 4)),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'No unread alerts. Your home energy is running optimal! ✨',
                                    style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              )
                            else
                              ...notifications.map((n) => _build3DNotificationCard(n)),
                            const SizedBox(height: 18),
                          ],

                          // Gujarat Community LiFE Feed Section
                          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3) ...[
                            const Row(
                              children: [
                                Text('🏛️', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 6),
                                Text(
                                  'GUJARAT MISSION LiFE COMMUNITY',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._communityEvents.map((evt) => _build3DCommunityCard(evt)),
                            const SizedBox(height: 18),
                          ],

                          // Achievements Section
                          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 4) ...[
                            const Row(
                              children: [
                                Text('🏆', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 6),
                                Text(
                                  'SANCTUARY ACHIEVEMENTS',
                                  style: TextStyle(
                                    color: Color(0xFFA78BFA),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildAchievementCard(
                              title: 'Sanctuary Pioneer (Level 1)',
                              desc: 'Adopted Chibi Sparrow and established your 3×3 starter garden island.',
                              progress: 1.0,
                              icon: '🌱',
                              coins: 100,
                            ),
                            const SizedBox(height: 10),
                            _buildAchievementCard(
                              title: 'Zero Vampire Power (Standby Slayer)',
                              desc: 'Cut wall plug switch 5 times to prevent continuous inductive drain.',
                              progress: 0.6,
                              icon: '🔌',
                              coins: 50,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Interactive Real Android System Notifications Hub
  Widget _buildSystemShadeTestingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF143B23), Color(0xFF10361F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0xFF062312), offset: Offset(0, 4), blurRadius: 0),
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📲', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REAL ANDROID SYSTEM NOTIFICATIONS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Delivers genuine notifications to your physical Android shade with sound & vibration.',
                      style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Grid of real system notification triggers
          Row(
            children: [
              Expanded(
                child: _buildSystemTriggerButton(
                  icon: '🔌',
                  title: 'Charger Unplug',
                  subtitle: 'Wall Switch OFF',
                  color: const Color(0xFFEF4444),
                  shadowColor: const Color(0xFF991B1B),
                  onTap: () => _triggerNativeNotification(
                    type: 'charger',
                    title: '🔌 Charger Unplugged! Save Standby Power',
                    body: 'Turn off the wall socket switch to avoid continuous phantom drain.',
                    id: 2001,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSystemTriggerButton(
                  icon: '🚨',
                  title: 'High AC Runtime',
                  subtitle: '8.5h Usage (>5h)',
                  color: const Color(0xFFF59E0B),
                  shadowColor: const Color(0xFFB45309),
                  onTap: () => _triggerNativeNotification(
                    type: 'ac_excess',
                    title: '🚨 High AC Usage Alert (8.5 hrs today)',
                    body: 'Inverter AC exceeded eco limit by 3.5 hrs. Potential excess: ₹585/mo. Set to 24°C eco mode!',
                    id: 4001,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSystemTriggerButton(
                  icon: '☀️',
                  title: 'Solar Peak Window',
                  subtitle: '11 AM - 3 PM Noon',
                  color: const Color(0xFF22C55E),
                  shadowColor: const Color(0xFF15803D),
                  onTap: () => _triggerNativeNotification(
                    type: 'solar',
                    title: '☀️ Solar Peak Window (11 AM - 3 PM)',
                    body: 'Prime rooftop solar active! Run water pumps & washing machines now.',
                    id: 3002,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSystemTriggerButton(
                  icon: '🌙',
                  title: '9 PM Standby Sweep',
                  subtitle: 'Vampire Drain Kill',
                  color: const Color(0xFF38BDF8),
                  shadowColor: const Color(0xFF0284C7),
                  onTap: () => _triggerNativeNotification(
                    type: 'phantom',
                    title: '💡 Phantom Vampire Load Alert',
                    body: 'Turn off TV and microwave wall switches before bed to save ~₹155/mo.',
                    id: 3001,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSystemTriggerButton(
                  icon: '📍',
                  title: '300m Left Home Alert',
                  subtitle: 'Includes "Claim +10 🪙" Action Button',
                  color: const Color(0xFF38BDF8),
                  shadowColor: const Color(0xFF0284C7),
                  onTap: () => _triggerNativeNotification(
                    type: 'departure',
                    title: '⚡ Left Home (300m)? Turn Off Wall Switches',
                    body: 'Did you turn off the AC & geyser? Confirm to prevent phantom vampire drain (~1.2 kg CO₂e).',
                    id: 5001,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTriggerButton({
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2818),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
          boxShadow: [
            BoxShadow(color: shadowColor.withValues(alpha: 0.5), offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DNotificationCard(Map<String, dynamic> item) {
    final title = item['title'] as String;
    final message = item['message'] as String;
    final isUnread = item['read'] == false;
    final type = item['type'] as String? ?? 'nudge';
    final actionTaken = item['actionTaken'] == true;

    // Palette determination based on type and evidence tier
    Color themeColor = const Color(0xFFF59E0B); // Amber default
    Color bottomShadowColor = const Color(0xFFB45309);
    String evidenceTier = 'Tier C: Estimated';
    String actionLabel = 'Log Habit (+5 🪙)';
    IconData iconData = Icons.notifications_active_rounded;

    if (type.contains('charger')) {
      themeColor = const Color(0xFFEF4444); // Coral
      bottomShadowColor = const Color(0xFF991B1B);
      evidenceTier = 'Tier A: Verified (Phone Hardware)';
      actionLabel = 'Wall Switch OFF (+5 🪙)';
      iconData = Icons.power_off_rounded;
    } else if (type.contains('ac') || type.contains('temperature')) {
      themeColor = const Color(0xFFF59E0B); // Amber / Gold
      bottomShadowColor = const Color(0xFFB45309);
      evidenceTier = 'Tier B: Command Sent (IR Blaster)';
      actionLabel = 'Send IR: Set 24°C (+15 🪙)';
      iconData = Icons.ac_unit_rounded;
    } else if (type.contains('water')) {
      themeColor = const Color(0xFF06B6D4); // Cyan
      bottomShadowColor = const Color(0xFF0E7490);
      evidenceTier = 'Tier C: Timed Supply';
      actionLabel = 'Log Water Conserved (+10 🪙)';
      iconData = Icons.water_drop_rounded;
    } else if (type.contains('commute')) {
      themeColor = const Color(0xFF22C55E); // Emerald
      bottomShadowColor = const Color(0xFF15803D);
      evidenceTier = 'Tier A: Displacement Trip';
      actionLabel = 'Log Green Ride (+30 🪙)';
      iconData = Icons.directions_bike_rounded;
    } else {
      themeColor = const Color(0xFF8B5CF6); // Violet
      bottomShadowColor = const Color(0xFF5B21B6);
      evidenceTier = 'System Event';
      actionLabel = 'Acknowledge (+5 🪙)';
      iconData = Icons.eco_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10361F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread ? themeColor : const Color(0xFF1F5435),
          width: isUnread ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF062312),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
          const BoxShadow(
            color: Colors.black38,
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3D Beveled Icon Container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: themeColor.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(color: bottomShadowColor, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Center(
                    child: Icon(iconData, color: themeColor, size: 22),
                  ),
                ),
                const SizedBox(width: 12),

                // Title + Evidence Tag + Unread Dot
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: themeColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: themeColor.withValues(alpha: 0.8),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          evidenceTier,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Message Body
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFD1FAE5),
                fontSize: 12,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 12),

            // Interactive 1-Tap 3D Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!actionTaken)
                  ElevatedButton(
                    onPressed: () => _executeNotificationAction(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Credited to Ledger',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DCommunityCard(Map<String, dynamic> evt) {
    final id = evt['id'] as String;
    final isCheered = _cheeredEvents.contains(id);
    final cheers = evt['cheers'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10361F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF062312),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black38,
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(evt['icon'] as String, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              evt['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            evt['time'] as String,
                            style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 10),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${evt['city']} • Gujarat Mission LiFE',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              evt['desc'] as String,
              style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '❤️ $cheers Citizens Cheered',
                  style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w600),
                ),
                ElevatedButton.icon(
                  onPressed: () => _onCheerCommunity(id),
                  icon: Icon(
                    isCheered ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 14,
                    color: isCheered ? Colors.redAccent : Colors.black,
                  ),
                  label: Text(isCheered ? 'Cheered!' : 'Cheer (+2 🪙)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheered ? const Color(0xFF143B23) : const Color(0xFF38BDF8),
                    foregroundColor: isCheered ? const Color(0xFF86EFAC) : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard({
    required String title,
    required String desc,
    required double progress,
    required String icon,
    required int coins,
  }) {
    final isComplete = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10361F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF062312),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black38,
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA78BFA)),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '+$coins 🪙',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 11),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? const Color(0xFF22C55E) : const Color(0xFFA78BFA),
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
