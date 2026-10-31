import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/device_time_log_service.dart';
import '../../services/game_state_service.dart';

class DeviceTimeLogSheet extends StatefulWidget {
  const DeviceTimeLogSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DeviceTimeLogSheet(),
    );
  }

  @override
  State<DeviceTimeLogSheet> createState() => _DeviceTimeLogSheetState();
}

class _DeviceTimeLogSheetState extends State<DeviceTimeLogSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDeviceId = 'ac';
  double _operatingHours = 6.5;
  double _thermostatTemp = 24.0;
  bool _isLogging = false;
  LoggedDeviceResult? _loggedResult;

  final Map<String, Map<String, dynamic>> _appliances = {
    'ac': {
      'name': 'Inverter Split AC (1.5 Ton)',
      'icon': '❄️',
      'kw': 1.45,
      'ecoLimit': 5.0,
      'tip': 'Every 1°C below 24°C burns ~6% more power.',
    },
    'geyser': {
      'name': 'Storage Water Geyser (2.0 kW)',
      'icon': '🚿',
      'kw': 2.0,
      'ecoLimit': 1.5,
      'tip': 'Turn off immediately after bath to stop automatic reheat cycles.',
    },
    'pump': {
      'name': 'Sump Water Pump (1.0 HP)',
      'icon': '💧',
      'kw': 1.1,
      'ecoLimit': 1.0,
      'tip': 'Automatic tank float switch prevents overhead tank overflow.',
    },
    'induction': {
      'name': 'Smart Induction Cooktop',
      'icon': '🥘',
      'kw': 1.5,
      'ecoLimit': 2.0,
      'tip': 'Flat bottom stainless steel pans cut cooking time by 20%.',
    },
    'ev_charger': {
      'name': 'EV 2-Wheeler Home Charger',
      'icon': '🛵',
      'kw': 0.75,
      'ecoLimit': 4.0,
      'tip': 'Charge during solar noon window (11 AM - 3 PM) for free green power.',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submitLog() async {
    setState(() => _isLogging = true);
    HapticFeedback.mediumImpact();

    final res = await DeviceTimeLogService.instance.logHours(
      deviceCatalogId: _selectedDeviceId,
      operatingHours: _operatingHours,
      thermostatTemp: _selectedDeviceId == 'ac' ? _thermostatTemp : null,
    );

    // Reward coins for diligence
    GameStateService.instance.addCoins(10);

    if (mounted) {
      setState(() {
        _isLogging = false;
        _loggedResult = res;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1B6B44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Text('⏱️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Runtime logged! +10 Urja Mudra coins earned.',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
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
                child: const Text('⏱️', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appliance Runtime Logger',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'High-Hour Warning Alerts & Standby Waste Prevention',
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
          const SizedBox(height: 10),

          // Tab Selector: Log Runtime vs History
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF143522),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              tabs: const [
                Tab(text: '⏱️ Log Runtime'),
                Tab(text: '📜 Past History & Trends'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogInputView(),
                _buildHistoryView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogInputView() {
    final currentSpec = _appliances[_selectedDeviceId] ?? _appliances['ac']!;
    final ecoLimit = (currentSpec['ecoLimit'] as num).toDouble();
    final isOverLimit = _operatingHours > ecoLimit;

    return ListView(
      children: [
        // Appliance Selector Chips
        const Text(
          'SELECT APPLIANCE',
          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _appliances.entries.map((entry) {
              final id = entry.key;
              final spec = entry.value;
              final isSelected = _selectedDeviceId == id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Text(spec['icon'] as String),
                  label: Text(
                    spec['name'].toString().split(' ')[0],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF22C55E),
                  backgroundColor: const Color(0xFF143522),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedDeviceId = id;
                        _operatingHours = (spec['ecoLimit'] as num).toDouble() + 1.5;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Runtime Hours Slider Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF143522),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isOverLimit ? const Color(0xFFF97316) : Colors.white12,
              width: isOverLimit ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(currentSpec['icon'] as String, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        currentSpec['name'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOverLimit ? const Color(0xFF7C2D12) : const Color(0xFF1B6B44),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOverLimit ? '⚠️ Above Limit' : '✓ Optimal',
                      style: TextStyle(
                        color: isOverLimit ? const Color(0xFFFDBA74) : const Color(0xFF86EFAC),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hours Used Today:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '${_operatingHours.toStringAsFixed(1)} hrs',
                    style: TextStyle(
                      color: isOverLimit ? const Color(0xFFFDBA74) : const Color(0xFF86EFAC),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _operatingHours,
                min: 0.5,
                max: 16.0,
                divisions: 31,
                activeColor: isOverLimit ? const Color(0xFFF97316) : const Color(0xFF22C55E),
                inactiveColor: Colors.white12,
                onChanged: (val) {
                  setState(() => _operatingHours = val);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0.5h', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text('Eco Threshold: ${ecoLimit.toStringAsFixed(1)}h', style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.w700)),
                  const Text('16.0h', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),

              if (_selectedDeviceId == 'ac') ...[
                const Divider(color: Colors.white12, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thermostat Setting:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '${_thermostatTemp.round()}°C',
                      style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Slider(
                  value: _thermostatTemp,
                  min: 18,
                  max: 28,
                  divisions: 10,
                  activeColor: const Color(0xFFFBBF24),
                  inactiveColor: Colors.white12,
                  onChanged: (val) {
                    setState(() => _thermostatTemp = val);
                  },
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('18°C (High Bill)', style: TextStyle(color: Color(0xFFEF4444), fontSize: 10)),
                    Text('24°C (BEE Standard)', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.w700)),
                    Text('28°C (Low)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Senior Engineer Appliance Advice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10281C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  currentSpec['tip'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Submit Button
        ElevatedButton.icon(
          onPressed: _isLogging ? null : _submitLog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: _isLogging
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Icon(Icons.check_circle_rounded, size: 20),
          label: const Text(
            'Log Runtime & Check Alert (+10 🪙)',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        const SizedBox(height: 18),

        // Results / High Usage Alert Card (if triggered)
        if (_loggedResult?.highUsageAlert != null) ...[
          _buildHighUsageAlertCard(_loggedResult!.highUsageAlert!),
        ],
      ],
    );
  }

  Widget _buildHistoryView() {
    final history = DeviceTimeLogService.instance.history;

    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No runtime logs recorded yet.\nLog your daily appliance hours to track trends!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      );
    }

    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final entry = history[i];
        final formattedDate = '${entry.loggedAt.day}/${entry.loggedAt.month}';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF143522),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: entry.isOverLimit ? const Color(0xFFF97316) : Colors.white12,
            ),
          ),
          child: Row(
            children: [
              Text(entry.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.deviceName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        if (entry.isOverLimit) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C2D12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('⚠️ HIGH', style: TextStyle(color: Color(0xFFFDBA74), fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$formattedDate • ${entry.operatingHours} hrs • ${entry.energyConsumedKwh} kWh',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${entry.costRupees}',
                    style: const TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  Text(
                    '${entry.co2EmissionsKg} kg CO₂',
                    style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighUsageAlertCard(HighUsageAlertData alert) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A150D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF97316), width: 1.8),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.alertTitle,
                  style: const TextStyle(color: Color(0xFFFDBA74), fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.alertMessage,
            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
          ),
          const Divider(color: Colors.white24, height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Cost Penalty:', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    Text(
                      '~₹${alert.potentialSavingsRupeesMonthly} / mo',
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Carbon Waste:', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    Text(
                      '${alert.potentialCo2ReductionKgMonthly} kg CO₂e',
                      style: const TextStyle(color: Color(0xFFF97316), fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF143522),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4ADE80)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.recommendation,
                    style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w700),
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
