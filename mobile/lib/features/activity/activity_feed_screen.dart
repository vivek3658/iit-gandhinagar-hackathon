import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final String _selectedCategory = 'All Activities';

  final List<ActivityEventItem> _events = [
    ActivityEventItem(
      icon: '⚡',
      iconBg: Color(0xFFFEF3C7),
      title: 'Used less electricity',
      metric: '+0.8 kg CO₂e',
      time: '8:12 AM',
      description: 'Kept AC at 26°C for 4 hours',
    ),
    ActivityEventItem(
      icon: '✔️',
      iconBg: Color(0xFFE8F5E9),
      title: 'Completed daily task',
      metric: '+10 pts',
      time: '9:30 AM',
      description: 'Checked room temperature',
    ),
    ActivityEventItem(
      icon: '💡',
      iconBg: Color(0xFFFEF3C7),
      title: 'Turned off unused lights',
      metric: '+0.3 kg CO₂e',
      time: '11:45 AM',
      description: 'Living room lights',
    ),
    ActivityEventItem(
      icon: '💧',
      iconBg: Color(0xFFE0F2FE),
      title: 'Watered your plant',
      metric: '+5 pts',
      time: '2:10 PM',
      description: 'Your Tulsi plant is happy! 🪴',
    ),
    ActivityEventItem(
      icon: '🚌',
      iconBg: Color(0xFFE8F5E9),
      title: 'Used public transport',
      metric: '+1.2 kg CO₂e',
      time: '5:40 PM',
      description: 'College commute (Bus)',
    ),
    ActivityEventItem(
      icon: '🏆',
      iconBg: Color(0xFFFEF3C7),
      title: 'Completed 3 tasks!',
      metric: '+30 pts',
      time: '9:15 PM',
      description: 'You\'re doing great! 🥳',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: UrjaColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Activity Feed',
          style: TextStyle(
            color: UrjaColors.textMain,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2EBE5)),
            ),
            child: Row(
              children: [
                Text(
                  _selectedCategory,
                  style: const TextStyle(color: UrjaColors.textSub, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: UrjaColors.textSub),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A log of your actions and impact',
              style: TextStyle(
                color: UrjaColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Today · Oct 30, 2026',
              style: TextStyle(
                color: UrjaColors.textSub,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Event Cards
            Column(
              children: _events.map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: e.iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text(e.icon, style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.title,
                                  style: const TextStyle(
                                    color: UrjaColors.textMain,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  e.metric,
                                  style: const TextStyle(
                                    color: Color(0xFF1B6B44),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              e.time,
                              style: const TextStyle(
                                color: UrjaColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.description,
                              style: const TextStyle(
                                color: UrjaColors.textSub,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityEventItem {
  final String icon;
  final Color iconBg;
  final String title;
  final String metric;
  final String time;
  final String description;

  const ActivityEventItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.metric,
    required this.time,
    required this.description,
  });
}
