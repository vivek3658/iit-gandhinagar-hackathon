import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/citizen_data_service.dart';
import '../../services/game_state_service.dart';

/// Monthly Electricity Meter Units Tracker & Reduction Plot Graph.
///
/// Features:
/// - Clean White & Emerald Green UI designed for Hackathon Judges
/// - Interactive custom canvas plot showing historical consumption trajectory
/// - Dynamic target reduction line (-5% to -40% reduction goal)
/// - User-entered monthly electricity readings from the backend
class MonthlyElectricityTrackerSheet extends StatefulWidget {
  const MonthlyElectricityTrackerSheet({super.key});

  @override
  State<MonthlyElectricityTrackerSheet> createState() =>
      _MonthlyElectricityTrackerSheetState();
}

class _MonthlyElectricityTrackerSheetState
    extends State<MonthlyElectricityTrackerSheet> {
  final GameStateService _state = GameStateService.instance;
  final TextEditingController _unitsController = TextEditingController();
  List<UtilityReading> _readings = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  @override
  void dispose() {
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _loadReadings() async {
    final auth = AuthService.instance;
    if (!auth.isLoggedIn || auth.isGuestMode) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sign in to save and view readings across your devices.';
      });
      return;
    }

    try {
      final readings = await CitizenDataService.instance.getReadings();
      if (!mounted) return;
      setState(() {
        _readings = readings;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _saveNewReading() async {
    if (_saving) return;
    final auth = AuthService.instance;
    if (!auth.isLoggedIn || auth.isGuestMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to save readings to your account.'),
        ),
      );
      return;
    }
    final text = _unitsController.text.trim();
    if (text.isEmpty) return;

    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid electricity consumption in kWh!'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    try {
      await CitizenDataService.instance.addReading(
        utility: 'ELECTRICITY',
        value: parsed,
        unit: 'kWh',
        periodStart: DateTime(now.year, now.month, 1),
        periodEnd: now,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _unitsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Electricity reading saved to your account.'),
          backgroundColor: Color(0xFF1B6B44),
        ),
      );
      await _loadReadings();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, double> _electricityLedger() {
    final electricityReadings =
        _readings.where((reading) => reading.utility == 'ELECTRICITY').toList()
          ..sort((a, b) {
            final byPeriod = a.periodEnd.compareTo(b.periodEnd);
            return byPeriod == 0
                ? a.createdAt.compareTo(b.createdAt)
                : byPeriod;
          });
    final ledger = <String, double>{};
    for (final reading in electricityReadings) {
      final month = reading.periodEnd.length >= 7
          ? reading.periodEnd.substring(0, 7)
          : reading.periodEnd;
      ledger[month] = reading.value;
    }
    return ledger;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final ledger = _electricityLedger();
        final currentUnits = ledger.isEmpty ? null : ledger.values.last;
        final targetUnits = currentUnits == null
            ? null
            : currentUnits * (1.0 - (_state.targetReductionPercent / 100.0));

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x260F2B1A),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Text('📈', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Electricity & Reduction',
                            style: TextStyle(
                              color: Color(0xFF0F2B1A),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Saved readings & personal target curve',
                            style: TextStyle(
                              color: Color(0xFF1B6B44),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFE2E8F0), height: 20),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // Plot Graph Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD1FAE5),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Electricity Units Plot (kWh)',
                                style: TextStyle(
                                  color: Color(0xFF0F2B1A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Recorded',
                                    style: TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 10,
                                    height: 3,
                                    color: const Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Target Goal',
                                    style: TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: _loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ledger.isEmpty
                                ? Center(
                                    child: Text(
                                      _error ??
                                          'Your saved electricity readings will appear here.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : CustomPaint(
                                    painter: _ElectricityPlotPainter(
                                      ledger: ledger,
                                      targetReductionPercent:
                                          _state.targetReductionPercent,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Target Reduction Slider
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Target Reduction Goal',
                                style: TextStyle(
                                  color: Color(0xFF0F2B1A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF86EFAC),
                                  ),
                                ),
                                child: Text(
                                  '-${_state.targetReductionPercent.toInt()}%',
                                  style: const TextStyle(
                                    color: Color(0xFF166534),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _state.targetReductionPercent,
                            min: 5.0,
                            max: 40.0,
                            divisions: 7,
                            activeColor: const Color(0xFF16A34A),
                            inactiveColor: const Color(0xFFE2E8F0),
                            onChanged: (val) {
                              _state.setTargetReductionPercent(val);
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Latest: ${currentUnits?.toStringAsFixed(0) ?? '—'} kWh',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Goal: ${targetUnits?.toStringAsFixed(0) ?? '—'} kWh',
                                style: const TextStyle(
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Text(
                        'This chart shows readings you enter and a personal target. '
                        'Bill savings and CO₂e reductions are not calculated without '
                        'verified tariff and emissions data.',
                        style: TextStyle(
                          color: Color(0xFF854D0E),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Record 1st Day of Month Units Input
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Log This Month’s Electricity Use',
                            style: TextStyle(
                              color: Color(0xFF0F2B1A),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter electricity use from your bill. This is a user-entered reading, not a live meter feed.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _unitsController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: Color(0xFF0F2B1A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    suffixText: 'kWh',
                                    suffixStyle: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFD1FAE5),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF16A34A),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _saving ? null : _saveNewReading,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  _saving ? 'Saving…' : 'Save Reading',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom Canvas Painter rendering a smooth consumption curve and target line
class _ElectricityPlotPainter extends CustomPainter {
  final Map<String, double> ledger;
  final double targetReductionPercent;

  _ElectricityPlotPainter({
    required this.ledger,
    required this.targetReductionPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ledger.isEmpty) return;

    final sortedKeys = ledger.keys.toList()..sort();
    final values = sortedKeys.map((k) => ledger[k]!).toList();
    final latestVal = values.last;
    final targetVal = latestVal * (1.0 - (targetReductionPercent / 100.0));

    // Combine historical values + 1 projected point for future goal
    final allValues = [...values, targetVal];
    final labels = [...sortedKeys.map((k) => k.substring(5)), 'Goal'];

    final maxVal = (allValues.reduce(math.max) * 1.15).ceilToDouble();
    final minVal = (allValues.reduce(math.min) * 0.85).floorToDouble();
    final valRange = (maxVal - minVal) <= 0 ? 1.0 : (maxVal - minVal);

    final leftMargin = 32.0;
    final bottomMargin = 24.0;
    final plotW = size.width - leftMargin;
    final plotH = size.height - bottomMargin;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 3; i++) {
      final y = plotH - (i / 3.0) * plotH;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);

      final gridVal = (minVal + (i / 3.0) * valRange).toInt();
      textPainter.text = TextSpan(
        text: '$gridVal',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Historical Points
    final points = <Offset>[];
    final stepX = plotW / (allValues.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = leftMargin + i * stepX;
      final y = plotH - ((values[i] - minVal) / valRange) * plotH;
      points.add(Offset(x, y));
    }

    // Draw Gradient Area under Historical Curve
    final path = Path()..moveTo(points.first.dx, plotH);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(points.last.dx, plotH);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF16A34A).withValues(alpha: 0.25),
          const Color(0xFF16A34A).withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, plotH));

    canvas.drawPath(path, fillPaint);

    // Draw Historical Line
    final linePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw Data Point Circles
    final pointPaint = Paint()..color = const Color(0xFF16A34A);
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 5, pointPaint);
      canvas.drawCircle(p, 5, dotBorderPaint);
    }

    // Draw Projected Target Line (Dashed Orange-Yellow to Goal Point)
    final goalX = leftMargin + (allValues.length - 1) * stepX;
    final goalY = plotH - ((targetVal - minVal) / valRange) * plotH;
    final goalOffset = Offset(goalX, goalY);

    final dashPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw dashed line from points.last to goalOffset
    final lastPoint = points.last;
    final distance = (goalOffset - lastPoint).distance;
    final dashW = 6.0;
    final spaceW = 4.0;
    double drawn = 0.0;
    final dir = (goalOffset - lastPoint) / distance;

    while (drawn < distance) {
      final start = lastPoint + dir * drawn;
      final end = lastPoint + dir * math.min(drawn + dashW, distance);
      canvas.drawLine(start, end, dashPaint);
      drawn += dashW + spaceW;
    }

    // Draw Goal Circle
    canvas.drawCircle(goalOffset, 6, Paint()..color = const Color(0xFFD97706));
    canvas.drawCircle(
      goalOffset,
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // X-Axis Month Labels
    for (int i = 0; i < labels.length; i++) {
      final x = leftMargin + i * stepX;
      final isGoal = i == labels.length - 1;
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isGoal ? const Color(0xFFD97706) : const Color(0xFF334155),
          fontWeight: isGoal ? FontWeight.bold : FontWeight.w600,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, plotH + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _ElectricityPlotPainter oldDelegate) {
    return oldDelegate.ledger != ledger ||
        oldDelegate.targetReductionPercent != targetReductionPercent;
  }
}
