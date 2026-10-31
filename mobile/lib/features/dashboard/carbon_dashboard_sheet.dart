import 'package:flutter/material.dart';
import '../../services/analytics_service.dart';

class CarbonDashboardSheet extends StatefulWidget {
  final VoidCallback? onActionCompleted;

  const CarbonDashboardSheet({
    super.key,
    this.onActionCompleted,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CarbonDashboardSheet(),
    );
  }

  @override
  State<CarbonDashboardSheet> createState() => _CarbonDashboardSheetState();
}

class _CarbonDashboardSheetState extends State<CarbonDashboardSheet> {
  AnalyticsDashboardData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final res = await AnalyticsClientService.instance.getDashboard();
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0D2116), // Clay dark green
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
                child: const Text('📊', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Senior Energy & Carbon Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Mission LiFE Real-time Grid & Emissions Ledger',
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4ADE80)))
                : ListView(
                    children: [
                      // 1. Real-Time Power & Solar Metrics
                      _buildRealTimeMetricsRow(),
                      const SizedBox(height: 18),

                      // 2. 24-Hour Load Curve Graph
                      _buildSectionTitle('24-HOUR HOURLY LOAD CURVE (kW)'),
                      const SizedBox(height: 8),
                      _buildLoadCurveChart(),
                      const SizedBox(height: 18),

                      // 3. Appliance Power Consumption Breakdown
                      _buildSectionTitle('APPLIANCE CONSUMPTION SPLIT'),
                      const SizedBox(height: 8),
                      _buildApplianceSplitCard(),
                      const SizedBox(height: 18),

                      // 4. Multi-Domain Carbon Ledger
                      _buildSectionTitle('MULTI-DOMAIN CO₂e LEDGER'),
                      const SizedBox(height: 8),
                      _buildCarbonLedgerCard(),
                      const SizedBox(height: 18),

                      // 5. Grid Tariff & Peak Optimization Insight
                      _buildTariffInsightCard(),
                      const SizedBox(height: 12),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF86EFAC),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildRealTimeMetricsRow() {
    final m = _data?.realTimeMetrics ?? {};
    final activeKw = (m['activePowerKw'] as num?)?.toDouble() ?? 1.15;
    final todayKwh = (m['todayKwh'] as num?)?.toDouble() ?? 8.6;
    final todaySolar = (m['todaySolarKwh'] as num?)?.toDouble() ?? 11.2;
    final todayCo2 = (m['todayCo2AvoidedKg'] as num?)?.toDouble() ?? 9.2;

    return Row(
      children: [
        Expanded(child: _metricPill('⚡ Active Load', '$activeKw kW', const Color(0xFFFBBF24))),
        const SizedBox(width: 8),
        Expanded(child: _metricPill('🔌 Today Grid', '$todayKwh kWh', Colors.white)),
        const SizedBox(width: 8),
        Expanded(child: _metricPill('☀️ Solar Gen', '$todaySolar kWh', const Color(0xFF60A5FA))),
        const SizedBox(width: 8),
        Expanded(child: _metricPill('🌱 Avoided', '$todayCo2 kg', const Color(0xFF4ADE80))),
      ],
    );
  }

  Widget _metricPill(String title, String val, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 9)),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadCurveChart() {
    final points = _data?.hourlyLoadCurve ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart_rounded, size: 16, color: Color(0xFF4ADE80)),
                  SizedBox(width: 6),
                  Text(
                    'Household Demand vs Solar Generation',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Peak 18:00 - 22:00',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom 24-hr load chart painter
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _LoadCurvePainter(points: points),
            ),
          ),
          const SizedBox(height: 8),

          // Legend
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Color(0xFF22C55E), label: 'Appliance Load (kW)'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFF60A5FA), label: 'Solar Output (kW)'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFF97316), label: 'Peak Grid Window'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceSplitCard() {
    final apps = _data?.applianceBreakdown ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          for (final a in apps) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(a['icon'] as String? ?? '📱', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              a['applianceName'] as String? ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${a['percentShare']}% • ${a['kwhPerMonth']} kWh/mo',
                              style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ((a['percentShare'] as num?)?.toDouble() ?? 10) / 100,
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(
                              (a['rating'] == 'HIGH')
                                  ? const Color(0xFFF97316)
                                  : ((a['rating'] == 'MODERATE') ? const Color(0xFFFBBF24) : const Color(0xFF4ADE80)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarbonLedgerCard() {
    final ledger = _data?.carbonLedger ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: ledger.map((item) {
          final domain = item['domain'] as String? ?? '';
          final kg = (item['kgCo2e'] as num?)?.toDouble() ?? 50.0;
          final pct = (item['percent'] as num?)?.toDouble() ?? 25.0;
          final icon = item['icon'] as String? ?? '🌱';

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F261A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    '${pct.round()}%',
                    style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  Text(
                    '${kg.round()} kg',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                  Text(
                    domain.split(' ')[0],
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTariffInsightCard() {
    final insights = _data?.gridTariffInsights ?? {};
    final rec = insights['recommendation'] as String? ?? 'Optimize loads during solar hours.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2D22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBBF24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Senior Engineer Load Shifting Tip',
                  style: TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w900, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  rec,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}

class _LoadCurvePainter extends CustomPainter {
  final List<Map<String, dynamic>> points;

  _LoadCurvePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final loadPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final solarPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final peakZonePaint = Paint()
      ..color = const Color(0x33F97316)
      ..style = PaintingStyle.fill;

    // Draw peak background band (18:00 to 22:00 -> 18/24 to 22/24)
    final peakStartX = size.width * (18 / 24);
    final peakWidth = size.width * (4 / 24);
    canvas.drawRect(Rect.fromLTWH(peakStartX, 0, peakWidth, size.height), peakZonePaint);

    // Draw baseline grid
    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), gridPaint);

    const maxKw = 3.5;

    final loadPath = Path();
    final solarPath = Path();

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = (i / (points.length - 1)) * size.width;
      final loadKw = (p['loadKw'] as num?)?.toDouble() ?? 0.5;
      final solarKw = (p['solarGenKw'] as num?)?.toDouble() ?? 0.0;

      final yLoad = size.height - (loadKw / maxKw * size.height).clamp(0.0, size.height);
      final ySolar = size.height - (solarKw / maxKw * size.height).clamp(0.0, size.height);

      if (i == 0) {
        loadPath.moveTo(x, yLoad);
        solarPath.moveTo(x, ySolar);
      } else {
        loadPath.lineTo(x, yLoad);
        solarPath.lineTo(x, ySolar);
      }
    }

    canvas.drawPath(solarPath, solarPaint);
    canvas.drawPath(loadPath, loadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
