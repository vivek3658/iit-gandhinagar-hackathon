import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/leaderboard_service.dart';
import 'garden_visitor_dialog.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _leagueData;
  Map<String, dynamic>? _globalData;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final league = await LeaderboardClientService.instance.getLeague();
      final global = await LeaderboardClientService.instance.getGlobal();
      if (!mounted) return;
      setState(() { _leagueData = league; _globalData = global; _isLoading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loadError = error.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F261A), // Clay nature dark backdrop
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F261A),
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆 ', style: TextStyle(fontSize: 20)),
            Text(
              'Leaderboard & Leagues',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF143522),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF14532D), offset: Offset(0, 2)),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              tabs: const [
                Tab(text: '🛡️ Weekly League'),
                Tab(text: '🏛️ Gujarat Municipal'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
          : _loadError != null
              ? Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, color: Color(0xFF86EFAC), size: 44), const SizedBox(height: 12), Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 14), FilledButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again'))])))
              : TabBarView(
              controller: _tabController,
              children: [
                _buildLeagueTab(),
                _buildMunicipalTab(),
              ],
            ),
    );
  }

  // ================= 1. DUOLINGO-STYLE WEEKLY LEAGUE TAB =================
  Widget _buildLeagueTab() {
    final leagueName = _leagueData?['league'] as String? ?? 'BRONZE';
    final seasonTimer = _leagueData?['seasonEndsAt'] as String? ?? '';
    final rawMembers = (_leagueData?['members'] as List<dynamic>?) ?? [];
    final members = rawMembers.map((m) => LeagueMemberData.fromJson(m as Map<String, dynamic>)).toList();

    return RefreshIndicator(
      color: const Color(0xFF4ADE80),
      backgroundColor: const Color(0xFF143522),
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Duolingo League Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFF78350F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Center(
                    child: Text('🥇', style: TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$leagueName LEAGUE',
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Top 3 advance to Sapphire League! ⚡',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFFCD34D)),
                          const SizedBox(width: 4),
                          Text(
                            seasonTimer,
                            style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (members.isEmpty)
            _emptyLeaderboard('No verified league members yet', 'Your weekly league appears when the backend has real member activity.')
          else ...[
          // Promotion Zone Marker (Duolingo style)
          _buildZoneHeader('🟢 PROMOTION ZONE (TOP 3 ADVANCE)', const Color(0xFF22C55E)),
          const SizedBox(height: 6),

          // Member List
          for (int i = 0; i < members.length; i++) ...[
            if (i == 3) ...[
              const SizedBox(height: 6),
              _buildZoneHeader('⚪ SAFE ZONE', Colors.white54),
              const SizedBox(height: 6),
            ],
            if (i == 6) ...[
              const SizedBox(height: 6),
              _buildZoneHeader('🔻 DEMOTION ZONE (BOTTOM 3 DROP)', const Color(0xFFEF4444)),
              const SizedBox(height: 6),
            ],
            _buildMemberRow(members[i]),
            const SizedBox(height: 6),
          ],
          ],
        ],
      ),
    );
  }

  Widget _buildZoneHeader(String title, Color col) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: col),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: col,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: col.withValues(alpha: 0.3), height: 1)),
      ],
    );
  }

  Widget _emptyLeaderboard(String title, String message) => Container(
        margin: const EdgeInsets.symmetric(vertical: 18),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: const Color(0xFF143522), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
        child: Column(children: [const Icon(Icons.eco_rounded, color: Color(0xFF86EFAC), size: 34), const SizedBox(height: 10), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)), const SizedBox(height: 6), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4))]),
      );

  Widget _buildMemberRow(LeagueMemberData member) {
    final isTop3 = member.rank <= 3;
    final isYou = member.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isYou
            ? const Color(0xFF1E4C33)
            : (isTop3 ? const Color(0xFF153B25) : const Color(0xFF10281C)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isYou
              ? const Color(0xFF4ADE80)
              : (isTop3 ? const Color(0x6622C55E) : Colors.white12),
          width: isYou ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          SizedBox(
            width: 32,
            child: Text(
              '#${member.rank}',
              style: TextStyle(
                color: isTop3 ? const Color(0xFFFCD34D) : Colors.white60,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // Avatar / Mascot Preview
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A3D2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Text(
                member.gardenSnapshot['previewEmoji'] as String? ?? '🕊️',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & District & Streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isYou ? const Color(0xFF86EFAC) : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      member.district,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• 🔥 ${member.streakDays}d streak',
                      style: const TextStyle(color: Color(0xFFF97316), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Weekly EXP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${member.weeklyExp} XP',
                style: const TextStyle(
                  color: Color(0xFFFDE68A),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),

              // Visit Island Button
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  GardenVisitorDialog.show(
                    context,
                    citizenId: member.citizenId,
                    citizenName: member.name,
                    district: member.district,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x334ADE80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x664ADE80)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Visit', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.w800)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF86EFAC), size: 9),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 2. GUJARAT MUNICIPAL TAB =================
  Widget _buildMunicipalTab() {
    final rawDistricts = (_globalData?['municipalRankings'] as List<dynamic>?) ?? [];
    final districts = rawDistricts.map((d) => MunicipalRankData.fromJson(d as Map<String, dynamic>)).toList();
    final topCitizens = (_globalData?['topCitizens'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // District Rankings Title
        const Text(
          'GUJARAT MUNICIPAL DISTRICTS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),

        if (districts.isEmpty && topCitizens.isEmpty)
          _emptyLeaderboard('No verified rankings yet', 'Rankings appear here after real citizen activity is collected by the backend.'),
        for (final dist in districts) ...[
          _buildDistrictCard(dist),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 20),
        const Text(
          'TOP 100 ALL-TIME CITIZENS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),

        for (final cit in topCitizens) ...[
          _buildTopCitizenCard(cit as Map<String, dynamic>),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDistrictCard(MunicipalRankData dist) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '#${dist.rank}',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dist.district,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${dist.activeCitizens} citizens • ${dist.primaryEnergyMode}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${dist.totalCo2SavedTonnes} T',
                style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 15, fontWeight: FontWeight.w900),
              ),
              const Text(
                'CO₂e avoided',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCitizenCard(Map<String, dynamic> cit) {
    final rank = cit['rank'] as int? ?? 1;
    final name = cit['name'] as String? ?? 'Citizen';
    final district = cit['district'] as String? ?? 'Gujarat';
    final co2 = (cit['totalCo2SavedKg'] as num?)?.toDouble() ?? 100.0;
    final badge = cit['badgeTitle'] as String? ?? 'Eco Guardian';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10281C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(
            rank == 1 ? '🥇' : (rank == 2 ? '🥈' : '🥉'),
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Text(
                  '$district • $badge',
                  style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$co2 kg CO₂e',
            style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
