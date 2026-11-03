import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';
import '../../services/quests_service.dart';

class DailyQuestsSheet extends StatefulWidget {
  const DailyQuestsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DailyQuestsSheet(),
    );
  }

  @override
  State<DailyQuestsSheet> createState() => _DailyQuestsSheetState();
}

class _DailyQuestsSheetState extends State<DailyQuestsSheet> {
  DailyQuestsData? _questsData;
  String? _loadError;
  bool _isLoading = true;
  final Set<String> _claimingQuestIds = {};

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    try {
      final data = await QuestsClientService.instance.getDailyQuests();
      if (!mounted) return;
      setState(() {
        _questsData = data;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _claimQuest(DailyQuestItem quest) async {
    if (_claimingQuestIds.contains(quest.id) || quest.isClaimed) return;
    HapticFeedback.heavyImpact();

    setState(() {
      _claimingQuestIds.add(quest.id);
    });

    try {
      final res = await QuestsClientService.instance.claimQuest(quest.id);
      if (res['success'] != true) {
        throw StateError('The server did not confirm the task claim.');
      }
      final coins = (res['coinsAwarded'] as num?)?.toInt() ?? quest.coinReward;
      final estimatedCo2eKg = (res['estimatedCo2eKg'] as num?)?.toDouble() ?? 0;
      GameStateService.instance.recordEcoAction(
        actionName: quest.title,
        co2Saved: quest.co2SavedKg,
        coinsAwarded: coins,
      );
      if (!mounted) return;
      setState(() => _claimingQuestIds.remove(quest.id));
      await _loadQuests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1B6B44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  estimatedCo2eKg > 0
                      ? 'Claimed ${quest.title}! +$coins coins and ${estimatedCo2eKg.toStringAsFixed(2)} kg estimated CO₂e added to this week’s league.'
                      : 'Claimed ${quest.title}! +$coins Urja Mudra coins added!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _claimingQuestIds.remove(quest.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not claim ${quest.title}: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0D2116),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF143522),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x334ADE80)),
                ),
                child: const Text('🎯', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Mission LiFE Quests',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Complete daily habits to earn Urja Mudra & XP',
                      style: TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
                  )
                : _questsData == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _loadError ?? 'Daily tasks are unavailable.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _loadQuests();
                          },
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      // Streak & Rewards summary card
                      _buildSummaryCard(),
                      const SizedBox(height: 18),

                      const Text(
                        'TODAY\'S ROTATING TASKS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Task list
                      for (final quest in _questsData?.quests ?? []) ...[
                        _buildQuestCard(quest),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final streak = _questsData?.streakDays ?? 0;
    final totalCoins = _questsData?.totalCoinsEarnableToday ?? 0;
    final totalCo2 = _questsData?.totalCo2AvoidableToday ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF0F381E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4ADE80), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statColumn('🔥 Streak', '$streak days', const Color(0xFFF97316)),
          Container(width: 1, height: 32, color: Colors.white24),
          _statColumn(
            '🪙 Earnable',
            '$totalCoins coins',
            const Color(0xFFFDE68A),
          ),
          Container(width: 1, height: 32, color: Colors.white24),
          _statColumn('🌱 Cut CO₂', '$totalCo2 kg', const Color(0xFF86EFAC)),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestCard(DailyQuestItem quest) {
    final isClaimed = quest.isClaimed;
    final isClaiming = _claimingQuestIds.contains(quest.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isClaimed ? const Color(0xFF10281C) : const Color(0xFF143522),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClaimed ? Colors.white12 : const Color(0x334ADE80),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E4C33),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x334ADE80)),
            ),
            child: Center(
              child: Text(quest.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        quest.title,
                        style: TextStyle(
                          color: isClaimed ? Colors.white60 : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          decoration: isClaimed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x334ADE80),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        quest.category,
                        style: const TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  quest.description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🪙 +${quest.coinReward} Urja Mudra • ⭐ +${quest.xpReward} XP',
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          ElevatedButton(
            onPressed: isClaimed || isClaiming
                ? null
                : () => _claimQuest(quest),
            style: ElevatedButton.styleFrom(
              backgroundColor: isClaimed
                  ? Colors.white12
                  : const Color(0xFF22C55E),
              foregroundColor: isClaimed ? Colors.white38 : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isClaimed
                  ? 'Done ✓'
                  : isClaiming
                  ? 'Claiming…'
                  : 'Claim',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
