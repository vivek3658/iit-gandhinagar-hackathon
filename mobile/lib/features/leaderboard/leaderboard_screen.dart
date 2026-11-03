import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/urja_theme.dart';
import '../../services/leaderboard_service.dart';
import 'garden_visitor_dialog.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeagueLeaderboardData? _leagueData;
  GlobalLeaderboardData? _globalData;
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
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final responses = await Future.wait<Object>([
        LeaderboardClientService.instance.getLeague(),
        LeaderboardClientService.instance.getGlobal(),
      ]);
      if (!mounted) return;
      setState(() {
        _leagueData = responses[0] as LeagueLeaderboardData;
        _globalData = responses[1] as GlobalLeaderboardData;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UrjaTheme.canvas,
      appBar: AppBar(
        backgroundColor: UrjaTheme.canvas,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆 ', style: TextStyle(fontSize: 20)),
            Text(
              'Leaderboard & Leagues',
              style: TextStyle(
                color: Color(0xFF0F172A),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: UrjaTheme.leaf,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF14532D), offset: Offset(0, 2)),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: '🛡️ Weekly League'),
                Tab(text: '🏛️ Gujarat Municipal'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: UrjaTheme.leaf),
            )
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: UrjaTheme.muted,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: UrjaTheme.muted),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildLeagueTab(), _buildMunicipalTab()],
            ),
    );
  }

  // ================= 1. DUOLINGO-STYLE WEEKLY LEAGUE TAB =================
  Widget _buildLeagueTab() {
    final league = _leagueData!;
    final leagueName = league.league;
    final seasonTimer = _seasonCountdown(league.seasonEndsAt);
    final members = league.members;

    return RefreshIndicator(
      color: const Color(0xFF4ADE80),
      backgroundColor: Colors.white,
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
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
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
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
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
                      Text(
                        'Top 3 advance to ${_nextLeague(leagueName)}! ⚡',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        league.district.isEmpty
                            ? 'Set your city in Profile to join a league'
                            : '${league.district} • estimated CO₂e this week',
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: Color(0xFFFCD34D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            seasonTimer,
                            style: const TextStyle(
                              color: Color(0xFFFCD34D),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 16),

          _yourLeagueRank(league),
          const SizedBox(height: 12),

          if (members.isEmpty)
            _emptyLeaderboard(
              'No city league members found',
              'Your city league will appear here once your profile is available.',
            )
          else
            for (int i = 0; i < members.length; i++) ...[
              if (members[i].rank == 1) ...[
                _buildZoneHeader(
                  '🟢 PROMOTION ZONE (TOP 3 ADVANCE)',
                  const Color(0xFF22C55E),
                ),
                const SizedBox(height: 6),
              ],
              if (members[i].rank == 4) ...[
                _buildZoneHeader('⚪ SAFE ZONE', Colors.white54),
                const SizedBox(height: 6),
              ],
              if (members[i].status == 'DEMOTING' &&
                  (i == 0 || members[i - 1].status != 'DEMOTING')) ...[
                _buildZoneHeader(
                  '🔻 DEMOTION ZONE (BOTTOM 2 DROP)',
                  const Color(0xFFEF4444),
                ),
                const SizedBox(height: 6),
              ],
              _buildMemberRow(members[i]),
              const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }

  Widget _yourLeagueRank(LeagueLeaderboardData league) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF7ED),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFC9E8CF)),
    ),
    child: Row(
      children: [
        const Icon(Icons.emoji_events_rounded, color: UrjaTheme.forest),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            league.yourRank > 0
                ? 'Your rank: #${league.yourRank} of ${league.totalMembers}'
                : 'Your city league rank is unavailable',
            style: const TextStyle(
              color: UrjaTheme.forest,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  String _nextLeague(String league) => switch (league) {
    'BRONZE' => 'Silver',
    'SILVER' => 'Gold',
    'GOLD' => 'Sapphire',
    'SAPPHIRE' => 'Ruby',
    'RUBY' => 'Diamond',
    _ => 'Diamond',
  };

  String _seasonCountdown(String endsAt) {
    final end = DateTime.tryParse(endsAt)?.toLocal();
    if (end == null) return 'Season end unavailable';
    final remaining = end.difference(DateTime.now());
    if (remaining.isNegative) return 'Season ending';
    if (remaining.inDays > 0) return '${remaining.inDays}d left';
    if (remaining.inHours > 0) return '${remaining.inHours}h left';
    return '${remaining.inMinutes}m left';
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
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      children: [
        const Icon(Icons.eco_rounded, color: Color(0xFF16A34A), size: 34),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _buildMemberRow(LeagueMemberData member) {
    final isTop3 = member.rank <= 3;
    final isYou = member.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isYou ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isYou
              ? const Color(0xFF22C55E)
              : (isTop3 ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
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
                color: isTop3
                    ? const Color(0xFFD97706)
                    : const Color(0xFF64748B),
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
              color: isYou ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isYou
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (member.avatarUrl != null && member.avatarUrl!.isNotEmpty)
                  ? Image.network(
                      member.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          member.gardenSnapshot['previewEmoji'] as String? ??
                              '🕊️',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        member.gardenSnapshot['previewEmoji'] as String? ??
                            '🕊️',
                        style: const TextStyle(fontSize: 20),
                      ),
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
                          color: isYou
                              ? const Color(0xFF166534)
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
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
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• 🔥 ${member.streakDays}d streak',
                      style: const TextStyle(
                        color: Color(0xFFF97316),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Weekly estimated CO2e
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${member.estimatedWeeklyCo2eKg.toStringAsFixed(2)} kg',
                style: const TextStyle(
                  color: Color(0xFF15803D),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Text(
                'estimated CO₂e',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x334ADE80),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x664ADE80)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Visit',
                        style: TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF86EFAC),
                        size: 9,
                      ),
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
    final global = _globalData!;
    final districts = global.municipalRankings;
    final topCitizens = global.topCitizens;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // District Rankings Title
        const Text(
          'GUJARAT CITY RANKINGS · ALL-TIME',
          style: TextStyle(
            color: UrjaTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Cities use the district in each profile. Estimates use user-confirmed walk, bike, and public transit distances against the app’s petrol-car reference factors; they are not verified or credited impact.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),

        if (districts.isEmpty && topCitizens.isEmpty)
          _emptyLeaderboard(
            'No estimated CO₂e rankings yet',
            'City and citizen standings appear after eligible low-carbon trips are saved.',
          ),
        for (final dist in districts) ...[
          _buildDistrictCard(dist),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 20),
        const Text(
          'TOP CITIZENS · ALL-TIME ESTIMATED CO₂e',
          style: TextStyle(
            color: UrjaTheme.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),

        for (final citizen in topCitizens) ...[
          _buildTopCitizenCard(citizen),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDistrictCard(MunicipalRankData dist) {
    final estimatedKg = dist.estimatedCo2eTonnes * 1000;
    final scoreLabel = estimatedKg >= 1000
        ? '${(estimatedKg / 1000).toStringAsFixed(2)} t'
        : '${estimatedKg.toStringAsFixed(1)} kg';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
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
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${dist.activeCitizens} citizens with eligible trips',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                scoreLabel,
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'estimated CO₂e',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCitizenCard(GlobalCitizenRankData citizen) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            citizen.rank == 1
                ? '🥇'
                : citizen.rank == 2
                ? '🥈'
                : citizen.rank == 3
                ? '🥉'
                : '#${citizen.rank}',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 10),
          if (citizen.avatarUrl?.isNotEmpty ?? false) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                citizen.avatarUrl!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  citizen.name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${citizen.district} • Lv ${citizen.mascotLevel} · ${citizen.badgeTitle}',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${citizen.estimatedCo2eKg.toStringAsFixed(2)} kg est. CO₂e',
            style: const TextStyle(
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
