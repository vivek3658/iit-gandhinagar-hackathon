import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';

/// Left Scroll Screen: Activity Feed & System Notification Center.
///
/// Features:
/// - Connected with Gujarat Mission LiFE live events and system alerts.
/// - Unread badge tracking for Charger Unplug & Bedtime Sweep reminders.
/// - Filterable feed categories: All Alerts, Nudges, Community LiFE, Achievements.
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
    'Nudges',
    'Community LiFE',
    'Achievements'
  ];

  final List<Map<String, dynamic>> _communityEvents = [
    {
      'id': 'comm_1',
      'title': 'Surat Solar Rooftop Initiative',
      'desc': 'Surat citizen households installed 1.2 MW rooftop solar today, avoiding 42 tonnes CO2e.',
      'tag': 'Community LiFE',
      'time': '12m ago',
      'icon': '☀️',
    },
    {
      'id': 'comm_2',
      'title': 'Ahmedabad Green BRTS Commute',
      'desc': '14,200 electric bus rides recorded today, cutting peak diesel emissions.',
      'tag': 'Community LiFE',
      'time': '1h ago',
      'icon': '🚌',
    },
    {
      'id': 'comm_3',
      'title': 'Vadodara Canal Solar Microgrid',
      'desc': 'Over-canal solar panels generated 45,000 kWh of clean water-conserving power.',
      'tag': 'Community LiFE',
      'time': '3h ago',
      'icon': '🌊',
    },
    {
      'id': 'comm_4',
      'title': 'Gandhinagar Zero Phantom Drain',
      'desc': 'Government offices joined the 9:00 PM wall socket sweep.',
      'tag': 'Nudges',
      'time': '5h ago',
      'icon': '🔌',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final notifications = _state.notificationHistory;
        final unreadCount = notifications.where((n) => n['read'] == false).length;

        return Scaffold(
          backgroundColor: const Color(0xFF091F14),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Atmospheric Background Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF062314),
                      Color(0xFF0F3822),
                      Color(0xFF091F14),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top Navigation Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Eco-Feed & Alerts',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text('📢', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                                Text(
                                  'Mission LiFE Stream & Alerts',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFF86EFAC),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Unread Notifications Pill
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount New',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          // Back to Sanctuary Button
                          InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onBackToSanctuary();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B6B44),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF4ADE80)),
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'Sanctuary',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Filter Chips Bar
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final isSelected = _selectedFilterIndex == i;
                          return ChoiceChip(
                            label: Text(_filters[i]),
                            selected: isSelected,
                            selectedColor: const Color(0xFF22C55E),
                            backgroundColor: const Color(0xFF153823),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedFilterIndex = i);
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Combined Feed List
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          // Notifications Center Section
                          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'NOTIFICATION CENTER',
                                  style: TextStyle(
                                    color: Color(0xFF86EFAC),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _state.markAllNotificationsRead();
                                    },
                                    child: const Text(
                                      'Mark all read',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (notifications.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No unread alerts. Your home energy is optimal! 🌿',
                                    style: TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                ),
                              )
                            else
                              ...notifications.map((n) => _buildNotificationCard(n)),
                            const SizedBox(height: 16),
                          ],

                          // Gujarat Community LiFE Feed Section
                          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
                            const Text(
                              'GUJARAT MISSION LiFE COMMUNITY',
                              style: TextStyle(
                                color: Color(0xFF86EFAC),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._communityEvents.map((evt) => _buildCommunityCard(evt)),
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

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final title = item['title'] as String;
    final message = item['message'] as String;
    final isUnread = item['read'] == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFF1B4D31) : const Color(0xFF122E1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? const Color(0xFF34D399) : Colors.white10,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUnread ? const Color(0xFF22C55E) : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['type'] == 'nudge'
                  ? Icons.notifications_active_rounded
                  : Icons.eco_rounded,
              color: isUnread ? Colors.black : Colors.white70,
              size: 16,
            ),
          ),
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
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> evt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF112A1D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(evt['icon'] as String, style: const TextStyle(fontSize: 22)),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      evt['time'] as String,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  evt['desc'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
