import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/citizen_api.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  Map<String, dynamic>? _leaderboard;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _leaderboard = await CitizenApi.instance.getLeaderboard();
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = _leaderboard?['members'];
    final list = members is List
        ? members.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : <Map<String, dynamic>>[];
    final league = _leaderboard?['league'] as String?;
    final rank = _leaderboard?['yourRank'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community league'),
        backgroundColor: UrjaColors.canvas,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(19, 8, 19, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [UrjaColors.forest, UrjaColors.navy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Grow together',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _LeagueBadge(league: league ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rank is num && rank > 0
                        ? 'You’re at rank ${rank.toInt()} in this weekly group.'
                        : 'Your rank appears when there is activity in your group.',
                    style: const TextStyle(
                      color: Color(0xFFDCEFE3),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Ranks reflect game activity—not verified household emissions.',
                    style: TextStyle(color: Color(0xFFB7D1C0), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'This week',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (_loading && _leaderboard == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null && _leaderboard == null)
              _RetryPanel(message: _error!, onRetry: _load)
            else if (list.isEmpty)
              const _EmptyLeague()
            else
              for (final member in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _MemberTile(member: member),
                ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: UrjaColors.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite_border_rounded, color: UrjaColors.forest),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A kind word helps. When community actions become available, cheer on a neighbor’s progress without comparing environmental impact.',
                      style: TextStyle(
                        color: UrjaColors.ink,
                        fontSize: 12,
                        height: 1.4,
                      ),
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
}

class _LeagueBadge extends StatelessWidget {
  const _LeagueBadge({required this.league});

  final String league;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF4BB4E),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      league,
      style: const TextStyle(
        color: UrjaColors.ink,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String? ?? 'Community member';
    final district = member['district'] as String? ?? 'Gujarat';
    final rank = member['rank'] is num ? (member['rank'] as num).toInt() : 0;
    final weeklyPoints = member['weeklyExp'] is num
        ? (member['weeklyExp'] as num).toInt()
        : 0;
    final isCurrent = member['isCurrentUser'] == true;
    return Card(
      color: isCurrent ? UrjaColors.mint : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF1D9),
          foregroundColor: UrjaColors.forest,
          child: Text(
            rank == 0 ? '·' : '$rank',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(district),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$weeklyPoints',
              style: const TextStyle(
                color: UrjaColors.forest,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'activity pts',
              style: TextStyle(color: UrjaColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLeague extends StatelessWidget {
  const _EmptyLeague();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Icon(Icons.groups_2_rounded, size: 38, color: UrjaColors.leaf),
          const SizedBox(height: 10),
          const Text(
            'Your league is taking shape',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Complete a learning chapter or sorting game to contribute when this group opens.',
            textAlign: TextAlign.center,
            style: TextStyle(color: UrjaColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _RetryPanel extends StatelessWidget {
  const _RetryPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
