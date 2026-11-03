import 'package:flutter/material.dart';

import '../../constants/urja_theme.dart';
import '../../services/analytics_service.dart';

class CarbonImpactDashboardScreen extends StatefulWidget {
  const CarbonImpactDashboardScreen({super.key});

  @override
  State<CarbonImpactDashboardScreen> createState() =>
      _CarbonImpactDashboardScreenState();
}

class _CarbonImpactDashboardScreenState
    extends State<CarbonImpactDashboardScreen> {
  AnalyticsDashboardData? _data;
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
      final result = await AnalyticsClientService.instance.getDashboard();
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: UrjaTheme.canvas,
    appBar: AppBar(
      title: const Text('Impact & utilities'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      color: UrjaTheme.leaf,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _introCard(),
          const SizedBox(height: 18),
          const _SectionLabel('LIVE DATA'),
          const SizedBox(height: 8),
          if (_loading && _data == null)
            const _StatusCard(
              icon: Icons.sync_rounded,
              title: 'Loading utility dashboard',
              message: 'Fetching the latest data linked to your account.',
            )
          else if (_error != null && _data == null)
            _StatusCard(
              icon: Icons.cloud_off_rounded,
              title: 'Dashboard unavailable',
              message: _error!,
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            )
          else
            _AvailabilityCard(data: _data!),
          const SizedBox(height: 18),
          const _SectionLabel('YOUR SAVED READINGS'),
          const SizedBox(height: 8),
          if (_data?.utilityReadings.isNotEmpty ?? false)
            ..._data!.utilityReadings.map(_ReadingCard.new)
          else
            const _StatusCard(
              icon: Icons.receipt_long_rounded,
              title: 'No utility readings yet',
              message:
                  'Add your electricity, water, or gas bill from Track. These records are marked as citizen-entered.',
            ),
          const SizedBox(height: 18),
          const _SectionLabel('WHAT THIS DASHBOARD CAN CONFIRM'),
          const SizedBox(height: 8),
          const _StatusCard(
            icon: Icons.verified_user_outlined,
            title: 'Evidence matters',
            message:
                'Bills and meter values you enter are not live meter telemetry. Tariffs, energy savings, and CO₂e impact stay unavailable unless a validated data source is connected.',
          ),
          if (_loading) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    ),
  );

  Widget _introCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: UrjaTheme.forest,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.insights_rounded, color: Color(0xFFA8D9B3), size: 23),
        SizedBox(height: 12),
        Text(
          'A clear picture, not guesswork.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Only data returned by your account is shown here. Missing telemetry is clearly marked unavailable.',
          style: TextStyle(color: Color(0xFFDCEFE1), fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.data});

  final AnalyticsDashboardData data;

  @override
  Widget build(BuildContext context) {
    final availability = data.dataAvailability;
    final metrics = data.realTimeMetrics;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.electric_meter_rounded,
                label: 'Live meter',
                value: availability['liveMeterTelemetry'] == true
                    ? _format(metrics['todayKwh'], 'kWh')
                    : 'Unavailable',
                positive: availability['liveMeterTelemetry'] == true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.co2_rounded,
                label: 'Measured CO₂e',
                value: availability['emissions'] == true
                    ? _format(metrics['todayCo2AvoidedKg'], 'kg')
                    : 'Unavailable',
                positive: availability['emissions'] == true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.solar_power_rounded,
                label: 'Solar generation',
                value: availability['solarGeneration'] == true
                    ? _format(metrics['todaySolarKwh'], 'kWh')
                    : 'Unavailable',
                positive: availability['solarGeneration'] == true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.currency_rupee_rounded,
                label: 'Tariff data',
                value: availability['tariff'] == true
                    ? 'Connected'
                    : 'Unavailable',
                positive: availability['tariff'] == true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _format(Object? value, String unit) {
    if (value is! num) return 'Unavailable';
    return '${value.toStringAsFixed(1)} $unit';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.positive,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: positive ? UrjaTheme.leaf : UrjaTheme.muted,
          ),
          const SizedBox(height: 11),
          Text(
            label,
            style: const TextStyle(color: UrjaTheme.muted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: positive ? UrjaTheme.ink : UrjaTheme.muted,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard(this.reading);

  final Map<String, dynamic> reading;

  @override
  Widget build(BuildContext context) {
    final utility = reading['utility'] as String? ?? 'UTILITY';
    final value = (reading['value'] as num?)?.toDouble();
    final unit = reading['unit'] as String? ?? '';
    final start = reading['periodStart'] as String? ?? '';
    final end = reading['periodEnd'] as String? ?? '';
    final icon = switch (utility) {
      'ELECTRICITY' => Icons.bolt_rounded,
      'WATER' => Icons.water_drop_rounded,
      'GAS' => Icons.local_fire_department_rounded,
      _ => Icons.receipt_long_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: UrjaTheme.mint,
            foregroundColor: UrjaTheme.forest,
            child: Icon(icon),
          ),
          title: Text(
            utility.toLowerCase().replaceAll('_', ' '),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '$start — $end · Citizen-entered',
            style: const TextStyle(fontSize: 11, color: UrjaTheme.muted),
          ),
          trailing: Text(
            value == null ? '—' : '${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(
              color: UrjaTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: UrjaTheme.muted,
      fontSize: 10,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: UrjaTheme.leaf, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: UrjaTheme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: UrjaTheme.muted,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          if (action != null)
            Align(alignment: Alignment.centerRight, child: action),
        ],
      ),
    ),
  );
}
