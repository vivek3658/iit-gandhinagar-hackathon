import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/calculator_service.dart';

class CarbonCalculatorScreen extends StatefulWidget {
  const CarbonCalculatorScreen({super.key});

  @override
  State<CarbonCalculatorScreen> createState() => _CarbonCalculatorScreenState();
}

class _CarbonCalculatorScreenState extends State<CarbonCalculatorScreen> {
  // Inputs
  double _monthlyKwh = 180;
  String _cookingFuelType = 'LPG_CYLINDER';
  double _cookingQuantity = 1.0;
  double _dailyCommuteKm = 15;
  String _commuteMode = 'EV_2WHEELER';
  String _dietType = 'VEGETARIAN';

  bool _isCalculating = false;
  CarbonEstimateResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    setState(() => _isCalculating = true);
    final res = await CalculatorClientService.instance.estimate(
      monthlyKwh: _monthlyKwh,
      cookingFuelType: _cookingFuelType,
      cookingQuantity: _cookingQuantity,
      dailyCommuteKm: _dailyCommuteKm,
      commuteMode: _commuteMode,
      dietType: _dietType,
    );
    if (mounted) {
      setState(() {
        _result = res;
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F261A), // Dark nature background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F261A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Carbon Footprint Calculator',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF143522),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x334ADE80)),
              ),
              child: const Row(
                children: [
                  Text('🌱', style: TextStyle(fontSize: 26)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mission LiFE Household Benchmark',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        Text(
                          'Compare your annual emissions against Gujarat and India averages and unlock rupee savings.',
                          style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Card 1: Electricity
            _buildInputCard(
              icon: '⚡',
              title: 'Monthly Electricity Consumption',
              subtitle: '${_monthlyKwh.round()} kWh / month (~₹${(_monthlyKwh * 6.5).round()} bill)',
              child: Column(
                children: [
                  Slider(
                    value: _monthlyKwh,
                    min: 50,
                    max: 600,
                    divisions: 55,
                    activeColor: const Color(0xFF22C55E),
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setState(() => _monthlyKwh = val);
                      _calculate();
                    },
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('50 kWh (1-BHK)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      Text('300 kWh (Avg)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      Text('600 kWh (AC heavy)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 2: Cooking Fuel
            _buildInputCard(
              icon: '🥘',
              title: 'Cooking Fuel Source',
              subtitle: _cookingFuelType == 'LPG_CYLINDER'
                  ? '${_cookingQuantity.toStringAsFixed(1)} cylinders / month'
                  : (_cookingFuelType == 'PNG_PIPED' ? '${(_cookingQuantity * 18).round()} SCM / month' : 'Induction Cooktop'),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildChip(
                        label: 'LPG Cylinder',
                        isSelected: _cookingFuelType == 'LPG_CYLINDER',
                        onTap: () {
                          setState(() => _cookingFuelType = 'LPG_CYLINDER');
                          _calculate();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'PNG Piped Gas',
                        isSelected: _cookingFuelType == 'PNG_PIPED',
                        onTap: () {
                          setState(() => _cookingFuelType = 'PNG_PIPED');
                          _calculate();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'Induction',
                        isSelected: _cookingFuelType == 'ELECTRIC_INDUCTION',
                        onTap: () {
                          setState(() => _cookingFuelType = 'ELECTRIC_INDUCTION');
                          _calculate();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _cookingQuantity,
                    min: 0.5,
                    max: 3.0,
                    divisions: 5,
                    activeColor: const Color(0xFF22C55E),
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setState(() => _cookingQuantity = val);
                      _calculate();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 3: Commute Mode & Distance
            _buildInputCard(
              icon: '🛵',
              title: 'Daily Commute & Transport',
              subtitle: '${_dailyCommuteKm.round()} km / day via ${_commuteLabel(_commuteMode)}',
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: '🛵 EV 2-Wheeler',
                        isSelected: _commuteMode == 'EV_2WHEELER',
                        onTap: () {
                          setState(() => _commuteMode = 'EV_2WHEELER');
                          _calculate();
                        },
                      ),
                      _buildChip(
                        label: '🚌 Metro / BRTS',
                        isSelected: _commuteMode == 'PUBLIC_BUS_METRO',
                        onTap: () {
                          setState(() => _commuteMode = 'PUBLIC_BUS_METRO');
                          _calculate();
                        },
                      ),
                      _buildChip(
                        label: '🏍️ Petrol 2W',
                        isSelected: _commuteMode == 'PETROL_2WHEELER',
                        onTap: () {
                          setState(() => _commuteMode = 'PETROL_2WHEELER');
                          _calculate();
                        },
                      ),
                      _buildChip(
                        label: '🚗 Petrol Car',
                        isSelected: _commuteMode == 'PETROL_CAR',
                        onTap: () {
                          setState(() => _commuteMode = 'PETROL_CAR');
                          _calculate();
                        },
                      ),
                      _buildChip(
                        label: '🚴 Cycle / Walk',
                        isSelected: _commuteMode == 'BICYCLE_WALK',
                        onTap: () {
                          setState(() => _commuteMode = 'BICYCLE_WALK');
                          _calculate();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _dailyCommuteKm,
                    min: 1,
                    max: 60,
                    divisions: 59,
                    activeColor: const Color(0xFF22C55E),
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setState(() => _dailyCommuteKm = val);
                      _calculate();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card 4: Diet
            _buildInputCard(
              icon: '🥗',
              title: 'Dietary Preference',
              subtitle: _dietType == 'VEGETARIAN' ? 'Traditional Gujarati Veg' : (_dietType == 'VEGAN' ? 'Plant-based Vegan' : 'Mixed Diet'),
              child: Row(
                children: [
                  _buildChip(
                    label: '🥦 Gujarati Veg',
                    isSelected: _dietType == 'VEGETARIAN',
                    onTap: () {
                      setState(() => _dietType = 'VEGETARIAN');
                      _calculate();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    label: '🌱 Vegan',
                    isSelected: _dietType == 'VEGAN',
                    onTap: () {
                      setState(() => _dietType = 'VEGAN');
                      _calculate();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    label: '🍗 Non-Veg',
                    isSelected: _dietType == 'NON_VEGETARIAN',
                    onTap: () {
                      setState(() => _dietType = 'NON_VEGETARIAN');
                      _calculate();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isCalculating && _result == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
                ),
              ),

            // RESULTS SECTION
            if (_result != null) ...[
              _buildResultHeroCard(_result!),
              const SizedBox(height: 20),
              _buildBenchmarkComparisonCard(_result!),
              const SizedBox(height: 20),
              _buildActionPlanSection(_result!),
            ],
          ],
        ),
      ),
    );
  }

  String _commuteLabel(String mode) {
    if (mode == 'EV_2WHEELER') return 'EV 2-Wheeler';
    if (mode == 'PUBLIC_BUS_METRO') return 'Ahmedabad Metro / BRTS';
    if (mode == 'PETROL_2WHEELER') return 'Petrol 2-Wheeler';
    if (mode == 'PETROL_CAR') return 'Petrol Car';
    return 'Bicycle / Walking';
  }

  Widget _buildInputCard({
    required String icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF0F261A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF86EFAC) : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeroCard(CarbonEstimateResult res) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF0D2817)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR ANNUAL FOOTPRINT',
                style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  res.rating,
                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${res.totalYearlyKgCO2e.round()}',
                style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              const Text(
                'kg CO₂e / year',
                style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Equal to ${(res.totalMonthlyKgCO2e).round()} kg CO₂e each month',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const Divider(color: Colors.white24, height: 24),

          // Percentage breakdown bars
          Row(
            children: [
              _breakdownBar('Electricity', res.percentages['electricity'] ?? 60, const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              _breakdownBar('Cooking', res.percentages['cooking'] ?? 15, const Color(0xFFFB923C)),
              const SizedBox(width: 8),
              _breakdownBar('Commute', res.percentages['commute'] ?? 15, const Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              _breakdownBar('Diet', res.percentages['dietWaste'] ?? 10, const Color(0xFF4ADE80)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownBar(String label, double pct, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
              Text('${pct.round()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkComparisonCard(CarbonEstimateResult res) {
    final diffGujarat = res.gujaratAverageKgCO2e - res.totalYearlyKgCO2e;
    final isLower = diffGujarat > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏛️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gujarat & India Benchmark', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(
                      isLower
                          ? '🎉 You produce ${diffGujarat.round()} kg LESS than Gujarat average!'
                          : '💡 ${(-diffGujarat).round()} kg above Gujarat state average',
                      style: TextStyle(
                        color: isLower ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildBenchmarkRow('Your Household', res.totalYearlyKgCO2e, 2500, const Color(0xFF4ADE80)),
          const SizedBox(height: 10),
          _buildBenchmarkRow('Gujarat Average', res.gujaratAverageKgCO2e, 2500, const Color(0xFFFBBF24)),
          const SizedBox(height: 10),
          _buildBenchmarkRow('India Average', res.indiaAverageKgCO2e, 2500, const Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildBenchmarkRow(String label, double val, double maxVal, Color color) {
    final pct = (val / maxVal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text('${val.round()} kg', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPlanSection(CarbonEstimateResult res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TAILORED MISSION LiFE SAVINGS PLAN',
          style: TextStyle(
            color: Color(0xFF86EFAC),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in res.actionPlan) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10281C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Text(item['icon'] as String? ?? '💡', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String? ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['description'] as String? ?? '',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Save ₹${item['annualSavingsRupees']}/yr',
                      style: const TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    Text(
                      '-${item['annualCo2ReductionKg']} kg CO₂',
                      style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
