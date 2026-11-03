import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/citizen_api.dart';
import '../../services/device_discovery.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _readings = [];
  String? _deviceError;
  String? _readingError;
  bool _loading = true;
  bool _scanning = false;
  String? _workingDevice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final api = CitizenApi.instance;
    final results = await Future.wait<Object>([
      _capture(api.getRegisteredDevices()),
      _capture(api.getReadings()),
    ]);
    if (!mounted) return;
    setState(() {
      _deviceError = _assignList(results[0], (value) => _devices = value);
      _readingError = _assignList(results[1], (value) => _readings = value);
      _loading = false;
    });
  }

  Future<Object> _capture(Future<List<Map<String, dynamic>>> task) async {
    try {
      return await task;
    } catch (error) {
      return error;
    }
  }

  String? _assignList(
    Object result,
    void Function(List<Map<String, dynamic>>) assign,
  ) {
    if (result is List<Map<String, dynamic>>) {
      assign(result);
      return null;
    }
    return result.toString();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _deviceError = null;
    });
    try {
      final found = await DeviceDiscovery.instance.scan();
      if (!mounted) return;
      if (found.isEmpty) {
        _toast(
          'No compatible Bluetooth or local network devices were found. You can still add a device manually.',
        );
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _DiscoverySheet(
          devices: found,
          onChoose: (device) {
            Navigator.pop(context);
            _addDevice(device);
          },
        ),
      );
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _deviceError = error.message ?? error.code);
      }
    } catch (error) {
      if (mounted) setState(() => _deviceError = error.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _addManually() => _addDevice(null);

  Future<void> _addDevice(Map<String, dynamic>? discovery) async {
    final details = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RegisterDeviceDialog(discovery: discovery),
    );
    if (details == null) return;
    try {
      await CitizenApi.instance.registerDevice(
        name: details['name'] as String,
        category: details['category'] as String,
        discoveryMethod: details['discoveryMethod'] as String,
        ratedPowerW: details['ratedPowerW'] as double?,
      );
      await _load();
      if (mounted) _toast('Device added to your home.');
    } catch (error) {
      if (mounted) setState(() => _deviceError = error.toString());
    }
  }

  Future<void> _logRuntime(Map<String, dynamic> device) async {
    final id = device['id'];
    if (id is! String) return;
    final hours = await showDialog<double>(
      context: context,
      builder: (context) => const _RuntimeDialog(),
    );
    if (hours == null) return;
    setState(() => _workingDevice = id);
    try {
      final result = await CitizenApi.instance.logRuntime(
        deviceId: id,
        hours: hours,
      );
      await _load();
      if (!mounted) return;
      final energy = result['energyConsumedKwh'];
      _toast(
        energy is num
            ? '${energy.toStringAsFixed(2)} kWh estimated from your rated power and runtime.'
            : 'Runtime saved. Add the device’s rated watts for an energy estimate.',
      );
    } catch (error) {
      if (mounted) setState(() => _deviceError = error.toString());
    } finally {
      if (mounted) setState(() => _workingDevice = null);
    }
  }

  Future<void> _removeDevice(Map<String, dynamic> device) async {
    final id = device['id'];
    if (id is! String) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this device?'),
        content: const Text('Its saved runtime history will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
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
      await CitizenApi.instance.removeDevice(id);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _deviceError = error.toString());
    }
  }

  Future<void> _addReading() async {
    final reading = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _ReadingDialog(),
    );
    if (reading == null) return;
    try {
      await CitizenApi.instance.addReading(
        utility: reading['utility'] as String,
        value: reading['value'] as double,
        unit: reading['unit'] as String,
        periodStart: reading['periodStart'] as DateTime,
        periodEnd: reading['periodEnd'] as DateTime,
      );
      await _load();
      if (mounted) _toast('Reading saved as user-entered data.');
    } catch (error) {
      if (mounted) setState(() => _readingError = error.toString());
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Track your home'),
      backgroundColor: UrjaColors.canvas,
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(19, 8, 19, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: UrjaColors.sky,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined, color: UrjaColors.forest),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Discovery is started by you. Nearby device IDs and addresses stay on this phone; only devices you confirm are saved to your account.',
                    style: TextStyle(
                      color: UrjaColors.ink,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          _SectionHeading(
            title: 'Household devices',
            subtitle: 'Discover nearby devices or add one yourself.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _scanning ? null : _scan,
                  icon: _scanning
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.radar_rounded),
                  label: Text(
                    _scanning ? 'Scanning nearby…' : 'Discover devices',
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.filledTonal(
                onPressed: _scanning ? null : _addManually,
                tooltip: 'Add device manually',
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  fixedSize: const Size(54, 54),
                  backgroundColor: UrjaColors.mint,
                  foregroundColor: UrjaColors.forest,
                ),
              ),
            ],
          ),
          if (_deviceError != null) ...[
            const SizedBox(height: 10),
            _ErrorText(message: _deviceError!),
          ],
          const SizedBox(height: 12),
          if (_loading && _devices.isEmpty)
            const _LoadingRow()
          else if (_devices.isEmpty)
            const _EmptyPanel(
              icon: Icons.sensors_outlined,
              title: 'Your home starts here',
              message:
                  'Add an appliance to log daily runtime and see a clearly labeled energy estimate.',
            )
          else
            for (final device in _devices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DeviceCard(
                  device: device,
                  busy: _workingDevice == device['id'],
                  onLog: () => _logRuntime(device),
                  onRemove: () => _removeDevice(device),
                ),
              ),
          const SizedBox(height: 18),
          const _SectionHeading(
            title: 'Utility readings',
            subtitle: 'Enter the values from your bill or meter display.',
          ),
          const SizedBox(height: 11),
          FilledButton.tonalIcon(
            onPressed: _addReading,
            icon: const Icon(Icons.add_chart_rounded),
            label: const Text('Add a utility reading'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(49),
              backgroundColor: UrjaColors.mint,
              foregroundColor: UrjaColors.forest,
            ),
          ),
          if (_readingError != null) ...[
            const SizedBox(height: 10),
            _ErrorText(message: _readingError!),
          ],
          const SizedBox(height: 10),
          if (_loading && _readings.isEmpty)
            const _LoadingRow()
          else if (_readings.isEmpty)
            const _EmptyPanel(
              icon: Icons.receipt_long_outlined,
              title: 'No readings yet',
              message:
                  'Your impact view will use readings you choose to enter.',
            )
          else
            for (final reading in _readings.take(5))
              _ReadingCard(reading: reading),
          const SizedBox(height: 12),
          const Text(
            'Runtime-derived energy is an estimate based on rated power. Device discovery does not mean the appliance reports its live power state.',
            style: TextStyle(
              color: UrjaColors.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: UrjaColors.muted, fontSize: 12),
      ),
    ],
  );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.busy,
    required this.onLog,
    required this.onRemove,
  });

  final Map<String, dynamic> device;
  final bool busy;
  final VoidCallback onLog;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final method = device['discoveryMethod'] as String? ?? 'MANUAL';
    final watts = device['ratedPowerW'];
    final lastHours = device['lastLoggedHours'];
    final lastKwh = device['lastEnergyKwh'];
    final date = device['lastLogDate'] as String?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: UrjaColors.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _deviceIcon(device['category'] as String?),
                color: UrjaColors.forest,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device['name'] as String? ?? 'Home device',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${_methodName(method)}${watts is num ? ' · ${watts.toStringAsFixed(0)} W' : ''}',
                    style: const TextStyle(
                      color: UrjaColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  if (lastHours is num)
                    Text(
                      'Last log: ${lastHours.toStringAsFixed(1)} h${lastKwh is num ? ' · ${lastKwh.toStringAsFixed(2)} kWh est.' : ''}${date == null ? '' : ' · $date'}',
                      style: const TextStyle(
                        color: UrjaColors.forest,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: busy ? null : onLog,
              tooltip: 'Log today’s runtime',
              icon: busy
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.timer_outlined),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') onRemove();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'remove', child: Text('Remove device')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _deviceIcon(String? category) => switch (category) {
    'ac' => Icons.ac_unit_rounded,
    'fan' => Icons.toys_rounded,
    'refrigerator' => Icons.kitchen_rounded,
    'geyser' => Icons.hot_tub_rounded,
    'pump' => Icons.water_drop_rounded,
    'tv' => Icons.tv_rounded,
    _ => Icons.electrical_services_rounded,
  };

  String _methodName(String value) => switch (value) {
    'BLE' => 'Bluetooth discovered',
    'MDNS' => 'Local network service',
    _ => 'Added manually',
  };
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.reading});

  final Map<String, dynamic> reading;

  @override
  Widget build(BuildContext context) {
    final utility = reading['utility'] as String? ?? 'UTILITY';
    final unit = reading['unit'] as String? ?? '';
    final value = reading['value'];
    final periodStart = reading['periodStart'] as String? ?? '';
    final periodEnd = reading['periodEnd'] as String? ?? '';
    return Card(
      child: ListTile(
        leading: Icon(
          utility == 'ELECTRICITY'
              ? Icons.bolt_rounded
              : utility == 'WATER'
              ? Icons.water_drop_rounded
              : Icons.local_fire_department_rounded,
          color: UrjaColors.forest,
        ),
        title: Text(
          '${utility[0]}${utility.substring(1).toLowerCase()}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('$periodStart — $periodEnd · User-entered'),
        trailing: Text(
          '${value is num ? value.toStringAsFixed(1) : '—'} $unit',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _DiscoverySheet extends StatelessWidget {
  const _DiscoverySheet({required this.devices, required this.onChoose});

  final List<Map<String, dynamic>> devices;
  final ValueChanged<Map<String, dynamic>> onChoose;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: UrjaColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 38,
              decoration: BoxDecoration(
                color: UrjaColors.line,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'Nearby devices',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a device you own. No address or scan identifier is uploaded.',
            style: TextStyle(color: UrjaColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 11),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: devices.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: UrjaColors.line),
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: UrjaColors.mint,
                    child: Icon(
                      Icons.sensors_rounded,
                      color: UrjaColors.forest,
                    ),
                  ),
                  title: Text(device['name'] as String? ?? 'Device'),
                  subtitle: Text(
                    device['method'] == 'BLE'
                        ? 'Bluetooth LE advertisement'
                        : 'Local network service advertisement',
                  ),
                  trailing: const Icon(Icons.add_circle_outline_rounded),
                  onTap: () => onChoose(device),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _RegisterDeviceDialog extends StatefulWidget {
  const _RegisterDeviceDialog({this.discovery});

  final Map<String, dynamic>? discovery;

  @override
  State<_RegisterDeviceDialog> createState() => _RegisterDeviceDialogState();
}

class _RegisterDeviceDialogState extends State<_RegisterDeviceDialog> {
  late final _nameController = TextEditingController(
    text: widget.discovery?['name'] as String? ?? '',
  );
  final _wattsController = TextEditingController();
  String _category = 'other';
  bool _invalid = false;

  @override
  void dispose() {
    _nameController.dispose();
    _wattsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.discovery == null ? 'Add a device' : 'Confirm device'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name at home'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Device type'),
            items:
                const [
                      ('other', 'Other'),
                      ('ac', 'Air conditioner'),
                      ('fan', 'Fan'),
                      ('refrigerator', 'Refrigerator'),
                      ('geyser', 'Water heater'),
                      ('pump', 'Water pump'),
                      ('tv', 'Television'),
                    ]
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.$1,
                        child: Text(item.$2),
                      ),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _category = value ?? 'other'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wattsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Rated power in watts (optional)',
              helperText: 'Read it from the appliance label.',
            ),
          ),
          if (_invalid)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Enter a name and a valid rated wattage.',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final name = _nameController.text.trim();
          final wattsText = _wattsController.text.trim();
          final watts = wattsText.isEmpty ? null : double.tryParse(wattsText);
          if (name.length < 2 ||
              (wattsText.isNotEmpty && (watts == null || watts <= 0))) {
            setState(() => _invalid = true);
            return;
          }
          Navigator.pop(context, {
            'name': name,
            'category': _category,
            'discoveryMethod':
                widget.discovery?['method'] as String? ?? 'MANUAL',
            if (watts != null) 'ratedPowerW': watts,
          });
        },
        child: const Text('Save device'),
      ),
    ],
  );
}

class _RuntimeDialog extends StatefulWidget {
  const _RuntimeDialog();

  @override
  State<_RuntimeDialog> createState() => _RuntimeDialogState();
}

class _RuntimeDialogState extends State<_RuntimeDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Log today’s runtime'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter the number of hours this appliance ran today. This is your report, not a live sensor reading.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Hours (0.1–24)',
            errorText: _error,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final value = double.tryParse(_controller.text);
          if (value == null || value < .1 || value > 24) {
            setState(() => _error = 'Enter a value from 0.1 to 24.');
            return;
          }
          Navigator.pop(context, value);
        },
        child: const Text('Save runtime'),
      ),
    ],
  );
}

class _ReadingDialog extends StatefulWidget {
  const _ReadingDialog();

  @override
  State<_ReadingDialog> createState() => _ReadingDialogState();
}

class _ReadingDialogState extends State<_ReadingDialog> {
  final _valueController = TextEditingController();
  String _utility = 'ELECTRICITY';
  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month - 1, today.day);
    final unit = switch (_utility) {
      'ELECTRICITY' => 'kWh',
      'WATER' => 'kL',
      _ => 'kg',
    };
    return AlertDialog(
      title: const Text('Add a utility reading'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _utility,
            decoration: const InputDecoration(labelText: 'Utility'),
            items: const [
              DropdownMenuItem(
                value: 'ELECTRICITY',
                child: Text('Electricity'),
              ),
              DropdownMenuItem(value: 'WATER', child: Text('Water')),
              DropdownMenuItem(value: 'GAS', child: Text('Gas')),
            ],
            onChanged: (value) =>
                setState(() => _utility = value ?? 'ELECTRICITY'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Usage ($unit)',
              helperText: 'Previous 30 days · adjust by the bill period',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(_valueController.text);
            if (value == null || value <= 0) {
              setState(() => _error = 'Enter a value greater than zero.');
              return;
            }
            Navigator.pop(context, {
              'utility': _utility,
              'value': value,
              'unit': unit,
              'periodStart': start,
              'periodEnd': today,
            });
          },
          child: const Text('Save reading'),
        ),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(18),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, size: 30, color: UrjaColors.leaf),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: UrjaColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) =>
      Text(message, style: const TextStyle(color: Colors.red, fontSize: 12));
}
