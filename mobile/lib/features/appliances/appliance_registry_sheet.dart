import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:urja/services/appliance_registry_service.dart';

/// Modal bottom sheet presenting household electronics, IoT detection (BLE, Wi-Fi, IR),
/// event-driven delta updates, and offline sync queuing.
class ApplianceRegistrySheet extends StatefulWidget {
  const ApplianceRegistrySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ApplianceRegistrySheet(),
    );
  }

  @override
  State<ApplianceRegistrySheet> createState() => _ApplianceRegistrySheetState();
}

class _ApplianceRegistrySheetState extends State<ApplianceRegistrySheet> {
  final _service = ApplianceRegistryService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'ac':
        return Icons.ac_unit_rounded;
      case 'fridge':
        return Icons.kitchen_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'washing_machine':
        return Icons.local_laundry_service_rounded;
      case 'fan':
        return Icons.mode_fan_off_rounded;
      case 'geyser':
        return Icons.water_drop_rounded;
      case 'microwave':
        return Icons.microwave_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  String _getTechBadge(ApplianceTechType type) {
    switch (type) {
      case ApplianceTechType.wifiMdns:
        return 'Wi-Fi mDNS';
      case ApplianceTechType.bleIot:
        return 'BLE IoT';
      case ApplianceTechType.irBlaster:
        return 'IR Blaster';
      case ApplianceTechType.smartPlug:
        return 'Smart Plug';
      case ApplianceTechType.manual:
        return 'Manual';
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = _service.devices;
    final isOnline = _service.isOnline;
    final offlineQueue = _service.offlineEventQueue;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1F14),
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
                    Icons.sensors_rounded,
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
                        'Electronics & IoT Registry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Smart & Dumb Devices • Event Delta Dispatch',
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

          // Power Dashboard Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF134E2E).withValues(alpha: 0.8),
                    const Color(0xFF0F3820).withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚡ Active Draw',
                          style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_service.totalActivePowerWatts.toStringAsFixed(0)} W',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🧛 Phantom Vampire',
                          style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_service.totalStandbyVampireWatts.toStringAsFixed(0)} W',
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.white12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? '🟢 Online' : '🟠 Offline',
                          style: TextStyle(
                            color: isOnline ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          offlineQueue.isEmpty
                              ? 'Synced'
                              : '${offlineQueue.length} Queued',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action row: Scan IoT devices + Network toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _service.isScanningIot
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();
                            final count = await _service.scanNearbyIotDevices();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('📡 Scan finished: Detected $count smart IoT appliances!'),
                                  backgroundColor: const Color(0xFF1B6B44),
                                ),
                              );
                            }
                          },
                    icon: _service.isScanningIot
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.radar_rounded, size: 16),
                    label: Text(
                      _service.isScanningIot ? 'Scanning...' : 'Scan IoT Devices',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _service.setOnlineStatus(!isOnline);
                    if (!isOnline) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📶 Internet restored: Flushed offline state buffer to server!'),
                          backgroundColor: Color(0xFF1B6B44),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    isOnline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                    size: 16,
                    color: isOnline ? const Color(0xFFF87171) : const Color(0xFF34D399),
                  ),
                  label: Text(
                    isOnline ? 'Test Offline' : 'Go Online',
                    style: TextStyle(
                      color: isOnline ? const Color(0xFFF87171) : const Color(0xFF34D399),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isOnline ? const Color(0xFFF87171) : const Color(0xFF34D399),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Device List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final d = devices[i];
                return _buildDeviceCard(d);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(ApplianceDevice d) {
    Color stateColor = Colors.white54;
    String stateLabel = 'OFF';
    if (d.state == ApplianceState.running) {
      stateColor = const Color(0xFF22C55E);
      stateLabel = 'RUNNING';
    } else if (d.state == ApplianceState.standby) {
      stateColor = const Color(0xFFFBBF24);
      stateLabel = 'STANDBY';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: d.state == ApplianceState.running
              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(d.category),
                  color: stateColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getTechBadge(d.techType),
                            style: const TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (d.isSmart)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Smart IoT',
                              style: TextStyle(
                                color: Color(0xFF86EFAC),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Traditional',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stateColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  stateLabel,
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Operational Controls (OFF | STANDBY | RUNNING)
          Row(
            children: [
              Expanded(
                child: Text(
                  d.state == ApplianceState.running
                      ? '⚡ ${d.activePowerWatts.toStringAsFixed(0)} W'
                      : (d.state == ApplianceState.standby
                          ? '🧛 ${d.standbyPowerWatts.toStringAsFixed(0)} W standby'
                          : '💤 0 W (No Vampire Draw)'),
                  style: TextStyle(
                    color: d.state == ApplianceState.running
                        ? const Color(0xFF86EFAC)
                        : (d.state == ApplianceState.standby
                            ? const Color(0xFFFCA5A5)
                            : Colors.white54),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Segmented controls
              _buildStateButton(d, ApplianceState.off, 'OFF'),
              const SizedBox(width: 4),
              _buildStateButton(d, ApplianceState.standby, 'STANDBY'),
              const SizedBox(width: 4),
              _buildStateButton(d, ApplianceState.running, 'ON'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateButton(ApplianceDevice d, ApplianceState targetState, String label) {
    final isSelected = d.state == targetState;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _service.updateDeviceState(d.id, targetState);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
