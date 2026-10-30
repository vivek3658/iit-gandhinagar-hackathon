import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:urja/services/water_conservation_service.dart';

/// Modal bottom sheet providing deep insights into Timed Municipal vs 24/7 Paid water networks,
/// tracking daily water quests, and calculating avoided pumping carbon emissions.
class WaterConservationSheet extends StatefulWidget {
  const WaterConservationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const WaterConservationSheet(),
    );
  }

  @override
  State<WaterConservationSheet> createState() => _WaterConservationSheetState();
}

class _WaterConservationSheetState extends State<WaterConservationSheet> {
  final _service = WaterConservationService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final quests = _service.quests;
    final supplyType = _service.supplyType;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF071E22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
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
                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Color(0xFF38BDF8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Water Conservation & Quests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Save Liters • Stop Pumping CO2e Emissions',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
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

          const SizedBox(height: 16),

          // Savings Scorecard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0369A1).withValues(alpha: 0.6),
                    const Color(0xFF082F49).withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💧 Water Conserved', style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          '${_service.totalLitersSaved} Liters',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌿 Pumping CO2e Cut', style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          '${_service.totalCo2eSavedKg.toStringAsFixed(2)} kg',
                          style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Supply Type Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSupplyTab(
                    type: WaterSupplyType.timedMunicipalMorning,
                    title: 'Timed 6-8 AM Supply',
                    subtitle: 'Gujarat Municipal',
                    isSelected: supplyType == WaterSupplyType.timedMunicipalMorning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSupplyTab(
                    type: WaterSupplyType.continuous24x7Paid,
                    title: '24x7 Paid Metered',
                    subtitle: 'Pressurized Supply',
                    isSelected: supplyType == WaterSupplyType.continuous24x7Paid,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // Educational Insights Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3138),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Color(0xFFFBBF24), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            supplyType == WaterSupplyType.timedMunicipalMorning
                                ? 'Morning Timed Water Supply Insights'
                                : '24x7 Metered Pressurized Supply Insights',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        supplyType == WaterSupplyType.timedMunicipalMorning
                            ? '• Overhead Tank Overflow is #1 loss: Motors run unattended during the 6-8 AM window, spilling 200-400L.\n• Mechanical float valve (₹150) stops 100% of overflow.\n• RO Reject Water: Catch 45L of clean reject water daily for floor mopping and plants.\n• CO2e Link: Municipal water treatment and pumping consumes ~0.45 kWh per 1,000 Liters.'
                            : '• Silent Flapper Leaks: A worn toilet flapper leaks 200L/day silently without noise. Do the food-color dye test!\n• Bucket Bath vs Shower: A bucket caps use to 15L vs a 100L 10-minute shower, saving 85 Liters!\n• Aerators on taps mix 50% air, cutting flow from 12 L/min to 3.5 L/min with identical pressure feel.',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.45),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Daily Conservation Quests',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),

                ...quests.map((q) => _buildQuestCard(q)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyTab({
    required WaterSupplyType type,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _service.setSupplyType(type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F3138),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : Colors.white10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCard(WaterQuest q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2E36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: q.isCompleted ? const Color(0xFF22C55E).withValues(alpha: 0.4) : Colors.white10,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: q.isCompleted
                  ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                  : const Color(0xFF0284C7).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              q.isCompleted ? Icons.check_circle_rounded : Icons.water_drop_outlined,
              color: q.isCompleted ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  q.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '💧 Save ${q.litersSaved}L',
                        style: const TextStyle(color: Color(0xFFBAE6FD), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B6B44).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${q.co2eSavedKg} kg CO2e',
                        style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: q.isCompleted
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    final success = _service.completeQuest(q.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎉 Completed "${q.title}"! Earned +${q.coinsReward} 🪙 and prevented CO2e!'),
                          backgroundColor: const Color(0xFF1B6B44),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: q.isCompleted ? Colors.white12 : const Color(0xFF22C55E),
              foregroundColor: q.isCompleted ? Colors.white38 : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              q.isCompleted ? 'Done' : '+${q.coinsReward} 🪙',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
