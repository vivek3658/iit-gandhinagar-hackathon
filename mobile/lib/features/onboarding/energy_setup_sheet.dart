import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:urja/services/game_state_service.dart';

/// Modal bottom sheet for configuring user electricity provider DISCOM,
/// rooftop solar installation details, and home geofence.
class EnergySetupSheet extends StatefulWidget {
  const EnergySetupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const EnergySetupSheet(),
    );
  }

  @override
  State<EnergySetupSheet> createState() => _EnergySetupSheetState();
}

class _EnergySetupSheetState extends State<EnergySetupSheet> {
  final _gameState = GameStateService.instance;
  late String _provider;
  late bool _hasSolar;
  late double _solarKw;
  late bool _hasBattery;

  final List<String> _providers = [
    'Torrent Power (Ahmedabad / Surat / Gandhinagar)',
    'UGVCL (Uttar Gujarat Vij Company Ltd)',
    'DGVCL (Dakshin Gujarat Vij Company Ltd)',
    'MGVCL (Madhya Gujarat Vij Company Ltd)',
    'PGVCL (Paschim Gujarat Vij Company Ltd)',
    'Tata Power Solar',
    'Adani Electricity',
    'BESCOM (Karnataka)',
    'MSEDCL (Maharashtra)',
    'BSES Rajdhani (Delhi)',
  ];

  @override
  void initState() {
    super.initState();
    _provider = _gameState.electricityProvider;
    _hasSolar = _gameState.hasSolar;
    _solarKw = _gameState.solarCapacityKw;
    _hasBattery = _gameState.hasBatteryStorage;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF092015),
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFFBBF24),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Energy & Solar Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'DISCOM Provider • PM Surya Ghar Rooftop',
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

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Electricity Provider DISCOM
                const Text(
                  'Electricity Utility Provider (DISCOM)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3120),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _providers.contains(_provider) ? _provider : _providers.first,
                      dropdownColor: const Color(0xFF0F3120),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                      items: _providers.map((p) {
                        return DropdownMenuItem<String>(
                          value: p,
                          child: Text(
                            p,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _provider = val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Solar Rooftop Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3120),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _hasSolar ? const Color(0xFFFBBF24).withValues(alpha: 0.4) : Colors.white10,
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
                              Icon(
                                Icons.solar_power_rounded,
                                color: _hasSolar ? const Color(0xFFFBBF24) : Colors.white38,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Rooftop Solar Installed?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _hasSolar,
                            activeThumbColor: const Color(0xFFFBBF24),
                            onChanged: (val) {
                              setState(() => _hasSolar = val);
                            },
                          ),
                        ],
                      ),

                      if (_hasSolar) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Solar Plant Capacity',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '${_solarKw.toStringAsFixed(1)} kW',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _solarKw,
                          min: 1.0,
                          max: 10.0,
                          divisions: 18,
                          activeColor: const Color(0xFFFBBF24),
                          inactiveColor: Colors.white12,
                          onChanged: (val) {
                            setState(() => _solarKw = val);
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Battery Storage Backup',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Switch(
                              value: _hasBattery,
                              activeThumbColor: const Color(0xFF34D399),
                              onChanged: (val) {
                                setState(() => _hasBattery = val);
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Solar Insight Callout
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFFBBF24), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Even with rooftop solar, eliminating standby loads and wasteful consumption boosts your net-metered grid feed-in earnings (₹2.25/unit under PM Surya Ghar Muft Bijli Yojana) and extends battery storage life!',
                          style: TextStyle(color: Colors.white, fontSize: 11, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    _gameState.setElectricityProvider(_provider);
                    _gameState.setSolarDetails(
                      hasSolar: _hasSolar,
                      capacityKw: _solarKw,
                      hasBattery: _hasBattery,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✨ Energy and Solar Profile Updated!'),
                        backgroundColor: Color(0xFF1B6B44),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Save Profile',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
