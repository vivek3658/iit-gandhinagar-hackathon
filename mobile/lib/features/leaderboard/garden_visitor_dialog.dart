import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';
import '../../services/leaderboard_service.dart';
import '../game/garden_3d_stage.dart';

class GardenVisitorDialog extends StatefulWidget {
  final String citizenId;
  final String citizenName;
  final String district;

  const GardenVisitorDialog({
    super.key,
    required this.citizenId,
    required this.citizenName,
    required this.district,
  });

  static Future<void> show(
    BuildContext context, {
    required String citizenId,
    required String citizenName,
    required String district,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GardenVisitorDialog(
        citizenId: citizenId,
        citizenName: citizenName,
        district: district,
      ),
    );
  }

  @override
  State<GardenVisitorDialog> createState() => _GardenVisitorDialogState();
}

class _GardenVisitorDialogState extends State<GardenVisitorDialog> {
  GardenVisitorData? _visitorData;
  bool _isLoading = true;
  bool _hasCheered = false;
  int _cheersCount = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    try {
      final data = await LeaderboardClientService.instance.visitGarden(
        widget.citizenId,
      );
      if (!mounted) return;
      setState(() {
        _visitorData = data;
        _isLoading = false;
        _loadError = data == null
            ? 'This citizen garden is unavailable.'
            : null;
        _cheersCount = data?.citizen.cheersReceived ?? 0;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _cheer() async {
    if (_hasCheered || _visitorData == null) return;
    HapticFeedback.heavyImpact();
    try {
      final result = await LeaderboardClientService.instance.cheerCitizen(
        widget.citizenId,
      );
      if (result.coinsEarned > 0) {
        GameStateService.instance.addCoins(result.coinsEarned);
      }
      if (!mounted) return;
      setState(() {
        _hasCheered = true;
        _cheersCount = result.totalCheersReceived;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1B6B44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const Text('👏', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.coinsEarned > 0
                      ? 'Cheered ${widget.citizenName}! +${result.coinsEarned} Urja Mudra coins added!'
                      : 'Cheered ${widget.citizenName}! Your support has been counted.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not cheer ${widget.citizenName}: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
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
      decoration: const BoxDecoration(
        color: Color(0xFF0F261A),
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
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF183D2B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x334ADE80)),
                  ),
                  child: const Text('🏝️', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.citizenName}\'s Island',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${widget.district} • Mission LiFE Citizen',
                        style: const TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 12,
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
          ),
          const Divider(color: Colors.white12, height: 24),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
                  )
                : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mascot Snapshot Card
                        _buildMascotCard(),
                        const SizedBox(height: 16),

                        // Garden Island Grid Layout
                        const Text(
                          'FLOATING GARDEN LAYOUT',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildGardenCanvas(),
                        const SizedBox(height: 16),

                        // Stats Highlights
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0A1C13),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasCheered || _visitorData == null
                        ? null
                        : _cheer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasCheered
                          ? Colors.white12
                          : const Color(0xFF22C55E),
                      foregroundColor: _hasCheered
                          ? Colors.white54
                          : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _hasCheered ? 0 : 4,
                    ),
                    icon: Text(
                      _hasCheered ? '✓' : '👏',
                      style: const TextStyle(fontSize: 18),
                    ),
                    label: Text(
                      _hasCheered
                          ? 'Cheered! ($_cheersCount Cheers)'
                          : 'Cheer Island',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotCard() {
    final mascot = _visitorData!.mascot;
    final name = mascot.name;
    final level = mascot.level;
    final vitality = mascot.vitality;
    final mood = mascot.mood;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x334ADE80)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
            ),
            child: const Center(
              child: Text('🕊️', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$name the Sparrow',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lv.$level',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Mood: $mood • Vitality: $vitality%',
                  style: const TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: vitality / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenCanvas() {
    final garden = _visitorData?.garden ?? {};
    final slots = (garden['slots'] as List<dynamic>?) ?? [];
    final islandState = slots.whereType<Map>().map((slot) {
      return <String, dynamic>{
        'x': ((slot['x'] as num?)?.toInt() ?? 1) - 1,
        'z': ((slot['z'] as num?)?.toInt() ?? 1) - 1,
        'id': slot['id'] as String? ?? 'unknown',
        'r': (slot['rotation'] as num?)?.toInt() ?? 0,
      };
    }).toList();

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [Color(0xFF1B4D31), Color(0xFF0A1C13)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x334ADE80)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Garden3DStage(
          initialIslandState: islandState,
          initialMascotLevel: _visitorData?.mascot.level,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final citizen = _visitorData!.citizen;

    return Row(
      children: [
        Expanded(
          child: _statPill(
            '🌱 Estimated CO₂e',
            '${citizen.estimatedCo2eKg.toStringAsFixed(2)} kg',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statPill('🔥 LiFE Streak', '${citizen.streakDays} days'),
        ),
      ],
    );
  }

  Widget _statPill(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
