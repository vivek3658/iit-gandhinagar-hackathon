import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:urja/services/appliance_registry_service.dart';

/// Modal bottom sheet presenting smart household appliances with inbuilt Wi-Fi / BLE,
/// live wattage consumption, standby vampire power tracking, and state controls.
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
      case 'geyser':
        return Icons.water_drop_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'ac':
        return const Color(0xFF0284C7); // Sky 600
      case 'fridge':
        return const Color(0xFF0D9488); // Teal 600
      case 'tv':
        return const Color(0xFF7C3AED); // Violet 600
      case 'geyser':
        return const Color(0xFFEA580C); // Orange 600
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = _service.devices;
    final totalActiveWatts = _service.totalActivePowerWatts;
    final totalStandbyWatts = _service.totalStandbyVampireWatts;
    final dailyKwh = ((totalActiveWatts * 8.0) + (totalStandbyWatts * 16.0)) / 1000.0;
    final dailyCostRupees = (dailyKwh * 6.5).toStringAsFixed(1);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                    Icons.wifi_tethering_rounded,
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
                        'Smart Connected Appliances',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Inbuilt Wi-Fi & BLE Live Energy Tracking',
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

          const SizedBox(height: 14),

          // Power Dashboard Banner (Modern White/Slate Card)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricCol('ACTIVE LOAD', '${totalActiveWatts.toInt()} W', const Color(0xFF16A34A), '⚡ Running'),
                      Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                      _buildMetricCol('VAMPIRE STANDBY', '${totalStandbyWatts.toInt()} W', const Color(0xFFD97706), '🔌 Phantom'),
                      Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                      _buildMetricCol('EST. DAILY COST', '₹$dailyCostRupees', const Color(0xFF2563EB), 'Discom Rate'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ONLINE SMART APPLIANCES',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${devices.length} Devices Monitored',
                    style: const TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Device Cards List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final d = devices[index];
                return _buildApplianceCard(d);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color valColor, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valColor,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildApplianceCard(ApplianceDevice d) {
    final catColor = _getCategoryColor(d.category);
    final isRunning = d.state == ApplianceState.running;
    final isStandby = d.state == ApplianceState.standby;

    String currentWattText;
    Color statusBadgeBg;
    Color statusBadgeText;
    String statusLabel;

    if (isRunning) {
      currentWattText = '${d.activePowerWatts.toInt()} W active';
      statusBadgeBg = const Color(0xFFDCFCE7);
      statusBadgeText = const Color(0xFF15803D);
      statusLabel = 'Running ⚡';
    } else if (isStandby) {
      currentWattText = '${d.standbyPowerWatts.toInt()} W phantom';
      statusBadgeBg = const Color(0xFFFEF3C7);
      statusBadgeText = const Color(0xFF92400E);
      statusLabel = 'Standby 🔌';
    } else {
      currentWattText = '0 W (Off)';
      statusBadgeBg = const Color(0xFFF1F5F9);
      statusBadgeText = const Color(0xFF64748B);
      statusLabel = 'Off ⚪';
    }

    final techLabel = d.techType == ApplianceTechType.wifiMdns ? 'Inbuilt Wi-Fi' : 'Inbuilt BLE';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRunning ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: isRunning ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: catColor.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  _getCategoryIcon(d.category),
                  color: catColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            d.name,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            techLabel,
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentWattText,
                          style: TextStyle(
                            color: isStandby ? const Color(0xFFD97706) : (isRunning ? const Color(0xFF16A34A) : const Color(0xFF94A3B8)),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
                  color: statusBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusBadgeText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-Way Segmented Control
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildStateSegment(d, ApplianceState.running, '⚡ Running', const Color(0xFF16A34A)),
                _buildStateSegment(d, ApplianceState.standby, '🔌 Standby', const Color(0xFFD97706)),
                _buildStateSegment(d, ApplianceState.off, '⚪ Off', const Color(0xFF64748B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateSegment(ApplianceDevice d, ApplianceState state, String label, Color activeColor) {
    final isSelected = d.state == state;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _service.setDeviceState(d.id, state);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
