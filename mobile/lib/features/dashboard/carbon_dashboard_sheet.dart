import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';

class CarbonDashboardSheet extends StatelessWidget {
  final VoidCallback? onActionCompleted;

  const CarbonDashboardSheet({
    super.key,
    this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final state = GameStateService.instance;
    final co2 = state.co2eSavedKg;
    final kwh = (co2 * 1.22).toStringAsFixed(1);
    final inr = (co2 * 7.5).toStringAsFixed(0);

    final actions = [
      {
        'title': 'Unplug Wall Charger',
        'desc': 'Stop phantom standby drain after charging',
        'co2': 0.25,
        'coins': 15,
        'icon': '🔌',
      },
      {
        'title': 'AC Set at 24°C Comfort',
        'desc': 'Saves 24% electricity vs 18°C chill',
        'co2': 2.4,
        'coins': 20,
        'icon': '❄️',
      },
      {
        'title': 'Nighttime Device Sweep',
        'desc': 'Turn off TV standby, geyser & idle gadgets',
        'co2': 1.2,
        'coins': 25,
        'icon': '🌙',
      },
      {
        'title': 'Red Light Engine Off',
        'desc': 'Cut idling at >30s city traffic junctions',
        'co2': 0.4,
        'coins': 15,
        'icon': '🚦',
      },
      {
        'title': 'Municipal Water Pump Off',
        'desc': 'Stop roof tank overflow & motor waste',
        'co2': 0.8,
        'coins': 20,
        'icon': '💧',
      },
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),

          // Title & Coins badge
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carbon & Energy Impact',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gujarat Mission LiFE Citizen Ledger',
                      style: TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '${state.coins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Primary Stats Cards
          Row(
            children: [
              _buildStatCard(
                label: 'CO2e PREVENTED',
                value: '${co2.toStringAsFixed(1)} kg',
                subtext: 'Real air saved',
                accentColor: const Color(0xFF4ADE80),
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                label: 'CLEAN ENERGY',
                value: '$kwh kWh',
                subtext: 'Power conserved',
                accentColor: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                label: 'MONEY SAVED',
                value: '₹$inr',
                subtext: 'Bill reduction',
                accentColor: const Color(0xFFFBBF24),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Mascot Growth / Real Experience Progress Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF163825),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mascot Growth (Lv ${state.mascotLevel})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${co2.toStringAsFixed(1)} / ${state.nextLevelTargetKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Color(0xFF86EFAC),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: state.levelProgress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '💡 Your mascot grows only from real CO2e you prevent in everyday life.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'ACTIVE CARBON-CUTTING MICRO-HABITS',
            style: TextStyle(
              color: Color(0xFF86EFAC),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Actions List
          Expanded(
            child: ListView.separated(
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = actions[i];
                final title = item['title'] as String;
                final desc = item['desc'] as String;
                final itemCo2 = item['co2'] as double;
                final itemCoins = item['coins'] as int;
                final icon = item['icon'] as String;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173022),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              desc,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          final didLevelUp = state.recordEcoAction(
                            actionName: title,
                            co2Saved: itemCo2,
                            coinsAwarded: itemCoins,
                          );
                          onActionCompleted?.call();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                didLevelUp
                                    ? '🎉 LEVEL UP! Mascot is now Level ${state.mascotLevel}! +$itemCoins 🪙 (+${itemCo2}kg CO2e)'
                                    : '✅ $title logged! +$itemCoins 🪙 & +${itemCo2}kg CO2e saved!',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: const Color(0xFF1B6B44),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B6B44),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '+$itemCoins 🪙',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtext,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF163323),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              subtext,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
