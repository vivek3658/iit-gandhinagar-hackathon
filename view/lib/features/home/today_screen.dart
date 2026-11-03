import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/auth_session.dart';
import '../../services/citizen_api.dart';
import '../../services/notification_service.dart';
import '../game/sparrow_stage.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    required this.isActive,
    required this.onOpenDevices,
    required this.onOpenGarden,
    required this.onOpenCommunity,
    required this.onOpenLearning,
    super.key,
  });

  final bool isActive;
  final VoidCallback onOpenDevices;
  final VoidCallback onOpenGarden;
  final VoidCallback onOpenCommunity;
  final VoidCallback onOpenLearning;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<Map<String, dynamic>> _quests = [];
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _mascot;
  int? _streakDays;
  String? _questError;
  String? _analyticsError;
  String? _mascotError;
  bool _loading = true;
  bool _chargerNudgeEnabled = false;
  String? _notificationError;
  String? _claimingId;
  String? _petError;
  int _earnedCoinsThisSession = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadChargerNudgePreference();
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final api = CitizenApi.instance;
    final results = await Future.wait<Object>([
      _capture(api.getDailyQuests()),
      _capture(api.getAnalytics()),
      _capture(api.getMascot()),
    ]);
    if (!mounted) return;
    setState(() {
      _questError = _setResult(results[0], (value) {
        final items = value['quests'];
        if (items is! List) {
          throw const FormatException('Daily missions were not returned.');
        }
        _streakDays = _number(value['streakDays']);
        _quests = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
      _analyticsError = _setResult(results[1], (value) => _analytics = value);
      _mascotError = _setResult(results[2], (value) => _mascot = value);
      _loading = false;
    });
  }

  Future<Object> _capture(Future<Map<String, dynamic>> future) async {
    try {
      return await future;
    } catch (error) {
      return error;
    }
  }

  String? _setResult(
    Object result,
    void Function(Map<String, dynamic>) accept,
  ) {
    if (result is! Map<String, dynamic>) return result.toString();
    try {
      accept(result);
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> _claim(Map<String, dynamic> quest) async {
    final id = quest['id'];
    if (id is! String || id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Already completed this?'),
        content: const Text(
          'Your confirmation earns Green Coins. It is self-reported, not independently verified, and does not create a measured CO₂ saving.',
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
    setState(() => _claimingId = id);
    try {
      final result = await CitizenApi.instance.claimQuest(id);
      final coinsAwarded = result['coinsAwarded'];
      if (coinsAwarded is num) {
        setState(() => _earnedCoinsThisSession += coinsAwarded.toInt());
      }
      await HapticFeedback.mediumImpact();
      await _load();
      if (mounted) _toast('Mission claimed. Nice work!');
    } catch (error) {
      if (mounted) _toast(error.toString());
    } finally {
      if (mounted) setState(() => _claimingId = null);
    }
  }

  Future<void> _pet() async {
    setState(() => _petError = null);
    try {
      await CitizenApi.instance.interactWithMascot();
      if (mounted) {
        setState(() => _mascot = null);
        final result = await _capture(CitizenApi.instance.getMascot());
        if (mounted && result is Map<String, dynamic>) {
          setState(() => _mascot = result);
        }
      }
    } catch (error) {
      if (mounted) setState(() => _petError = error.toString());
    }
  }

  Future<void> _loadChargerNudgePreference() async {
    try {
      final enabled = await NotificationService.instance
          .getChargerNudgeEnabled();
      if (mounted) setState(() => _chargerNudgeEnabled = enabled);
    } catch (error) {
      if (mounted) setState(() => _notificationError = error.toString());
    }
  }

  Future<void> _toggleChargerNudge() async {
    try {
      if (!_chargerNudgeEnabled) {
        final granted = await NotificationService.instance.requestPermission();
        if (!granted) {
          if (mounted) {
            _toast('Allow notifications to turn on charger reminders.');
          }
          return;
        }
      }
      final enabled = !_chargerNudgeEnabled;
      await NotificationService.instance.setChargerNudgeEnabled(enabled);
      if (!mounted) return;
      setState(() {
        _chargerNudgeEnabled = enabled;
        _notificationError = null;
      });
      _toast(
        enabled
            ? 'Charger unplug reminders are on.'
            : 'Charger unplug reminders are off.',
      );
    } catch (error) {
      if (mounted) {
        setState(() => _notificationError = error.toString());
        _toast(error.toString());
      }
    }
  }

  Future<void> _testChargerNudge() async {
    try {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (mounted) _toast('Allow notifications to test the charger nudge.');
        return;
      }
      final shown = await NotificationService.instance.showChargerNudgeTest();
      if (!mounted) return;
      if (!shown) throw StateError('The test notification could not be shown.');
      setState(() => _notificationError = null);
      _toast('Test nudge sent to your notification shade.');
    } catch (error) {
      if (mounted) {
        setState(() => _notificationError = error.toString());
        _toast(error.toString());
      }
    }
  }

  void _openMissions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> refreshSheet() async {
            await _load();
            if (context.mounted) setSheetState(() {});
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .82,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                const Text(
                  "Today's missions",
                  style: TextStyle(
                    color: UrjaColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _ChapterHeader(
                  completed: _quests
                      .where((quest) => quest['isClaimed'] == true)
                      .length,
                  total: _quests.length,
                  onLearn: () {
                    Navigator.of(sheetContext).pop();
                    widget.onOpenLearning();
                  },
                ),
                const SizedBox(height: 12),
                if (_loading && _quests.isEmpty)
                  const _LoadingCard(label: 'Finding your missions…')
                else if (_questError != null && _quests.isEmpty)
                  _RetryCard(message: _questError!, onRetry: refreshSheet)
                else if (_quests.isEmpty)
                  const _EmptyCard(
                    icon: Icons.eco_outlined,
                    title: 'No missions available',
                    message: 'New missions will appear here when available.',
                  )
                else
                  for (var index = 0; index < _quests.length; index++)
                    _ChapterStop(
                      index: index,
                      quest: _quests[index],
                      busy: _claimingId == _quests[index]['id'],
                      onClaim: () async {
                        await _claim(_quests[index]);
                        if (context.mounted) setSheetState(() {});
                      },
                      isLast: index == _quests.length - 1,
                    ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Rewards celebrate self-reported participation; they are not measured CO2e savings.',
                    style: TextStyle(
                      color: UrjaColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openProgress() {
    final readings = _analytics?['utilityReadings'];
    final entries = readings is List
        ? readings.whereType<Map>().toList()
        : const <Map>[];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            const Text(
              'Your green progress',
              style: TextStyle(
                color: UrjaColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _ProgressSummary(
              completed: _quests
                  .where((quest) => quest['isClaimed'] == true)
                  .length,
              total: _quests.length,
              readings: readings is List ? readings.length : null,
              co2e: _analyticsError != null ? 'Unavailable' : 'Not measured',
            ),
            if (_analyticsError != null) ...[
              const SizedBox(height: 10),
              _InlineError(
                message: 'Progress data unavailable: $_analyticsError',
              ),
              TextButton.icon(
                onPressed: () async {
                  await _load();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh data'),
              ),
            ],
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Home readings'),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              _EmptyCard(
                icon: Icons.bolt_rounded,
                title: 'No readings saved yet',
                message: _analyticsError == null
                    ? 'Add a household reading to start tracking your usage.'
                    : 'Reconnect to load saved household readings.',
              )
            else
              for (final reading in entries)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.bolt_rounded,
                      color: UrjaColors.forest,
                    ),
                    title: Text(reading['utility'] as String? ?? 'Utility'),
                    subtitle: Text(
                      '${reading['periodStart'] ?? '—'} to ${reading['periodEnd'] ?? '—'} · User-entered',
                    ),
                    trailing: Text(
                      '${reading['value'] ?? '—'} ${reading['unit'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            _GameShortcut(
              icon: Icons.bolt_rounded,
              title: 'Add home data',
              subtitle: 'Open energy tracking',
              color: const Color(0xFFFFF0BE),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenDevices();
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'This backend does not currently calculate CO2e savings. Household readings are user-entered and are shown as usage data, not verified impact.',
              style: TextStyle(
                color: UrjaColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.instance.user ?? const <String, dynamic>{};
    final points = user['points'];
    final coins =
        (points is num ? points.toInt() : 0) + _earnedCoinsThisSession;
    final level = _number(_mascot?['level']);
    final streak = _streakDays;
    final currentExp = _number(_mascot?['currentExp']) ?? 0;
    final nextLevelExp = _number(_mascot?['nextLevelExp']) ?? 100;
    final levelFloor = level == null ? 0 : (level - 1) * (level - 1) * 100;
    final levelSpan = nextLevelExp - levelFloor;
    final levelExp = (currentExp - levelFloor).clamp(
      0,
      levelSpan > 0 ? levelSpan : 100,
    );
    final levelProgress = levelSpan <= 0
        ? 0.0
        : ((currentExp - levelFloor) / levelSpan).clamp(0.0, 1.0);
    final readings = _analytics?['utilityReadings'];
    final energyAvailable =
        readings is List &&
        readings.any(
          (reading) => reading is Map && reading['utility'] == 'ELECTRICITY',
        );
    final completedMissions = _quests
        .where((quest) => quest['isClaimed'] == true)
        .length;
    return Scaffold(
      backgroundColor: UrjaColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _CompanionHome(
              isActive: widget.isActive,
              level: level,
              progress: levelProgress,
              currentExp: levelExp,
              nextLevelExp: levelSpan > 0 ? levelSpan : 100,
              completedMissions: completedMissions,
              totalMissions: _quests.length,
              expression: _mascot?['expression'] as String? ?? 'happy',
              onPet: _pet,
              onGarden: widget.onOpenGarden,
              onMissions: _openMissions,
              onProgress: _openProgress,
              onLearn: widget.onOpenLearning,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.fromLTRB(9, 8, 7, 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .93),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x254A3C1B),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: UrjaColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: UrjaColors.forest,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'URJA',
                          style: TextStyle(
                            color: UrjaColors.forest,
                            fontSize: 9,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TopHudPill(
                    icon: Icons.local_fire_department_rounded,
                    label: streak == null ? '0' : '$streak',
                    color: const Color(0xFFFF8B38),
                  ),
                  const SizedBox(width: 5),
                  _TopHudPill(
                    icon: Icons.bolt_rounded,
                    label: _analyticsError != null
                        ? 'SYNC'
                        : energyAvailable
                        ? 'LOGGED'
                        : 'ADD',
                    color: _analyticsError != null
                        ? UrjaColors.muted
                        : const Color(0xFF55B94E),
                    onTap: widget.onOpenDevices,
                  ),
                  const SizedBox(width: 5),
                  _CoinPill(coins: coins),
                  PopupMenuButton<String>(
                    tooltip: 'Account',
                    onSelected: (value) async {
                      if (value == 'charger_nudge_toggle') {
                        await _toggleChargerNudge();
                        return;
                      }
                      if (value == 'charger_nudge_test') {
                        await _testChargerNudge();
                        return;
                      }
                      if (value == 'refresh') {
                        await _load();
                        return;
                      }
                      if (value != 'sign-out') return;
                      try {
                        await AuthSession.instance.signOut();
                      } catch (error) {
                        if (mounted) _toast(error.toString());
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'charger_nudge_toggle',
                        child: Text(
                          _chargerNudgeEnabled
                              ? 'Charger reminder: on'
                              : 'Charger reminder: off',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'charger_nudge_test',
                        child: Text('Test charger nudge'),
                      ),
                      PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                      PopupMenuItem(value: 'sign-out', child: Text('Sign out')),
                    ],
                    icon: _notificationError == null
                        ? const Icon(Icons.more_vert_rounded, size: 20)
                        : const Icon(
                            Icons.notifications_off_outlined,
                            size: 20,
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_mascotError != null || _petError != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 145,
              child: Material(
                color: Colors.white.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _petError ?? 'Companion data unavailable: $_mascotError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFAD4237),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

int? _number(Object? value) => value is num ? value.toInt() : null;

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.completed,
    required this.total,
    required this.readings,
    required this.co2e,
  });

  final int completed;
  final int total;
  final int? readings;
  final String co2e;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: const Color(0xFFDCEACD), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0xFFDAE8D0),
          offset: Offset(0, 4),
          blurRadius: 0,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.insights_rounded, color: UrjaColors.forest, size: 19),
            SizedBox(width: 7),
            Text(
              'YOUR GREEN PROGRESS',
              style: TextStyle(
                color: UrjaColors.forest,
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProgressMetric(
                value: total == 0 ? '—' : '$completed/$total',
                label: 'missions',
                color: const Color(0xFF4F9B47),
              ),
            ),
            Expanded(
              child: _ProgressMetric(
                value: readings?.toString() ?? '—',
                label: 'home readings',
                color: const Color(0xFF3989A4),
              ),
            ),
            Expanded(
              child: _ProgressMetric(
                value: co2e,
                label: 'CO2e today',
                color: const Color(0xFFB36C32),
              ),
            ),
          ],
        ),
        if (co2e == 'Not measured') ...[
          const SizedBox(height: 8),
          Text(
            'Impact estimates are not available yet. Your actions and readings are still saved.',
            style: TextStyle(
              color: UrjaColors.muted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: value.length > 8 ? 12 : 17,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: UrjaColors.muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _TopHudPill extends StatelessWidget {
  const _TopHudPill({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD2A9), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C4F3214),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(5, 4, 11, 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF2C2),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFFFD35B), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0xFFD99A29),
          offset: Offset(0, 3),
          blurRadius: 0,
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE987), Color(0xFFF2A928)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFE59613), width: 1.5),
          ),
          child: const Icon(Icons.toll_rounded, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 5),
        Text(
          coins.toString(),
          style: const TextStyle(
            color: Color(0xFF754600),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _CompanionHome extends StatelessWidget {
  const _CompanionHome({
    required this.isActive,
    required this.level,
    required this.progress,
    required this.currentExp,
    required this.nextLevelExp,
    required this.completedMissions,
    required this.totalMissions,
    required this.expression,
    required this.onPet,
    required this.onGarden,
    required this.onMissions,
    required this.onProgress,
    required this.onLearn,
  });

  final bool isActive;
  final int? level;
  final double progress;
  final int currentExp;
  final int nextLevelExp;
  final int completedMissions;
  final int totalMissions;
  final String expression;
  final Future<void> Function() onPet;
  final VoidCallback onGarden;
  final VoidCallback onMissions;
  final VoidCallback onProgress;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 700;
      final panelHeight = compact ? 112.0 : 122.0;
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF83DCEB), Color(0xFFC8F1D9), Color(0xFF9ADD75)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _IslandBackdrop()),
            ),
            Positioned(
              left: -12,
              right: -12,
              top: 68,
              bottom: panelHeight + 18,
              child: SparrowStage(
                onPet: onPet,
                expression: expression,
                isActive: isActive,
                backgroundColor: Colors.transparent,
                borderRadius: 0,
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 68,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8).withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .9),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26356243),
                        offset: Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wb_sunny_rounded,
                        color: Color(0xFFEA9B27),
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'YOUR SPARROW SANCTUARY',
                        style: TextStyle(
                          color: Color(0xFF285A3D),
                          fontSize: 9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: panelHeight + 18,
              child: _IslandShortcut(
                icon: Icons.flag_rounded,
                label: 'MISSIONS',
                badge: totalMissions > completedMissions
                    ? '${totalMissions - completedMissions}'
                    : null,
                onTap: onMissions,
              ),
            ),
            Positioned(
              right: 12,
              bottom: panelHeight + 18,
              child: _IslandShortcut(
                icon: Icons.park_rounded,
                label: 'GARDEN',
                onTap: onGarden,
                color: const Color(0xFF78D85D),
              ),
            ),
            Positioned(
              left: 13,
              right: 13,
              bottom: 9,
              height: panelHeight,
              child: _JourneyCard(
                level: level,
                progress: progress,
                currentExp: currentExp,
                nextLevelExp: nextLevelExp,
                completedMissions: completedMissions,
                totalMissions: totalMissions,
                onLearn: onLearn,
                onProgress: onProgress,
                compact: compact,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _IslandShortcut extends StatelessWidget {
  const _IslandShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.color = const Color(0xFFFFC64B),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            elevation: 5,
            shadowColor: const Color(0x663B502D),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white.withValues(alpha: .35), color],
                  ),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44634B1F),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(icon, color: const Color(0xFF285A3D), size: 25),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              right: -3,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE95F46),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badge!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 7),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF285A3D),
          fontSize: 9,
          letterSpacing: .5,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.white, blurRadius: 5)],
        ),
      ),
    ],
  );
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.level,
    required this.progress,
    required this.currentExp,
    required this.nextLevelExp,
    required this.completedMissions,
    required this.totalMissions,
    required this.onLearn,
    required this.onProgress,
    required this.compact,
  });

  final int? level;
  final double progress;
  final int currentExp;
  final int nextLevelExp;
  final int completedMissions;
  final int totalMissions;
  final VoidCallback onLearn;
  final VoidCallback onProgress;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(14, compact ? 9 : 11, 10, compact ? 9 : 11),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF22583D), Color(0xFF143D32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xFFD8F4A8), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0xFF397E4E),
          offset: Offset(0, 5),
          blurRadius: 0,
        ),
        BoxShadow(
          color: Color(0x30374A2B),
          offset: Offset(0, 8),
          blurRadius: 16,
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.explore_rounded,
              color: Color(0xFFFFD76D),
              size: 15,
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                "TODAY'S ADVENTURE",
                style: TextStyle(
                  color: Color(0xFFBDEBB7),
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: .16)),
              ),
              child: Text(
                totalMissions == 0
                    ? 'MISSIONS'
                    : '$completedMissions / $totalMissions MISSIONS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  letterSpacing: .4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Material(
              color: const Color(0xFFFFD76D),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onProgress,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 39,
                  height: 39,
                  child: Center(
                    child: Text(
                      level?.toString() ?? '·',
                      style: const TextStyle(
                        color: Color(0xFF805400),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: GestureDetector(
                onTap: onProgress,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      level == null
                          ? 'Growing together'
                          : 'Sparrow · Level $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: .2),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFB7EF62),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$currentExp / $nextLevelExp eco XP',
                      style: const TextStyle(
                        color: Color(0xFFCBE0C9),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 9),
            Material(
              color: const Color(0xFFFFC64B),
              borderRadius: BorderRadius.circular(17),
              elevation: 2,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onLearn();
                },
                borderRadius: BorderRadius.circular(17),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 11 : 14,
                    vertical: compact ? 12 : 14,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF704A10),
                        size: 17,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'LEARN',
                        style: TextStyle(
                          color: Color(0xFF704A10),
                          fontSize: 9,
                          letterSpacing: .7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _IslandBackdrop extends CustomPainter {
  const _IslandBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sunCenter = Offset(w * .82, h * .2);
    canvas.drawCircle(
      sunCenter,
      w * .18,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF8C7).withValues(alpha: .52),
            const Color(0xFFFFF8C7).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: w * .18)),
    );
    canvas.drawCircle(
      sunCenter,
      w * .055,
      Paint()..color = const Color(0xFFFFF1A8).withValues(alpha: .72),
    );

    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: .48);
    for (final offset in [Offset(w * .18, h * .26), Offset(w * .79, h * .35)]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: offset.translate(0, 6),
          width: w * .2,
          height: h * .025,
        ),
        cloudPaint,
      );
      canvas.drawCircle(
        Offset(offset.dx - w * .035, offset.dy - 3),
        w * .025,
        cloudPaint,
      );
      canvas.drawCircle(
        Offset(offset.dx + w * .012, offset.dy - 6),
        w * .032,
        cloudPaint,
      );
    }

    final farHill = Path()
      ..moveTo(0, h * .64)
      ..quadraticBezierTo(w * .19, h * .52, w * .4, h * .65)
      ..quadraticBezierTo(w * .68, h * .46, w, h * .62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      farHill,
      Paint()..color = const Color(0xFF9DDE87).withValues(alpha: .62),
    );

    final islandTop = Path()
      ..moveTo(-w * .08, h * .73)
      ..quadraticBezierTo(w * .22, h * .59, w * .5, h * .7)
      ..quadraticBezierTo(w * .77, h * .58, w * 1.08, h * .73)
      ..lineTo(w * 1.08, h)
      ..lineTo(-w * .08, h)
      ..close();
    canvas.drawPath(islandTop, Paint()..color = const Color(0xFF80D969));

    final islandEdge = Path()
      ..moveTo(-w * .08, h * .81)
      ..quadraticBezierTo(w * .22, h * .72, w * .5, h * .79)
      ..quadraticBezierTo(w * .78, h * .7, w * 1.08, h * .81)
      ..quadraticBezierTo(w * .86, h * .91, w * .72, h * .97)
      ..quadraticBezierTo(w * .5, h * .91, w * .29, h * .98)
      ..quadraticBezierTo(w * .12, h * .9, -w * .08, h * .81)
      ..close();
    canvas.drawPath(islandEdge, Paint()..color = const Color(0xFF6D9F55));
    canvas.drawPath(
      islandEdge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFB2E586).withValues(alpha: .9),
    );

    final grassPaint = Paint()
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF3F9C55).withValues(alpha: .74);
    for (final point in [
      Offset(w * .09, h * .77),
      Offset(w * .17, h * .73),
      Offset(w * .87, h * .74),
      Offset(w * .94, h * .78),
    ]) {
      canvas.drawLine(point, point.translate(-2, -9), grassPaint);
      canvas.drawLine(point, point.translate(3, -7), grassPaint);
    }

    final flowerPaint = Paint()..color = const Color(0xFFFFE789);
    for (final point in [
      Offset(w * .1, h * .78),
      Offset(w * .86, h * .78),
      Offset(w * .92, h * .83),
      Offset(w * .2, h * .84),
    ]) {
      canvas.drawCircle(point, 3, flowerPaint);
      canvas.drawCircle(
        Offset(point.dx - 3, point.dy + 2),
        2.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(point.dx + 3, point.dy + 2),
        2.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IslandBackdrop oldDelegate) => false;
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.completed,
    required this.total,
    required this.onLearn,
  });

  final int completed;
  final int total;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 14, 12, 13),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF285D3A), Color(0xFF17482F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: const Color(0xFF9AD67C), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0xFFB5D99A),
          offset: Offset(0, 5),
          blurRadius: 0,
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(0xFFFFDD75),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFCE9C34),
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(Icons.checklist_rounded, color: Color(0xFF825716)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TODAY'S MISSIONS",
                style: TextStyle(
                  color: Color(0xFFFFDB7A),
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Small actions, real habits',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : completed / total,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: .2),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFB4EF69)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            Text(
              '$completed/$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'done',
              style: TextStyle(color: Color(0xFFCBE0C9), fontSize: 9),
            ),
            const SizedBox(height: 3),
            InkWell(
              onTap: onLearn,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 19,
                  color: Color(0xFFFFDB7A),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ChapterStop extends StatelessWidget {
  const _ChapterStop({
    required this.index,
    required this.quest,
    required this.busy,
    required this.onClaim,
    required this.isLast,
  });

  final int index;
  final Map<String, dynamic> quest;
  final bool busy;
  final VoidCallback onClaim;
  final bool isLast;

  static const _colors = [
    Color(0xFFFFE6A3),
    Color(0xFFD8F1BB),
    Color(0xFFFFD7C8),
    Color(0xFFDCD9FF),
    Color(0xFFBEEBF0),
  ];
  static const _edges = [
    Color(0xFFE0B54E),
    Color(0xFF83B454),
    Color(0xFFD88E6E),
    Color(0xFF9588D5),
    Color(0xFF68AEB7),
  ];

  @override
  Widget build(BuildContext context) {
    final claimed = quest['isClaimed'] == true;
    final color = _colors[index % _colors.length];
    final edge = _edges[index % _edges.length];
    final card = _QuestCard(
      quest: quest,
      index: index,
      claimed: claimed,
      busy: busy,
      color: color,
      edge: edge,
      onClaim: onClaim,
    );
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: index.isEven
                  ? Align(alignment: Alignment.centerLeft, child: card)
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: 48,
              child: Center(
                child: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: claimed ? const Color(0xFF77C94D) : color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: claimed ? const Color(0xFF4D9B3B) : edge,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: claimed ? const Color(0xFF4D9B3B) : edge,
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    claimed ? Icons.check_rounded : Icons.eco_rounded,
                    color: claimed ? Colors.white : const Color(0xFF74531D),
                    size: 22,
                  ),
                ),
              ),
            ),
            Expanded(
              child: index.isOdd
                  ? Align(alignment: Alignment.centerRight, child: card)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        if (!isLast)
          SizedBox(
            height: 31,
            child: Center(
              child: Container(
                width: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF9ACD69),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF70A744),
                      offset: Offset(1, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.index,
    required this.claimed,
    required this.busy,
    required this.color,
    required this.edge,
    required this.onClaim,
  });

  final Map<String, dynamic> quest;
  final int index;
  final bool claimed;
  final bool busy;
  final Color color;
  final Color edge;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final icon = quest['icon'] as String? ?? '🌿';
    final title = quest['title'] as String? ?? 'Green mission';
    final description = quest['description'] as String? ?? '';
    final coins = quest['coinReward'] is num
        ? (quest['coinReward'] as num).toInt()
        : 0;
    return Container(
      constraints: const BoxConstraints(minHeight: 148),
      decoration: BoxDecoration(
        color: edge,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(color: edge, offset: const Offset(0, 5), blurRadius: 0),
          const BoxShadow(
            color: Color(0x164A3A22),
            offset: Offset(0, 7),
            blurRadius: 10,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: Colors.white.withValues(alpha: .85),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: edge.withValues(alpha: .6),
                        offset: const Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 21)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5CF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEFC558)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.toll_rounded,
                        size: 14,
                        color: Color(0xFFE79D20),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '+$coins',
                        style: const TextStyle(
                          color: Color(0xFF805400),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF263B2B),
                fontSize: 13,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF546551),
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: Material(
                color: claimed
                    ? const Color(0xFF6CB85A)
                    : const Color(0xFFFFFCF1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: claimed || busy ? null : onClaim,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: busy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                claimed
                                    ? Icons.check_circle_rounded
                                    : Icons.stars_rounded,
                                size: 15,
                                color: claimed
                                    ? Colors.white
                                    : const Color(0xFF568241),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                claimed ? 'REWARD COLLECTED' : 'COLLECT REWARD',
                                style: TextStyle(
                                  color: claimed
                                      ? Colors.white
                                      : const Color(0xFF426E33),
                                  fontSize: 9,
                                  letterSpacing: .4,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameShortcut extends StatelessWidget {
  const _GameShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        height: 94,
        padding: const EdgeInsets.fromLTRB(10, 10, 7, 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20613D16),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF3D773D), size: 23),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: UrjaColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: UrjaColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: UrjaColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
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
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label),
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
          Text(message, style: const TextStyle(color: UrjaColors.muted)),
          const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, size: 30, color: UrjaColors.leaf),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  message,
                  style: const TextStyle(color: UrjaColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: const TextStyle(color: Color(0xFFAD4237), fontSize: 12),
  );
}
