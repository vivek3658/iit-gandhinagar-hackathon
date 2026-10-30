import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';
import '../../services/notification_service.dart';
import '../appliances/appliance_registry_sheet.dart';
import '../commute/commute_travel_sheet.dart';
import '../onboarding/energy_setup_sheet.dart';
import '../water/water_conservation_sheet.dart';

class UserSettingsSheet extends StatefulWidget {
  final Function(String title, String message, int coins, double co2)? onTriggerNudge;

  const UserSettingsSheet({
    super.key,
    this.onTriggerNudge,
  });

  @override
  State<UserSettingsSheet> createState() => _UserSettingsSheetState();
}

class _UserSettingsSheetState extends State<UserSettingsSheet> {
  final GameStateService _state = GameStateService.instance;

  Future<void> _selectSleepTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _state.sleepTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF22C55E),
              onPrimary: Colors.white,
              surface: Color(0xFF14241B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _state.setSleepTime(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0D2116),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),

          // Header
          const Row(
            children: [
              Text('⚙️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Citizen Settings & Nudges',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Mission LiFE Behavioral Automation',
                      style: TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              children: [
                // Section 1: Ambient Behavioral Triggers (BEHAVIORAL_NUDGES.md)
                _buildSectionHeader('AMBIENT BEHAVIORAL TRIGGERS'),
                const SizedBox(height: 8),

                // 1. Charger Unplug Reminder
                _buildCard([
                  Row(
                    children: [
                      const Text('🔌', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Charger Unplug Reminder',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              "Alerts when phone unplugged: 'Don't forget to turn off wall charger socket!'",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _state.enableChargerReminder,
                        activeThumbColor: const Color(0xFF22C55E),
                        onChanged: (val) {
                          setState(() => _state.setEnableChargerReminder(val));
                        },
                      ),
                    ],
                  ),
                  if (_state.enableChargerReminder) ...[
                    const Divider(color: Colors.white12, height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            NotificationService.instance.triggerChargerUnplugNudge();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔔 Physical Charger Unplug Notification sent to Android Notification Shade!'),
                                backgroundColor: Color(0xFF1B6B44),
                              ),
                            );
                          },
                          icon: const Icon(Icons.power_off_rounded, size: 14),
                          label: const Text('Test Charger Unplug Pop-up'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF86EFAC),
                            side: const BorderSide(color: Color(0xFF22C55E)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            NotificationService.instance.triggerLearningNotification('phantom');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('💡 Phantom Vampire Alert sent to Android Shade!'),
                                backgroundColor: Color(0xFF1B6B44),
                              ),
                            );
                          },
                          icon: const Icon(Icons.lightbulb_rounded, size: 14),
                          label: const Text('💡 Vampire Alert'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFDE68A),
                            side: const BorderSide(color: Color(0xFFFBBF24)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            NotificationService.instance.triggerLearningNotification('solar');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('☀️ Solar Peak Window Alert sent to Android Shade!'),
                                backgroundColor: Color(0xFF1B6B44),
                              ),
                            );
                          },
                          icon: const Icon(Icons.solar_power_rounded, size: 14),
                          label: const Text('☀️ Solar Alert'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF93C5FD),
                            side: const BorderSide(color: Color(0xFF60A5FA)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ]),
                const SizedBox(height: 12),

                // 2. Bedtime Device Shutdown Reminder
                _buildCard([
                  Row(
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bedtime Device Sweep',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Reminds you 15 min prior to sleep to turn off AC sleep timer & gadgets',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _state.enableSleepReminder,
                        activeThumbColor: const Color(0xFF22C55E),
                        onChanged: (val) {
                          setState(() => _state.setEnableSleepReminder(val));
                        },
                      ),
                    ],
                  ),
                  if (_state.enableSleepReminder) ...[
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Bedtime:',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              'Remind at: ${_state.sleepReminderTime.format(context)}',
                              style: const TextStyle(
                                color: Color(0xFF86EFAC),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _selectSleepTime(context),
                          icon: const Icon(Icons.access_time, size: 15),
                          label: Text(_state.sleepTime.format(context)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B6B44),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                            widget.onTriggerNudge?.call(
                              '🌙 Bedtime Device Sweep (15 min reminder)',
                              'Time for the bedtime check! Set AC timer to 3 hrs and turn off unnecessary chargers and appliances.',
                              25,
                              1.2,
                            );
                          },
                          icon: const Icon(Icons.bedtime, size: 14),
                          label: const Text('Simulate Bedtime Alert'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF86EFAC),
                            side: const BorderSide(color: Color(0xFF22C55E)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ]),
                const SizedBox(height: 20),

                // Section 2: Sustainability, Energy & Resource Conservation Domains
                _buildSectionHeader('MISSION LiFE PILLARS & IOT'),
                const SizedBox(height: 8),
                _buildCard([
                  _buildDomainTile(
                    icon: '⚡',
                    title: 'Electricity & Rooftop Solar',
                    subtitle: '${_state.electricityProvider} • ${_state.hasSolar ? "${_state.solarCapacityKw} kW Solar" : "No Solar"}',
                    onTap: () {
                      Navigator.pop(context);
                      EnergySetupSheet.show(context);
                    },
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  _buildDomainTile(
                    icon: '📱',
                    title: 'Electronics & IoT Appliance Registry',
                    subtitle: 'Smart & Dumb Devices • BLE / Wi-Fi / IR • Offline Sync',
                    onTap: () {
                      Navigator.pop(context);
                      ApplianceRegistrySheet.show(context);
                    },
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  _buildDomainTile(
                    icon: '🚴',
                    title: 'Sustainable Commute & Vehicle Garage',
                    subtitle: 'Walk (max 3 km) • Cycle • EV • Public Transit • Garage',
                    onTap: () {
                      Navigator.pop(context);
                      CommuteTravelSheet.show(context);
                    },
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  _buildDomainTile(
                    icon: '💧',
                    title: 'Water Conservation & Quests',
                    subtitle: 'Timed 6-8 AM vs 24x7 Paid • Overflow & RO Reject Saves',
                    onTap: () {
                      Navigator.pop(context);
                      WaterConservationSheet.show(context);
                    },
                  ),
                ]),
                const SizedBox(height: 20),

                // Section 3: Mascot Companion Behavior
                _buildSectionHeader('MASCOT BEHAVIOR SETTINGS'),
                const SizedBox(height: 8),
                _buildCard([
                  const Text(
                    'Personality & Tone:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Encouraging',
                      'Coach',
                      'Zen Guardian',
                    ].map((tone) {
                      final isSelected = _state.mascotBehaviorTone == tone;
                      return ChoiceChip(
                        label: Text(tone),
                        selected: isSelected,
                        selectedColor: const Color(0xFF22C55E),
                        backgroundColor: const Color(0xFF14241B),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) {
                            HapticFeedback.selectionClick();
                            setState(() => _state.setMascotBehaviorTone(tone));
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chirps & Sound Effects',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      Switch(
                        value: _state.soundEnabled,
                        activeThumbColor: const Color(0xFF22C55E),
                        onChanged: (val) {
                          setState(() => _state.setSoundEnabled(val));
                        },
                      ),
                    ],
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF86EFAC),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13281E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDomainTile({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }
}
