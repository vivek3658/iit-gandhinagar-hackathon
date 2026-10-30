import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedTab = 'Global';

  final List<LeaderboardItem> _items = const [
    LeaderboardItem(rank: 1, name: 'GreenWarrior', score: '12.5 kg CO₂e', avatar: '🌱', badgeType: 1),
    LeaderboardItem(rank: 2, name: 'EcoSage', score: '11.8 kg CO₂e', avatar: '🐱', badgeType: 2),
    LeaderboardItem(rank: 3, name: 'PlanetFriend', score: '11.2 kg CO₂e', avatar: '🏔️', badgeType: 3),
    LeaderboardItem(rank: 11, name: 'SenseiGreen', score: '8.9 kg CO₂e', avatar: '🧑‍🌾'),
    LeaderboardItem(rank: 12, name: 'You', score: '8.7 kg CO₂e', avatar: '🕊️', isCurrentUser: true, rankChange: '↑ 2'),
    LeaderboardItem(rank: 13, name: 'EcoDreamer', score: '8.4 kg CO₂e', avatar: '🌸'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5), // Light clean nature background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F8F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: UrjaColors.textMain,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Text('🏆', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Card with Crowned 3D Sparrow!
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  // Crowned 3D Sparrow graphic from mockup!
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/sparrow_crown.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You\'re in top',
                          style: TextStyle(
                            color: UrjaColors.textSub,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '#12',
                              style: TextStyle(
                                color: UrjaColors.textMain,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '↑ 2',
                              style: TextStyle(
                                color: Color(0xFF1B6B44),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Keep going, champion! 💚',
                          style: TextStyle(
                            color: Color(0xFF1B6B44),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Segmented Pills: [Global] [Friends] [India]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: ['Global', 'Friends', '🇮🇳 India'].map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = tab),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0F3E2E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              tab,
                              style: TextStyle(
                                color: isSelected ? Colors.white : UrjaColors.textSub,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Leaderboard List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: _items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: item.isCurrentUser ? const Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: item.isCurrentUser ? const Color(0xFFA5D6A7) : const Color(0xFFE2EBE5),
                        width: item.isCurrentUser ? 1.5 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Rank Badge (1, 2, 3 or number)
                        _buildRankBadge(item),
                        const SizedBox(width: 12),

                        // Avatar
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F8F5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(item.avatar, style: const TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 12),

                        // Name & Score
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  color: UrjaColors.textMain,
                                  fontSize: 15,
                                  fontWeight: item.isCurrentUser ? FontWeight.w800 : FontWeight.w700,
                                ),
                              ),
                              Text(
                                item.score,
                                style: const TextStyle(
                                  color: UrjaColors.textSub,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right indicator
                        if (item.isCurrentUser && item.rankChange != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8E6C9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.rankChange!,
                              style: const TextStyle(
                                color: Color(0xFF1B6B44),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          const Text('🍃', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Bottom Callout
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Row(
                children: [
                  Text('🌱', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Top 1% of all URJA ONE users! You\'re making a real difference 🌱',
                      style: TextStyle(
                        color: Color(0xFF1B6B44),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(LeaderboardItem item) {
    if (item.badgeType == 1) {
      return Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
        child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
      );
    }
    if (item.badgeType == 2) {
      return Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle),
        child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
      );
    }
    if (item.badgeType == 3) {
      return Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle),
        child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))),
      );
    }
    return SizedBox(
      width: 30,
      child: Center(
        child: Text(
          '${item.rank}',
          style: const TextStyle(
            color: UrjaColors.textSub,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class LeaderboardItem {
  final int rank;
  final String name;
  final String score;
  final String avatar;
  final int? badgeType;
  final bool isCurrentUser;
  final String? rankChange;

  const LeaderboardItem({
    required this.rank,
    required this.name,
    required this.score,
    required this.avatar,
    this.badgeType,
    this.isCurrentUser = false,
    this.rankChange,
  });
}
