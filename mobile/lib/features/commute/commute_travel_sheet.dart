import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:urja/services/commute_travel_service.dart';

/// Modal bottom sheet for logging sustainable travel commutes,
/// managing user vehicle garage, and validating walk limits.
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
  double _distanceKm = 2.4;
  CommuteMode _selectedMode = CommuteMode.walk;
  String? _selectedVehicleName;
  String? _validationWarning;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    if (_service.vehicles.isNotEmpty) {
      _selectedVehicleName = _service.vehicles.first.name;
    }
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
        return 'Public Bus/Metro';
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

  @override
  Widget build(BuildContext context) {
    final garage = _service.vehicles;
    final tripHistory = _service.tripHistory;
    final estimatedCoins = (_distanceKm * _getRateCoins(_selectedMode)).round();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF091F13),
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
                    color: const Color(0xFF1B6B44).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: Color(0xFF34D399),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Travel & Commute Logger',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF86EFAC)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _service.homeAddress,
                              style: const TextStyle(
                                color: Color(0xFF86EFAC),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                // Distance Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3120),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
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
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Color(0xFF4ADE80),
                                fontWeight: FontWeight.bold,
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
                        activeColor: const Color(0xFF22C55E),
                        inactiveColor: Colors.white12,
                        onChanged: (val) {
                          setState(() {
                            _distanceKm = val;
                          });
                          _checkWalkValidation();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Commute Mode Selector
                const Text(
                  'Choose How You Traveled',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CommuteMode.values.map((mode) {
                    final isSelected = _selectedMode == mode;
                    final rate = _getRateCoins(mode);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedMode = mode;
                        });
                        _checkWalkValidation();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF0F3120),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4ADE80)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getModeIcon(mode),
                              size: 16,
                              color: isSelected ? Colors.black : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getModeLabel(mode),
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black12
                                    : const Color(0xFF1B6B44).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+$rate 🪙/km',
                                style: TextStyle(
                                  color: isSelected ? Colors.black87 : const Color(0xFF86EFAC),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Walk Limit Warning
                if (_validationWarning != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF87171), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationWarning!,
                            style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Multi-Vehicle Selector
                if (_selectedMode == CommuteMode.ev || _selectedMode == CommuteMode.petrolVehicle) ...[
                  const Text(
                    'Select Vehicle from Garage',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
                        value: _selectedVehicleName,
                        dropdownColor: const Color(0xFF0F3120),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                        items: garage.map((v) {
                          return DropdownMenuItem<String>(
                            value: v.name,
                            child: Row(
                              children: [
                                Icon(
                                  v.type.name.contains('ev')
                                      ? Icons.electric_scooter_rounded
                                      : Icons.two_wheeler_rounded,
                                  color: v.type.name.contains('ev')
                                      ? const Color(0xFF34D399)
                                      : Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  v.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                const Spacer(),
                                Text(
                                  v.efficiencyText,
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedVehicleName = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: _validationWarning != null
                      ? null
                      : () {
                          HapticFeedback.heavyImpact();
                          final success = _service.logCommuteTrip(
                            distanceKm: _distanceKm,
                            mode: _selectedMode,
                            vehicleName: _selectedVehicleName,
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 Commute Logged! Earned +$estimatedCoins 🪙 and prevented CO2e!'),
                                backgroundColor: const Color(0xFF1B6B44),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Log Commute (+ $estimatedCoins 🪙)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),

                const SizedBox(height: 24),

                // Trip History
                if (tripHistory.isNotEmpty) ...[
                  const Text(
                    'Recent Eco Journeys',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...tripHistory.take(4).map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(_getModeIcon(t.mode), color: const Color(0xFF86EFAC), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_getModeLabel(t.mode)} • ${t.distanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            Text(
                              '+${t.coinsEarned} 🪙',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
