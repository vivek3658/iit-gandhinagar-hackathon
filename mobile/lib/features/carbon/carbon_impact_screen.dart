import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class CarbonImpactDashboardScreen extends StatelessWidget {
  const CarbonImpactDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UrjaColors.emeraldBg,
      appBar: AppBar(
        backgroundColor: UrjaColors.emeraldBg,
        elevation: 0,
        title: const Text(
          'Carbon Footprint & Impact',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Carbon Avoided Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: UrjaColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total CO₂e Prevented',
                        style: TextStyle(
                          color: Color(0xFFD1FAE5),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🌱 Top 5% Gujarat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '280.4',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'kg CO₂e',
                        style: TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatColumn(title: 'Trees Equivalent', value: '14.2 🌲'),
                      _StatColumn(title: 'Solar Generated', value: '312 kWh ☀️'),
                      _StatColumn(title: 'Grid Shifted', value: '48.5 hrs ⚡'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Real-Time Grid Status (Gujarat DISCOM Alert)
            const Text(
              'Gujarat Grid Status (DISCOM)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: UrjaColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UrjaColors.borderGreen),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: UrjaColors.amberGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('⚡', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Evening Peak (6:30 - 9:30 PM)',
                          style: TextStyle(
                            color: UrjaColors.sunnyYellow,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Switch off geysers, pumps & idle ACs during this window to earn 2x bonus Urja Mudra coins!',
                          style: TextStyle(
                            color: UrjaColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Monthly Reduction Trajectory Breakdown
            const Text(
              'Monthly Breakdown (kWh & Carbon)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            _buildMonthlyCard('October 2026', '210 kWh', '-35.2 kg CO₂', 'Saved ₹420 on electricity bill', 0.85),
            const SizedBox(height: 10),
            _buildMonthlyCard('September 2026', '245 kWh', '-28.0 kg CO₂', 'Saved ₹310 on electricity bill', 0.70),
            const SizedBox(height: 10),
            _buildMonthlyCard('August 2026', '280 kWh', '-19.4 kg CO₂', 'Baseline established', 0.55),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCard(String month, String kwh, String co2Saved, String billSavings, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UrjaColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UrjaColors.borderGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                co2Saved,
                style: const TextStyle(
                  color: UrjaColors.primaryGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$kwh consumed · $billSavings',
            style: const TextStyle(
              color: UrjaColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: UrjaColors.borderGreen,
            color: UrjaColors.primaryGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String title;
  final String value;

  const _StatColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD1FAE5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
