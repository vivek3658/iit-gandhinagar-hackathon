import 'package:flutter/material.dart';

import '../../constants/urja_theme.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/quests_service.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({
    required this.onOpenActivity,
    required this.onOpenSettings,
    required this.onOpenRecords,
    required this.onAddReading,
    required this.onOpenImpact,
    required this.onOpenDeviceLog,
    required this.onOpenRegisteredDevices,
    required this.onOpenLearning,
    required this.onOpenCommunity,
    required this.onOpenPlay,
    super.key,
  });

  final VoidCallback onOpenActivity;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenRecords;
  final VoidCallback onAddReading;
  final VoidCallback onOpenImpact;
  final VoidCallback onOpenDeviceLog;
  final VoidCallback onOpenRegisteredDevices;
  final VoidCallback onOpenLearning;
  final VoidCallback onOpenCommunity;
  final VoidCallback onOpenPlay;

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  DailyQuestsData? _quests;
  AnalyticsDashboardData? _analytics;
  String? _questsError;
  String? _analyticsError;
  bool _isLoading = true;
  String? _claimingQuestId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _questsError = null;
      _analyticsError = null;
    });

    final results = await Future.wait<Object?>([
      QuestsClientService.instance.getDailyQuests().then<Object?>(
        (value) => value,
        onError: (Object error) => error,
      ),
      AnalyticsClientService.instance.getDashboard().then<Object?>(
        (value) => value,
        onError: (Object error) => error,
      ),
    ]);
    if (!mounted) return;

    setState(() {
      if (results[0] is DailyQuestsData) {
        _quests = results[0] as DailyQuestsData;
      } else {
        _questsError = _message(results[0]);
      }
      if (results[1] is AnalyticsDashboardData) {
        _analytics = results[1] as AnalyticsDashboardData;
      } else {
        _analyticsError = _message(results[1]);
      }
      _isLoading = false;
    });
  }

  Future<void> _claimQuest(DailyQuestItem quest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm today’s action'),
        content: Text(
          'You are confirming that you completed “${quest.title}” today. '
          'This is self-reported, not independently verified. '
          'The reward is Green Coins; no CO₂ reduction is credited. Eligible saved trip logs may add a clearly labeled estimate to your city league.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I did this'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _claimingQuestId = quest.id);
    try {
      final result = await QuestsClientService.instance.claimQuest(quest.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      final coins =
          (result['coinsAwarded'] as num?)?.toInt() ?? quest.coinReward;
      final estimatedCo2eKg =
          (result['estimatedCo2eKg'] as num?)?.toDouble() ?? 0;
      try {
        await AuthService.instance.refreshProfile();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mission claimed (+$coins Green Coins), but the balance could not refresh: ${_message(error)}',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            estimatedCo2eKg > 0
                ? '+$coins Green Coins; ${estimatedCo2eKg.toStringAsFixed(2)} kg estimated CO₂e added to this week’s city league.'
                : '+$coins Green Coins added to your account.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    } finally {
      if (mounted) setState(() => _claimingQuestId = null);
    }
  }

  String _message(Object? error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final name = user?.name.trim().split(RegExp(r'\s+')).first;
    final firstName = name == null || name.isEmpty ? 'there' : name;
    final isGuest = AuthService.instance.isGuestMode;

    return Scaffold(
      backgroundColor: UrjaTheme.canvas,
      body: RefreshIndicator(
        onRefresh: _load,
        color: UrjaTheme.leaf,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 12,
            20,
            32,
          ),
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: UrjaTheme.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: UrjaTheme.forest,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR DASHBOARD',
                        style: TextStyle(
                          color: UrjaTheme.forest,
                          fontSize: 11,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Your green day',
                        style: TextStyle(
                          color: UrjaTheme.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _roundIconButton(
                  context,
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Activity',
                  onPressed: widget.onOpenActivity,
                ),
                const SizedBox(width: 8),
                _roundIconButton(
                  context,
                  icon: Icons.person_outline_rounded,
                  tooltip: 'Profile and settings',
                  onPressed: widget.onOpenSettings,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _WelcomeCard(
              firstName: firstName,
              isGuest: isGuest,
              streakDays: _quests?.streakDays,
            ),
            const SizedBox(height: 16),
            _DashboardActions(
              onLearn: widget.onOpenLearning,
              onAddReading: widget.onAddReading,
              onLeaderboard: widget.onOpenCommunity,
            ),
            const SizedBox(height: 22),
            _sectionTitle(
              'Your progress',
              action: 'See impact',
              onAction: widget.onOpenImpact,
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: Listenable.merge([
                GameStateService.instance,
                AuthService.instance,
              ]),
              builder: (context, _) => Row(
                children: [
                  Expanded(
                    child: _ProgressCard(
                      icon: Icons.toll_rounded,
                      label: 'Green Coins',
                      value:
                          '${AuthService.instance.currentUser?.points ?? GameStateService.instance.coins}',
                      detail: 'Spend in your garden',
                      color: UrjaTheme.amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProgressCard(
                      icon: Icons.spa_rounded,
                      label: 'Sparrow level',
                      value: '${GameStateService.instance.mascotLevel}',
                      detail: 'Grows with recorded progress',
                      color: UrjaTheme.leaf,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Today’s missions'),
            const SizedBox(height: 10),
            if (_isLoading && _quests == null)
              const _LoadingCard(label: 'Loading your daily missions…')
            else if (_questsError != null && _quests == null)
              _RetryCard(message: _questsError!, onRetry: _load)
            else if (_quests?.quests.isEmpty ?? true)
              const _EmptyCard(
                icon: Icons.check_circle_outline_rounded,
                title: 'No missions available',
                message:
                    'New missions will appear here when the server provides them.',
              )
            else ...[
              for (final quest in _quests!.quests)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _QuestCard(
                    quest: quest,
                    isClaiming: _claimingQuestId == quest.id,
                    onClaim: () => _claimQuest(quest),
                  ),
                ),
              const Text(
                'Rewards are based on your confirmation. They are not verified utility savings or measured CO₂e.',
                style: TextStyle(
                  color: UrjaTheme.muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 22),
            _sectionTitle('Your household data'),
            const SizedBox(height: 10),
            if (_analyticsError != null && _analytics == null)
              _RetryCard(message: _analyticsError!, onRetry: _load)
            else
              _HouseholdDataCard(
                analytics: _analytics,
                isLoading: _isLoading,
                onTap: widget.onOpenRecords,
              ),
            const SizedBox(height: 22),
            _sectionTitle('Explore Urja'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.65,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ExploreCard(
                  icon: Icons.menu_book_rounded,
                  title: 'Learn & play',
                  subtitle: 'Lessons and sorting',
                  onTap: widget.onOpenLearning,
                ),
                _ExploreCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Household records',
                  subtitle: 'Bills, vehicles, trips',
                  onTap: widget.onOpenRecords,
                ),
                _ExploreCard(
                  icon: Icons.insights_rounded,
                  title: 'Energy impact',
                  subtitle: 'Your saved data',
                  onTap: widget.onOpenImpact,
                ),
                _ExploreCard(
                  icon: Icons.electric_bolt_rounded,
                  title: 'Device use',
                  subtitle: 'Log appliance hours',
                  onTap: widget.onOpenDeviceLog,
                ),
                _ExploreCard(
                  icon: Icons.devices_other_rounded,
                  title: 'My devices',
                  subtitle: 'Register and track runtime',
                  onTap: widget.onOpenRegisteredDevices,
                ),
                _ExploreCard(
                  icon: Icons.groups_2_rounded,
                  title: 'Community',
                  subtitle: 'Weekly league',
                  onTap: widget.onOpenCommunity,
                ),
                _ExploreCard(
                  icon: Icons.flutter_dash_rounded,
                  title: 'Sanctuary',
                  subtitle: 'Sparrow and garden',
                  onTap: widget.onOpenPlay,
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardActions extends StatelessWidget {
  const _DashboardActions({
    required this.onLearn,
    required this.onAddReading,
    required this.onLeaderboard,
  });

  final VoidCallback onLearn;
  final VoidCallback onAddReading;
  final VoidCallback onLeaderboard;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _DashboardAction(
          icon: Icons.route_rounded,
          label: 'Chapters',
          onTap: onLearn,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _DashboardAction(
          icon: Icons.add_chart_rounded,
          label: 'Add reading',
          onTap: onAddReading,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _DashboardAction(
          icon: Icons.emoji_events_rounded,
          label: 'Leaderboard',
          onTap: onLeaderboard,
        ),
      ),
    ],
  );
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
        child: Column(
          children: [
            Icon(icon, color: UrjaTheme.forest, size: 21),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: UrjaTheme.ink,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _roundIconButton(
  BuildContext context, {
  required IconData icon,
  required String tooltip,
  required VoidCallback onPressed,
}) => IconButton.filledTonal(
  onPressed: onPressed,
  tooltip: tooltip,
  style: IconButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: UrjaTheme.ink,
    side: const BorderSide(color: UrjaTheme.line),
    fixedSize: const Size(42, 42),
  ),
  icon: Icon(icon, size: 21),
);

Widget _sectionTitle(String title, {String? action, VoidCallback? onAction}) =>
    Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: UrjaTheme.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action)),
      ],
    );

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.firstName,
    required this.isGuest,
    required this.streakDays,
  });

  final String firstName;
  final bool isGuest;
  final int? streakDays;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [UrjaTheme.forest, Color(0xFF28744C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24174B35),
          blurRadius: 18,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Good ${_timeGreeting()}, $firstName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Text('🌱', style: TextStyle(fontSize: 28)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          isGuest
              ? 'Guest preview · your progress is not saved to an account'
              : 'Small choices. A greener Gujarat.',
          style: const TextStyle(color: Color(0xFFDCEFE1), fontSize: 12),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: UrjaTheme.amber,
              size: 20,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                streakDays == null
                    ? 'Daily streak loads with your missions'
                    : '$streakDays day${streakDays == 1 ? '' : 's'} active',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'TODAY',
              style: TextStyle(
                color: Color(0xFFC9E4D0),
                fontSize: 10,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: UrjaTheme.muted, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: UrjaTheme.ink,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: UrjaTheme.muted, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.isClaiming,
    required this.onClaim,
  });

  final DailyQuestItem quest;
  final bool isClaiming;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final isClaimed = quest.isClaimed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: UrjaTheme.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                quest.icon.isEmpty ? '🌿' : quest.icon,
                style: const TextStyle(fontSize: 21),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      color: UrjaTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    quest.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: UrjaTheme.muted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '+${quest.coinReward} Green Coins',
                    style: const TextStyle(
                      color: UrjaTheme.forest,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isClaimed)
              const Icon(Icons.check_circle_rounded, color: UrjaTheme.leaf)
            else
              IconButton.filledTonal(
                onPressed: isClaiming ? null : onClaim,
                tooltip: 'Confirm completed mission',
                icon: isClaiming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _HouseholdDataCard extends StatelessWidget {
  const _HouseholdDataCard({
    required this.analytics,
    required this.isLoading,
    required this.onTap,
  });

  final AnalyticsDashboardData? analytics;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final readings =
        analytics?.utilityReadings ?? const <Map<String, dynamic>>[];
    final liveMetersAvailable =
        analytics?.dataAvailability['liveMeterTelemetry'] == true;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF3B74A5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Utility readings',
                      style: TextStyle(
                        color: UrjaTheme.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading && analytics == null
                          ? 'Loading your saved readings…'
                          : readings.isEmpty
                          ? liveMetersAvailable
                                ? 'No readings saved yet'
                                : 'No readings yet · live meter data is unavailable'
                          : '${readings.length} citizen-entered reading${readings.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: UrjaTheme.muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: UrjaTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        child: Column(
          children: [
            Icon(icon, color: UrjaTheme.leaf, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: UrjaTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: UrjaTheme.muted, fontSize: 9),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: UrjaTheme.muted)),
        ],
      ),
    ),
  );
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load this section',
            style: TextStyle(fontWeight: FontWeight.w800, color: UrjaTheme.ink),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: UrjaTheme.muted, fontSize: 11),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: UrjaTheme.leaf, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: UrjaTheme.muted,
                    fontSize: 11,
                    height: 1.35,
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
