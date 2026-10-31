import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../appliances/appliance_registry_sheet.dart';
import '../auth/google_login_screen.dart';
import '../commute/commute_travel_sheet.dart';
import '../onboarding/energy_setup_sheet.dart';
import '../water/water_conservation_sheet.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final GameStateService _state = GameStateService.instance;
  final AuthService _auth = AuthService.instance;

  // Local state toggles
  bool _acHighHoursAlert = true;
  bool _geyserReheatAlert = true;
  bool _sumpOverflowAlert = true;
  double _gardenTouchSensitivity = 1.0;
  bool _pinchZoomEnabled = true;

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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF143522),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('🚪', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'Sign Out?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from UrjaVatika? Your local garden island, mascot vitality, and mission progress are safely saved.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const GoogleLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final userName = user?.name ?? 'Gujarat Eco Citizen';
    final userEmail = user?.email ?? 'citizen@gujarat.urja';
    final userWard = user?.ward ?? 'Navrangpura';
    final userDistrict = user?.district ?? 'Ahmedabad';

    return Scaffold(
      backgroundColor: const Color(0xFF0D2116), // Dark eco nature theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2116),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings & Preferences',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          // 1. Citizen Profile Card
          _buildCitizenProfileCard(
            userName: userName,
            userEmail: userEmail,
            userWard: userWard,
            userDistrict: userDistrict,
          ),
          const SizedBox(height: 20),

          // 2. Sparrow Mascot Sanctuary Settings
          _buildSectionHeader('SPARROW MASCOT SANCTUARY & BEDTIME'),
          const SizedBox(height: 10),
          _buildCard([
            _buildMascotSettingRow(),
            const Divider(color: Colors.white12, height: 20),
            _buildSwitchRow(
              icon: '🌙',
              title: 'Nest Mode Bedtime Sleep (11 PM - 6 AM)',
              subtitle: 'Sparrow dozes in its straw nest during late night hours',
              value: _state.enableNightDimming,
              onChanged: (val) {
                setState(() => _state.setEnableNightDimming(val));
              },
            ),
            const Divider(color: Colors.white12, height: 20),
            _buildSwitchRow(
              icon: '⏰',
              title: 'Bedtime Device Sweep Reminder',
              subtitle: 'Alerts 15 min before sleep to turn off AC & idle electronics',
              value: _state.enableSleepReminder,
              onChanged: (val) {
                setState(() => _state.setEnableSleepReminder(val));
              },
            ),
            if (_state.enableSleepReminder) ...[
              const Divider(color: Colors.white12, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bedtime Target:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        'Remind at: ${_state.sleepReminderTime.format(context)}',
                        style: const TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _selectSleepTime(context),
                    icon: const Icon(Icons.access_time, size: 14),
                    label: Text(_state.sleepTime.format(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6B44),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ]),
          const SizedBox(height: 20),

          // 3. 3D Floating Garden Island Settings
          _buildSectionHeader('3D FLOATING GARDEN ISLAND'),
          const SizedBox(height: 10),
          _buildCard([
            _buildSwitchRow(
              icon: '🤏',
              title: 'Two-Finger Pinch Zoom & Pan',
              subtitle: 'Smoothly zoom into placed flowers and structures',
              value: _pinchZoomEnabled,
              onChanged: (val) {
                setState(() => _pinchZoomEnabled = val);
              },
            ),
            const Divider(color: Colors.white12, height: 20),
            Row(
              children: [
                const Text('🎮', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Garden Touch Sensitivity',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Text(
                        'Adjust 3D camera pan responsiveness: ${_gardenTouchSensitivity.toStringAsFixed(1)}x',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Slider(
              value: _gardenTouchSensitivity,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              activeColor: const Color(0xFF22C55E),
              inactiveColor: Colors.white12,
              onChanged: (val) {
                setState(() => _gardenTouchSensitivity = val);
              },
            ),
          ]),
          const SizedBox(height: 20),

          // 4. Electricity DISCOM & Solar Rooftop
          _buildSectionHeader('ELECTRICITY DISCOM & SOLAR ROOFTOP'),
          const SizedBox(height: 10),
          _buildCard([
            _buildDomainTile(
              icon: '⚡',
              title: 'Electricity Utility Provider',
              subtitle: '${_state.electricityProvider} • Consumer No: GJ-AMD-40192',
              onTap: () => EnergySetupSheet.show(context),
            ),
            const Divider(color: Colors.white12, height: 16),
            _buildDomainTile(
              icon: '☀️',
              title: 'PM Surya Ghar Rooftop Solar',
              subtitle: _state.hasSolar ? '${_state.solarCapacityKw} kW Grid-Tied PV Active' : 'Configure Solar Net-Metering',
              onTap: () => EnergySetupSheet.show(context),
            ),
          ]),
          const SizedBox(height: 20),

          // 5. Water Storage, Sump & Rainwater
          _buildSectionHeader('WATER CONSERVATION & SUMP PUMP'),
          const SizedBox(height: 10),
          _buildCard([
            _buildDomainTile(
              icon: '💧',
              title: 'Municipal Water & Rainwater Harvesting',
              subtitle: 'Underground Sump + Overhead Tank • 2,000 L',
              onTap: () => WaterConservationSheet.show(context),
            ),
            const Divider(color: Colors.white12, height: 16),
            _buildSwitchRow(
              icon: '🚨',
              title: 'Sump Pump Overflow Alert',
              subtitle: 'Warns when pump runs over 45 min to prevent overflow',
              value: _sumpOverflowAlert,
              onChanged: (val) {
                setState(() => _sumpOverflowAlert = val);
              },
            ),
          ]),
          const SizedBox(height: 20),

          // 6. Smart Electronics & High-Hour Reminders
          _buildSectionHeader('ELECTRONIC APPLIANCES & HIGH-HOUR ALERTS'),
          const SizedBox(height: 10),
          _buildCard([
            _buildDomainTile(
              icon: '📱',
              title: 'Appliance Registry & Time Logs',
              subtitle: 'AC, Geyser, Refrigerator, Induction, Sump Pump',
              onTap: () => ApplianceRegistrySheet.show(context),
            ),
            const Divider(color: Colors.white12, height: 16),
            _buildSwitchRow(
              icon: '❄️',
              title: 'AC High-Hour Warning (Limit: 5 hrs/day)',
              subtitle: 'Alerts when AC runs excessively and calculates ₹ waste',
              value: _acHighHoursAlert,
              onChanged: (val) {
                setState(() => _acHighHoursAlert = val);
              },
            ),
            const Divider(color: Colors.white12, height: 16),
            _buildSwitchRow(
              icon: '🚿',
              title: 'Geyser Standby Alert (Limit: 1.5 hrs/day)',
              subtitle: 'Prevents automatic thermal reheat standing loss',
              value: _geyserReheatAlert,
              onChanged: (val) {
                setState(() => _geyserReheatAlert = val);
              },
            ),
            const Divider(color: Colors.white12, height: 16),
            _buildSwitchRow(
              icon: '🔌',
              title: 'Wall Charger Unplug Pop-up',
              subtitle: 'Triggers when phone reaches 100% or is unplugged',
              value: _state.enableChargerReminder,
              onChanged: (val) {
                setState(() => _state.setEnableChargerReminder(val));
              },
            ),
          ]),
          const SizedBox(height: 20),

          // 7. Sustainable Commute & Garage
          _buildSectionHeader('COMMUTE & MOBILITY GARAGE'),
          const SizedBox(height: 10),
          _buildCard([
            _buildDomainTile(
              icon: '🚴',
              title: 'Daily Green Commute Modes',
              subtitle: 'Walk, Cycle, EV 2-Wheeler, Ahmedabad Metro / BRTS',
              onTap: () => CommuteTravelSheet.show(context),
            ),
          ]),
          const SizedBox(height: 20),

          // 8. Audio, Haptics & Visuals
          _buildSectionHeader('AUDIO & HAPTICS'),
          const SizedBox(height: 10),
          _buildCard([
            _buildSwitchRow(
              icon: '🔊',
              title: 'Ambient Soundscape & Audio',
              subtitle: 'Chirping sanctuary birds, rustling trees, water ripples',
              value: _state.soundEnabled,
              onChanged: (val) {
                setState(() => _state.setSoundEnabled(val));
              },
            ),
            const Divider(color: Colors.white12, height: 16),
            _buildSwitchRow(
              icon: '📳',
              title: 'Tactile Haptic Feedback',
              subtitle: 'Claymorphic tactile clicks on taps, drops and actions',
              value: true,
              onChanged: (val) {
                HapticFeedback.mediumImpact();
              },
            ),
          ]),
          const SizedBox(height: 28),

          // 9. Sign Out Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF261010),
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Sign Out from Citizen Account',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'UrjaVatika v1.2.0 • Government of Gujarat Mission LiFE',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitizenProfileCard({
    required String userName,
    required String userEmail,
    required String userWard,
    required String userDistrict,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF143E26)],
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
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text('🇮🇳', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$userWard Ward, $userDistrict',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn('🪙 Urja Mudra', '${_state.coins}'),
              Container(width: 1, height: 28, color: Colors.white12),
              _buildMetricColumn('🌱 CO₂e Saved', '${_state.co2eSavedKg.toStringAsFixed(1)} kg'),
              Container(width: 1, height: 28, color: Colors.white12),
              _buildMetricColumn('🔥 LiFE Streak', '${_state.notificationHistory.length + 5}d'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFDE68A),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildMascotSettingRow() {
    return Row(
      children: [
        const Text('🕊️', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mascot Identity & Vitality',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
              Text(
                'Piku the Indian Sparrow • Level 2 Companion',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1B6B44),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '95% Vitality',
            style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF86EFAC),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF143522),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSwitchRow({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF22C55E),
          onChanged: onChanged,
        ),
      ],
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
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
