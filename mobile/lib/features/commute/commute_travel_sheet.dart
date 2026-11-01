import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:urja/services/commute_travel_service.dart';
import 'package:urja/services/geofence_departure_service.dart';
import 'package:urja/services/game_state_service.dart';

/// Modal bottom sheet for logging sustainable travel commutes,
/// setting home location on Gujarat map, and testing auto-commute distance notifications.
class CommuteTravelSheet extends StatefulWidget {
  const CommuteTravelSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CommuteTravelSheet(),
    );
  }

  @override
  State<CommuteTravelSheet> createState() => _CommuteTravelSheetState();
}

class _CommuteTravelSheetState extends State<CommuteTravelSheet> {
  final _service = CommuteTravelService.instance;
  final _geofence = GeofenceDepartureService.instance;
  double _distanceKm = 3.5;
  CommuteMode _selectedMode = CommuteMode.publicTransit;
    String? _validationWarning;

  final List<Map<String, dynamic>> _gujaratLocations = const [
    {'name': 'Navrangpura, Ahmedabad', 'lat': 23.0365, 'lng': 72.5611},
    {'name': 'Sector 21, Gandhinagar', 'lat': 23.2230, 'lng': 72.6492},
    {'name': 'Vesu, Surat', 'lat': 21.1418, 'lng': 72.7709},
    {'name': 'Alkapuri, Vadodara', 'lat': 22.3107, 'lng': 73.1812},
    {'name': 'Kalawad Road, Rajkot', 'lat': 22.2818, 'lng': 70.7690},
  ];

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);

    _checkWalkValidation();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  void _checkWalkValidation() {
    final warning = _service.validateTripMode(_selectedMode, _distanceKm);
    setState(() {
      _validationWarning = warning;
    });
  }

  IconData _getModeIcon(CommuteMode mode) {
    switch (mode) {
      case CommuteMode.walk:
        return Icons.directions_walk_rounded;
      case CommuteMode.bicycle:
        return Icons.directions_bike_rounded;
      case CommuteMode.publicTransit:
        return Icons.directions_bus_rounded;
      case CommuteMode.ev:
        return Icons.electric_scooter_rounded;
      case CommuteMode.petrolVehicle:
        return Icons.directions_car_rounded;
    }
  }

  String _getModeLabel(CommuteMode mode) {
    switch (mode) {
      case CommuteMode.walk:
        return 'Walk';
      case CommuteMode.bicycle:
        return 'Cycle';
      case CommuteMode.publicTransit:
        return 'Metro / Bus';
      case CommuteMode.ev:
        return 'Electric EV';
      case CommuteMode.petrolVehicle:
        return 'Petrol/Diesel';
    }
  }

  int _getRateCoins(CommuteMode mode) {
    switch (mode) {
      case CommuteMode.walk:
        return 50;
      case CommuteMode.bicycle:
        return 40;
      case CommuteMode.publicTransit:
        return 30;
      case CommuteMode.ev:
        return 15;
      case CommuteMode.petrolVehicle:
        return 0;
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pin_drop_rounded, color: Color(0xFF16A34A), size: 24),
                SizedBox(width: 8),
                Text(
                  'Set Your Home Base Location',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select your Gujarat residence coordinates for 300m departure auto-reminders:',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 16),
            ..._gujaratLocations.map((loc) {
              final isCurrent = _service.homeAddress.contains(loc['name'] as String);
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: isCurrent ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
                ),
                tileColor: isCurrent ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                leading: Icon(
                  Icons.home_rounded,
                  color: isCurrent ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                ),
                title: Text(
                  loc['name'] as String,
                  style: TextStyle(
                    color: isCurrent ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${(loc['lat'] as double).toStringAsFixed(4)}° N, ${(loc['lng'] as double).toStringAsFixed(4)}° E',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)) : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final lat = loc['lat'] as double;
                  final lng = loc['lng'] as double;
                  final name = loc['name'] as String;
                  _service.setHomeLocation(lat, lng, name);
                  _geofence.setHomeCoordinates(lat, lng, name);
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📍 Home Base set to $name!'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimatedCoins = (_distanceKm * _getRateCoins(_selectedMode)).round();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
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
              color: const Color(0xFFCBD5E1),
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
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                  ),
                  child: const Icon(
                    Icons.directions_subway_rounded,
                    color: Color(0xFF16A34A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sustainable Travel & Commute',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Auto-Departure Reminders • Mission LiFE Rewards',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                // 1. Home Base Map Coordinate Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.pin_drop_rounded, color: Color(0xFF16A34A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HOME BASE GEOFENCE',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _service.homeAddress,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showLocationPicker,
                        icon: const Icon(Icons.edit_location_alt_rounded, size: 15),
                        label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Auto-Commute Displacement Guardian Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x080284C7),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.radar_rounded, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'AUTO-DISTANCE GEOFENCE NOTIFICATIONS',
                            style: TextStyle(
                              color: Color(0xFF0284C7),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Short departure (50m-300m) checks switches. Long travel (>1.5 km) reminds to log eco transit mode.',
                        style: TextStyle(color: Color(0xFF475569), fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.heavyImpact();
                                await _geofence.simulateShortDeparture(160.0);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('⚡ Short departure notification posted (160m)! Check notification shade.'),
                                      backgroundColor: Color(0xFF16A34A),
                                    ),
                                  );
                                }
                              },
                              icon: const Text('🔌', style: TextStyle(fontSize: 13)),
                              label: const Text('Test Left Home (160m)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEF3C7),
                                foregroundColor: const Color(0xFF92400E),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.heavyImpact();
                                await _geofence.simulateLongCommute(_distanceKm);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('🚇 Long commute notification posted (${_distanceKm.toStringAsFixed(1)} km)! Check notification shade.'),
                                      backgroundColor: const Color(0xFF0284C7),
                                    ),
                                  );
                                }
                              },
                              icon: const Text('🚇', style: TextStyle(fontSize: 13)),
                              label: Text('Test Traveled (${_distanceKm.toStringAsFixed(1)}km)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE0F2FE),
                                foregroundColor: const Color(0xFF0369A1),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Distance Slider Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Trip Distance Traveled',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _distanceKm,
                        min: 0.5,
                        max: 20.0,
                        divisions: 39,
                        activeColor: const Color(0xFF16A34A),
                        inactiveColor: const Color(0xFFE2E8F0),
                        onChanged: (val) {
                          setState(() => _distanceKm = val);
                          _checkWalkValidation();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Commute Mode Selector
                const Text(
                  'CHOOSE HOW YOU TRAVELED',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CommuteMode.values.map((mode) {
                    final isSelected = _selectedMode == mode;
                    final rate = _getRateCoins(mode);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedMode = mode);
                        _checkWalkValidation();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF16A34A) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x06000000), offset: Offset(0, 2), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getModeIcon(mode),
                              size: 16,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getModeLabel(mode),
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white24 : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                rate > 0 ? '+$rate/km' : '0 🪙',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF92400E),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_validationWarning != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationWarning!,
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // 5. Submit Button
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    final coins = estimatedCoins;
                    final co2e = _distanceKm * 0.18; // ~0.18 kg CO2e saved vs petrol car
                    GameStateService.instance.recordEcoAction(
                      actionName: 'Sustainable Commute via ${_getModeLabel(_selectedMode)}',
                      co2Saved: co2e,
                      coinsAwarded: coins,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 Logged ${_distanceKm.toStringAsFixed(1)} km via ${_getModeLabel(_selectedMode)}! Earned +$coins 🪙 & cut ${co2e.toStringAsFixed(2)} kg CO₂e!'),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Log Verified Trip (+$estimatedCoins 🪙)',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
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
  }
}
