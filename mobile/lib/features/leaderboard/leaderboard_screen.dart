import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<DistrictLeaderboardItem> _districts = const [
    DistrictLeaderboardItem(rank: 1, name: 'Surat', co2SavedTons: 1420.5, solarKwh: 382000, participants: 48200, badge: '🥇 Top Solar City'),
    DistrictLeaderboardItem(rank: 2, name: 'Ahmedabad', co2SavedTons: 1280.2, solarKwh: 345000, participants: 62400, badge: '🥈 Peak Reducer'),
    DistrictLeaderboardItem(rank: 3, name: 'Vadodara', co2SavedTons: 910.8, solarKwh: 240000, participants: 31200, badge: '🥉 Green Canopy'),
    DistrictLeaderboardItem(rank: 4, name: 'Rajkot', co2SavedTons: 785.4, solarKwh: 198000, participants: 27500, badge: '⚡ Energy Champion'),
    DistrictLeaderboardItem(rank: 5, name: 'Bhavnagar', co2SavedTons: 620.1, solarKwh: 165000, participants: 19800, badge: '🌊 Coastal Wind'),
    DistrictLeaderboardItem(rank: 6, name: 'Gandhinagar', co2SavedTons: 540.9, solarKwh: 142000, participants: 18400, badge: '🌿 Model Green Capital'),
    DistrictLeaderboardItem(rank: 7, name: 'Jamnagar', co2SavedTons: 495.2, solarKwh: 130000, participants: 15300, badge: '✨ Clean Port'),
  ];

  final List<CitizenLeaderboardItem> _citizens = const [
    CitizenLeaderboardItem(rank: 1, name: 'Aarav Patel', district: 'Surat', co2SavedKg: 420.8, level: 21, avatar: '👨‍🌾'),
    CitizenLeaderboardItem(rank: 2, name: 'Diya Shah', district: 'Ahmedabad', co2SavedKg: 385.2, level: 19, avatar: '👩‍🔬'),
    CitizenLeaderboardItem(rank: 3, name: 'Kavya Joshi', district: 'Vadodara', co2SavedKg: 340.5, level: 18, avatar: '👩‍🏫'),
    CitizenLeaderboardItem(rank: 4, name: 'You (Citizen)', district: 'Ahmedabad', co2SavedKg: 280.0, level: 14, avatar: '🕊️', isCurrentUser: true),
    CitizenLeaderboardItem(rank: 5, name: 'Rohan Mehta', district: 'Rajkot', co2SavedKg: 245.1, level: 12, avatar: '👨‍💻'),
    CitizenLeaderboardItem(rank: 6, name: 'Ananya Desai', district: 'Gandhinagar', co2SavedKg: 210.4, level: 10, avatar: '👩‍🎨'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UrjaColors.emeraldBg,
      appBar: AppBar(
        backgroundColor: UrjaColors.emeraldBg,
        elevation: 0,
        title: const Text(
          'Gujarat Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: UrjaColors.primaryGreen,
          labelColor: UrjaColors.primaryGreen,
          unselectedLabelColor: UrjaColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: '33 Districts'),
            Tab(text: 'Top Citizens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDistrictTab(),
          _buildCitizenTab(),
        ],
      ),
    );
  }

  Widget _buildDistrictTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _districts.length,
      itemBuilder: (context, index) {
        final d = _districts[index];
        final isTop3 = d.rank <= 3;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: UrjaColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTop3 ? UrjaColors.primaryGreen.withValues(alpha: 0.4) : UrjaColors.borderGreen,
              width: isTop3 ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isTop3
                      ? UrjaColors.primaryGreen.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${d.rank}',
                    style: TextStyle(
                      color: isTop3 ? UrjaColors.primaryGreen : UrjaColors.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          d.badge,
                          style: const TextStyle(
                            color: UrjaColors.sunnyYellow,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.participants.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} households · ${(d.solarKwh / 1000).toStringAsFixed(0)}k kWh solar',
                      style: const TextStyle(
                        color: UrjaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // CO2 Prevented
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${d.co2SavedTons.toStringAsFixed(1)} T',
                    style: const TextStyle(
                      color: UrjaColors.primaryGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'CO2 Saved',
                    style: TextStyle(
                      color: UrjaColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCitizenTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _citizens.length,
      itemBuilder: (context, index) {
        final c = _citizens[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.isCurrentUser
                ? UrjaColors.primaryGreen.withValues(alpha: 0.15)
                : UrjaColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: c.isCurrentUser ? UrjaColors.primaryGreen : UrjaColors.borderGreen,
              width: c.isCurrentUser ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '#${c.rank}',
                style: TextStyle(
                  color: c.isCurrentUser ? UrjaColors.primaryGreen : UrjaColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(c.avatar, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        color: c.isCurrentUser ? UrjaColors.primaryGreen : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${c.district} · Level ${c.level} Sparrow',
                      style: const TextStyle(
                        color: UrjaColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${c.co2SavedKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: UrjaColors.amberGold,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Carbon Avoided',
                    style: TextStyle(
                      color: UrjaColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class DistrictLeaderboardItem {
  final int rank;
  final String name;
  final double co2SavedTons;
  final double solarKwh;
  final int participants;
  final String badge;

  const DistrictLeaderboardItem({
    required this.rank,
    required this.name,
    required this.co2SavedTons,
    required this.solarKwh,
    required this.participants,
    required this.badge,
  });
}

class CitizenLeaderboardItem {
  final int rank;
  final String name;
  final String district;
  final double co2SavedKg;
  final int level;
  final String avatar;
  final bool isCurrentUser;

  const CitizenLeaderboardItem({
    required this.rank,
    required this.name,
    required this.district,
    required this.co2SavedKg,
    required this.level,
    required this.avatar,
    this.isCurrentUser = false,
  });
}
