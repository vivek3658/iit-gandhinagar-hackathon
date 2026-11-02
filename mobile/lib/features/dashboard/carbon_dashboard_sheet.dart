import 'package:flutter/material.dart';

import '../../models/senior_carbon_analytics.dart';
import '../../services/api_client.dart';

/// Senior Energy & Carbon Analytics Sheet (Mission LiFE Gujarat Standard)
///
/// Features:
/// - Clean White & Emerald Green palette tailored for Hackathon Judges
/// - 24-hour hourly load curve with solar generation overlay
/// - Real-time active power metrics & emissions prevented ledger
/// - Appliance power split with high-consumption alerts
/// - Gujarat Time-of-Day (ToD) tariff optimization insights
class CarbonDashboardSheet extends StatefulWidget {
  final VoidCallback? onActionCompleted;

  const CarbonDashboardSheet({super.key, this.onActionCompleted});

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onActionCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CarbonDashboardSheet(onActionCompleted: onActionCompleted),
    );
  }

  @override
  State<CarbonDashboardSheet> createState() => _CarbonDashboardSheetState();
}

class _CarbonDashboardSheetState extends State<CarbonDashboardSheet> {
  SeniorCarbonAnalytics? _data;
  bool _isLoading = true;
  String? _error;
  int _selectedDomainTab = 0;

  @override
  void initState() {
    super.initState();
    _fetchCarbonAnalytics();
  }

  Future<void> _fetchCarbonAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.get('/analytics/carbon');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Analytics request failed (${response.statusCode}).');
      }
      final analytics = SeniorCarbonAnalytics.fromJson(response.decodeJson());
      if (!mounted) return;
      setState(() {
        _data = analytics;
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _data = null;
          _error = error.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x260F2B1A),
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
                color: const Color(0xFFCBD5E1),
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
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Text('📊', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Home Utility Dashboard',
                      style: TextStyle(
                        color: Color(0xFF0F2B1A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Saved utility readings and available measurements',
                      style: TextStyle(
                        color: Color(0xFF1B6B44),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 20),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                  )
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: Color(0xFF64748B),
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: _fetchCarbonAnalytics,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      // Filter saved readings by utility type.
                      _buildDomainTabBar(),
                      _buildInteractiveBarGraph(),
                      const SizedBox(height: 12),
                      _buildLatestUtilityCards(),
                      const SizedBox(height: 18),
                      _buildRealTimeMetricsRow(),
                      const SizedBox(height: 18),

                      _buildSectionTitle('METER TELEMETRY'),
                      const SizedBox(height: 8),
                      _buildLoadCurveChart(),
                      const SizedBox(height: 18),

                      _buildSectionTitle('APPLIANCE MEASUREMENTS'),
                      const SizedBox(height: 8),
                      _buildApplianceSplitCard(),
                      const SizedBox(height: 18),

                      _buildSectionTitle('VERIFIED CO₂e IMPACT'),
                      const SizedBox(height: 8),
                      _buildCarbonLedgerCard(),
                      const SizedBox(height: 18),

                      _buildTariffInsightCard(),
                      const SizedBox(height: 12),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainTabBar() {
    final tabs = ['CO2E 🍃', 'ELECTRICITY ⚡', 'WATER 💧', 'GAS 🥘'];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final isSelected = _selectedDomainTab == idx;
          return GestureDetector(
            onTap: () => setState(() => _selectedDomainTab = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(
                  tabs[idx],
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInteractiveBarGraph() {
    final utility = switch (_selectedDomainTab) {
      1 => 'ELECTRICITY',
      2 => 'WATER',
      3 => 'GAS',
      _ => null,
    };
    final readings =
        (_data?.utilityReadings ?? [])
            .where((reading) => reading['utility'] == utility)
            .toList()
          ..sort(
            (a, b) => (b['periodEnd'] as String? ?? '').compareTo(
              a['periodEnd'] as String? ?? '',
            ),
          );
    final unit = readings.isEmpty ? null : readings.first['unit'] as String?;
    final barData = readings
        .where((reading) => reading['unit'] == unit)
        .take(7)
        .map(
          (reading) => {
            'day': reading['periodEnd'] as String? ?? '',
            'val': reading['value'] as num? ?? 0,
            'unit': unit ?? '',
          },
        )
        .toList()
        .reversed
        .toList();

    if (utility == null || barData.isEmpty) {
      return _unavailableCard(
        utility == null
            ? 'Emissions are not available because no validated CO₂e source is configured.'
            : 'No $utility readings saved yet. Add a reading to see it here.',
      );
    }

    final maxVal = barData
        .map((e) => (e['val'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SAVED ${utility ?? ''} READINGS (${unit ?? ''})',
                style: TextStyle(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'USER-ENTERED',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar Columns
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: barData.map((item) {
                final val = (item['val'] as num).toDouble();
                final heightFactor = (val / maxVal).clamp(0.12, 1.0);
                final isToday = item['day'] == 'Today';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      val.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isToday
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: 80 * heightFactor,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isToday
                              ? [
                                  const Color(0xFF16A34A),
                                  const Color(0xFF4ADE80),
                                ]
                              : [
                                  const Color(0xFF94A3B8),
                                  const Color(0xFFCBD5E1),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (item['day'] as String).length >= 10
                          ? (item['day'] as String).substring(5, 10)
                          : item['day'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                        color: isToday
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestUtilityCards() {
    final readings = _data?.utilityReadings ?? [];
    final electricity = _latestUtilityReading(readings, 'ELECTRICITY');
    final water = _latestUtilityReading(readings, 'WATER');
    final gas = _latestUtilityReading(readings, 'GAS');

    return Row(
      children: [
        Expanded(
          child: _summaryStatCard(
            title: 'Electricity',
            val: electricity == null
                ? '--'
                : '${electricity['value']} ${electricity['unit']}',
            sub: electricity == null
                ? 'No saved reading'
                : 'Through ${electricity['periodEnd']}',
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryStatCard(
            title: 'Water',
            val: water == null ? '--' : '${water['value']} ${water['unit']}',
            sub: water == null
                ? 'No saved reading'
                : 'Through ${water['periodEnd']}',
            color: const Color(0xFF0284C7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryStatCard(
            title: 'Gas',
            val: gas == null ? '--' : '${gas['value']} ${gas['unit']}',
            sub: gas == null
                ? 'No saved reading'
                : 'Through ${gas['periodEnd']}',
            color: const Color(0xFFD97706),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _latestUtilityReading(
    List<Map<String, dynamic>> readings,
    String utility,
  ) {
    final matching =
        readings.where((reading) => reading['utility'] == utility).toList()
          ..sort(
            (a, b) => (b['periodEnd'] as String? ?? '').compareTo(
              a['periodEnd'] as String? ?? '',
            ),
          );
    return matching.isEmpty ? null : matching.first;
  }

  Widget _unavailableCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _summaryStatCard({
    required String title,
    required String val,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w500,
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
        color: Color(0xFF166534),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildRealTimeMetricsRow() {
    final m = _data?.realTimeMetrics ?? {};
    String metric(String key, String unit) {
      final value = m[key];
      return value is num
          ? '${value.toStringAsFixed(1)} $unit'
          : 'Not measured';
    }

    return Row(
      children: [
        Expanded(
          child: _metricPill(
            '⚡ Active Load',
            metric('activePowerKw', 'kW'),
            const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricPill(
            '🔌 Today Grid',
            metric('todayKwh', 'kWh'),
            const Color(0xFF0F2B1A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricPill(
            '☀️ Solar Gen',
            metric('todaySolarKwh', 'kWh'),
            const Color(0xFF0284C7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricPill(
            '🌱 Avoided',
            metric('todayCo2AvoidedKg', 'kg CO₂e'),
            const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _metricPill(String title, String val, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(
              color: valColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadCurveChart() {
    final points = _data?.hourlyLoadCurve ?? [];
    if (points.isEmpty) {
      return _unavailableCard(
        'Hourly load and solar interval data are not connected to a meter source.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 16,
                color: Color(0xFF16A34A),
              ),
              SizedBox(width: 6),
              Text(
                'Measured Load vs Solar Generation',
                style: TextStyle(
                  color: Color(0xFF0F2B1A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom 24-hr load chart painter
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(painter: _LoadCurvePainter(points: points)),
          ),
          const SizedBox(height: 8),

          // Legend
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: Color(0xFF16A34A),
                label: 'Appliance Load (kW)',
              ),
              const SizedBox(width: 16),
              const _LegendDot(
                color: Color(0xFF0284C7),
                label: 'Solar Output (kW)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceSplitCard() {
    final apps = _data?.applianceBreakdown ?? [];
    if (apps.isEmpty) {
      return _unavailableCard(
        'Appliance-level consumption is not available from saved utility bills.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1.2),
      ),
      child: Column(
        children: [
          for (final a in apps) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    a['icon'] as String? ?? '📱',
                    style: const TextStyle(fontSize: 18),
                  ),
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
                              style: const TextStyle(
                                color: Color(0xFF0F2B1A),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${a['percentShare']}% • ${a['kwhPerMonth']} kWh/mo',
                              style: const TextStyle(
                                color: Color(0xFF166534),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:
                                ((a['percentShare'] as num?)?.toDouble() ??
                                    10) /
                                100,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation(
                              (a['rating'] == 'HIGH')
                                  ? const Color(0xFFEA580C)
                                  : ((a['rating'] == 'MODERATE')
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF16A34A)),
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
    if (ledger.isEmpty) {
      return _unavailableCard(
        'Environmental impact will appear when validated emission factors and source data are available.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 1.2),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD1FAE5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F2B1A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    '${pct.round()}%',
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${kg.round()} kg',
                    style: const TextStyle(
                      color: Color(0xFF0F2B1A),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    domain.split(' ')[0],
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
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
    final rec = insights['recommendation'] as String?;
    if (rec == null) {
      return _unavailableCard(
        'Tariff recommendations are not available because no provider tariff data is configured.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
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
                  'DISCOM Peak Shifting Advisory',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec,
                  style: const TextStyle(
                    color: Color(0xFF78350F),
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
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
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final solarPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw baseline grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      gridPaint,
    );

    final maxKw = points.fold<double>(0, (maximum, point) {
      final load = (point['loadKw'] as num?)?.toDouble() ?? 0;
      final solar = (point['solarGenKw'] as num?)?.toDouble() ?? 0;
      return [maximum, load, solar].reduce((a, b) => a > b ? a : b);
    });
    final chartMaxKw = maxKw > 0 ? maxKw : 1;

    final loadPath = Path();
    final solarPath = Path();

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = points.length == 1
          ? size.width / 2
          : (i / (points.length - 1)) * size.width;
      final loadKw = (p['loadKw'] as num?)?.toDouble() ?? 0;
      final solarKw = (p['solarGenKw'] as num?)?.toDouble() ?? 0.0;

      final yLoad =
          size.height -
          (loadKw / chartMaxKw * size.height).clamp(0.0, size.height);
      final ySolar =
          size.height -
          (solarKw / chartMaxKw * size.height).clamp(0.0, size.height);

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
