import 'package:flutter/material.dart';

import '../../constants/urja_theme.dart';
import '../../services/device_registry_service.dart';

class RegisteredDevicesScreen extends StatefulWidget {
  const RegisteredDevicesScreen({super.key});

  @override
  State<RegisteredDevicesScreen> createState() =>
      _RegisteredDevicesScreenState();
}

class _RegisteredDevicesScreenState extends State<RegisteredDevicesScreen> {
  final _service = DeviceRegistryService.instance;
  List<RegisteredHouseholdDevice> _devices = [];
  bool _loading = true;
  String? _error;

  static const _categories = <String, String>{
    'ac': 'Air conditioner',
    'fan': 'Fan',
    'refrigerator': 'Refrigerator',
    'geyser': 'Water heater',
    'pump': 'Water pump',
    'tv': 'Television',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await _service.getDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _message(error);
        _loading = false;
      });
    }
  }

  String _message(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Exception|StateError|HttpException): '),
    '',
  );

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_message(error))));
  }

  Future<void> _registerDevice() async {
    final name = TextEditingController();
    final ratedPower = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var category = 'ac';
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Register a household device',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: UrjaTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add a device you identified. URJA does not scan your network or control appliances.',
                      style: TextStyle(color: UrjaTheme.muted, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: name,
                      maxLength: 64,
                      decoration: const InputDecoration(
                        labelText: 'Device name',
                        hintText: 'e.g. Living room AC',
                      ),
                      validator: (value) {
                        final length = value?.trim().length ?? 0;
                        if (length < 2) return 'Enter at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setModalState(() => category = value);
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: ratedPower,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Rated power (optional)',
                        suffixText: 'W',
                        helperText:
                            'Used only to estimate energy from your runtime log.',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final watts = double.tryParse(text);
                        if (watts == null || watts < 1 || watts > 20000) {
                          return 'Enter a value between 1 and 20,000 W';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => saving = true);
                                try {
                                  await _service.registerDevice(
                                    name: name.text,
                                    category: category,
                                    ratedPowerW: ratedPower.text.trim().isEmpty
                                        ? null
                                        : double.parse(ratedPower.text.trim()),
                                  );
                                  if (!mounted || !sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                  await _load();
                                } catch (error) {
                                  if (!mounted) return;
                                  if (!sheetContext.mounted) return;
                                  setModalState(() => saving = false);
                                  _showError(error);
                                }
                              },
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save device'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    name.dispose();
    ratedPower.dispose();
  }

  Future<void> _logRuntime(RegisteredHouseholdDevice device) async {
    final hours = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Log today’s runtime',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: UrjaTheme.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.name,
                    style: const TextStyle(color: UrjaTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: hours,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Hours used today',
                      suffixText: 'hours',
                    ),
                    validator: (value) {
                      final valueAsNumber = double.tryParse(value ?? '');
                      if (valueAsNumber == null ||
                          valueAsNumber < 0.1 ||
                          valueAsNumber > 24) {
                        return 'Enter a value from 0.1 to 24 hours';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Runtime is self-reported. Energy is estimated only when rated power is available; this does not measure CO₂e.',
                    style: TextStyle(
                      color: UrjaTheme.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => saving = true);
                              try {
                                final result = await _service.logRuntime(
                                  deviceId: device.id,
                                  operatingHours: double.parse(
                                    hours.text.trim(),
                                  ),
                                  date: DateTime.now(),
                                );
                                if (!mounted) return;
                                if (!sheetContext.mounted) return;
                                Navigator.pop(sheetContext);
                                await _load();
                                if (!mounted) return;
                                final energy = result.energyConsumedKwh;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      energy == null
                                          ? 'Runtime saved. No energy estimate is available for this device.'
                                          : 'Runtime saved · ${energy.toStringAsFixed(2)} kWh estimated.',
                                    ),
                                  ),
                                );
                              } catch (error) {
                                if (!sheetContext.mounted) return;
                                setModalState(() => saving = false);
                                _showError(error);
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save runtime'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    hours.dispose();
  }

  Future<void> _removeDevice(RegisteredHouseholdDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove device?'),
        content: Text('Remove ${device.name} and its registry entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.removeDevice(device.id);
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: UrjaTheme.canvas,
    appBar: AppBar(
      title: const Text('Household devices'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _registerDevice,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add device'),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      color: UrjaTheme.leaf,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _introCard(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your devices',
                  style: TextStyle(
                    color: UrjaTheme.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${_devices.length} registered',
                style: const TextStyle(
                  color: UrjaTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading && _devices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _devices.isEmpty)
            _statusCard(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load devices',
              message: _error!,
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            )
          else if (_devices.isEmpty)
            _statusCard(
              icon: Icons.devices_other_rounded,
              title: 'No devices registered',
              message:
                  'Add a device to keep its runtime logs with your account.',
            )
          else
            ..._devices.map(
              (device) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _deviceCard(device),
              ),
            ),
          if (_error != null && _devices.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Refresh failed: $_error',
              style: const TextStyle(color: Color(0xFFB42318), fontSize: 12),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _introCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: UrjaTheme.mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: UrjaTheme.forest),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Devices are registered with your confirmation. Runtime logs are self-reported, and energy figures are estimates—not live meter readings.',
            style: TextStyle(
              color: UrjaTheme.forest,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _deviceCard(RegisteredHouseholdDevice device) {
    final lastLogged = device.lastLoggedHours;
    final energy = device.lastEnergyKwh;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: UrjaTheme.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _categoryIcon(device.category),
                    color: UrjaTheme.forest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          color: UrjaTheme.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_categories[device.category] ?? 'Other'} · ${device.discoveryMethod.toLowerCase()}',
                        style: const TextStyle(
                          color: UrjaTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeDevice(device),
                  tooltip: 'Remove device',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: UrjaTheme.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: UrjaTheme.canvas,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                lastLogged == null
                    ? 'No runtime log yet'
                    : 'Last log · ${lastLogged.toStringAsFixed(1)} h'
                          '${device.lastLogDate == null ? '' : ' · ${device.lastLogDate}'}'
                          '${energy == null ? '' : ' · ${energy.toStringAsFixed(2)} kWh estimated'}',
                style: const TextStyle(
                  color: UrjaTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logRuntime(device),
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('Log today’s runtime'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: UrjaTheme.leaf, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: UrjaTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            style: const TextStyle(
              color: UrjaTheme.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (action != null)
            Align(alignment: Alignment.centerRight, child: action),
        ],
      ),
    ),
  );

  IconData _categoryIcon(String category) => switch (category) {
    'ac' => Icons.ac_unit_rounded,
    'fan' => Icons.air_rounded,
    'refrigerator' => Icons.kitchen_rounded,
    'geyser' => Icons.water_drop_outlined,
    'pump' => Icons.water_rounded,
    'tv' => Icons.tv_rounded,
    _ => Icons.devices_other_rounded,
  };
}
