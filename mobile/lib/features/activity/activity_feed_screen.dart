import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  String _selectedCategory = 'ALL';

  final List<ActivityItemModel> _activities = [
    ActivityItemModel(
      id: '1',
      category: 'HABIT',
      title: 'Welcome to Urja Sanctuary! 🌿',
      message: 'You received 50 Urja Mudra coins to embark on your Mission LiFE journey.',
      icon: 'spark',
      coinsEarned: 50,
      district: 'Ahmedabad',
      timeAgo: 'Just now',
      isRead: false,
    ),
    ActivityItemModel(
      id: '2',
      category: 'ALERT',
      title: 'Peak Grid Hour Reminder ⚡',
      message: 'Ahmedabad grid peak begins at 6:30 PM. Switch off standby appliances to earn 2x bonus points!',
      icon: 'zap',
      district: 'Ahmedabad',
      timeAgo: '1 hr ago',
      isRead: false,
    ),
    ActivityItemModel(
      id: '3',
      category: 'COMMUNITY',
      title: 'Surat Solar Park Milestone ☀️',
      message: 'Citizens in Surat collectively generated 25,000 kWh of rooftop solar energy this week!',
      icon: 'solar',
      district: 'Surat',
      timeAgo: '3 hrs ago',
      isRead: false,
    ),
    ActivityItemModel(
      id: '4',
      category: 'SANCTUARY',
      title: 'Rajkot Eco-Gardener Landmark 🌳',
      message: 'Citizen Patel unlocked the Sacred Canopy Banyan tree after saving 120 kg of CO2.',
      icon: 'tree',
      district: 'Rajkot',
      timeAgo: '5 hrs ago',
      isRead: true,
    ),
    ActivityItemModel(
      id: '5',
      category: 'HABIT',
      title: 'Solar Water Heater Bonus 🚿',
      message: 'Completed morning warm bath using solar thermal water heater. +10 Urja Mudra awarded.',
      icon: 'sun',
      coinsEarned: 10,
      district: 'Ahmedabad',
      timeAgo: '1 day ago',
      isRead: true,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (var a in _activities) {
        a.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read!'),
        backgroundColor: UrjaColors.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'ALL'
        ? _activities
        : _activities.where((a) => a.category == _selectedCategory).toList();

    final unreadCount = _activities.where((a) => !a.isRead).length;

    return Scaffold(
      backgroundColor: UrjaColors.emeraldBg,
      appBar: AppBar(
        backgroundColor: UrjaColors.emeraldBg,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Activity & Alerts',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: UrjaColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: UrjaColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['ALL', 'HABIT', 'ALERT', 'COMMUNITY', 'SANCTUARY'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: UrjaColors.primaryGreen,
                    backgroundColor: UrjaColors.cardSurface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : UrjaColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? UrjaColors.primaryGreen : UrjaColors.borderGreen,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Activity List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => item.isRead = true);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.isRead ? UrjaColors.cardSurface : const Color(0xFF1B382B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.isRead
                            ? UrjaColors.borderGreen
                            : UrjaColors.primaryGreen.withValues(alpha: 0.5),
                        width: item.isRead ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Circle
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(item.category).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getEmojiForCategory(item.category),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        color: item.isRead ? Colors.white : UrjaColors.primaryGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.timeAgo,
                                    style: const TextStyle(
                                      color: UrjaColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.message,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              if (item.coinsEarned != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: UrjaColors.amberGold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🪙', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+${item.coinsEarned} Urja Mudra',
                                        style: const TextStyle(
                                          color: UrjaColors.sunnyYellow,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'ALERT':
        return Colors.orange;
      case 'COMMUNITY':
        return Colors.lightBlue;
      case 'SANCTUARY':
        return Colors.teal;
      default:
        return UrjaColors.primaryGreen;
    }
  }

  String _getEmojiForCategory(String cat) {
    switch (cat) {
      case 'ALERT':
        return '⚡';
      case 'COMMUNITY':
        return '🏙️';
      case 'SANCTUARY':
        return '🌳';
      default:
        return '🌿';
    }
  }
}

class ActivityItemModel {
  final String id;
  final String category;
  final String title;
  final String message;
  final String icon;
  final int? coinsEarned;
  final String district;
  final String timeAgo;
  bool isRead;

  ActivityItemModel({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.icon,
    this.coinsEarned,
    required this.district,
    required this.timeAgo,
    this.isRead = false,
  });
}
