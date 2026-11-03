import 'package:flutter/material.dart';

import '../../constants/urja_theme.dart';
import '../../services/citizen_data_service.dart';

class CitizenRecordsScreen extends StatefulWidget {
  const CitizenRecordsScreen({
    this.initialTab = 0,
    this.openAddReading = false,
    super.key,
  });

  final int initialTab;
  final bool openAddReading;

  @override
  State<CitizenRecordsScreen> createState() => _CitizenRecordsScreenState();
}

class _CitizenRecordsScreenState extends State<CitizenRecordsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<UtilityReading> _readings = [];
  List<CitizenVehicle> _vehicles = [];
  List<CitizenTrip> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      initialIndex: widget.initialTab.clamp(0, 2),
      vsync: this,
    );
    _load();
    if (widget.openAddReading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addReading();
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        CitizenDataService.instance.getReadings(),
        CitizenDataService.instance.getVehicles(),
        CitizenDataService.instance.getTrips(),
      ]);
      if (!mounted) return;
      setState(() {
        _readings = values[0] as List<UtilityReading>;
        _vehicles = values[1] as List<CitizenVehicle>;
        _trips = values[2] as List<CitizenTrip>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _addReading() async {
    final controller = TextEditingController();
    var utility = 'ELECTRICITY';
    var unit = 'kWh';
    var periodStart = DateTime.now().subtract(const Duration(days: 30));
    var periodEnd = DateTime.now();
    var saving = false;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => _FormSheet(
          title: 'Add a utility reading',
          subtitle:
              'This is saved as a citizen-entered record, not a live meter reading.',
          onClose: () => Navigator.pop(sheetContext),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: utility,
                  decoration: const InputDecoration(labelText: 'Utility'),
                  items: const [
                    DropdownMenuItem(
                      value: 'ELECTRICITY',
                      child: Text('Electricity'),
                    ),
                    DropdownMenuItem(value: 'WATER', child: Text('Water')),
                    DropdownMenuItem(value: 'GAS', child: Text('Gas')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() {
                      utility = value;
                      unit = switch (value) {
                        'ELECTRICITY' => 'kWh',
                        'WATER' => 'L',
                        _ => 'kg',
                      };
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Bill / meter value',
                    suffixText: unit,
                  ),
                  validator: (value) {
                    final number = double.tryParse(value ?? '');
                    if (number == null || number <= 0) {
                      return 'Enter a value greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _DateRangeSelector(
                  start: periodStart,
                  end: periodEnd,
                  onChanged: (start, end) => setModalState(() {
                    periodStart = start;
                    periodEnd = end;
                  }),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => saving = true);
                          try {
                            await CitizenDataService.instance.addReading(
                              utility: utility,
                              value: double.parse(controller.text.trim()),
                              unit: unit,
                              periodStart: periodStart,
                              periodEnd: periodEnd,
                            );
                            if (!mounted || !sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            await _load();
                          } catch (error) {
                            if (sheetContext.mounted) {
                              setModalState(() => saving = false);
                            }
                            if (mounted) _showError(error);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save reading'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _addVehicle() async {
    final label = TextEditingController();
    final make = TextEditingController();
    final model = TextEditingController();
    final registration = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var vehicleType = 'TWO_WHEELER';
    var fuelType = 'PETROL';
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => _FormSheet(
          title: 'Add a vehicle',
          subtitle:
              'Add details manually. URJA does not look up registration numbers.',
          onClose: () => Navigator.pop(sheetContext),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: label,
                  decoration: const InputDecoration(
                    labelText: 'Name this vehicle',
                    hintText: 'e.g. Family scooter',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a vehicle name'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: vehicleType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(
                            value: 'TWO_WHEELER',
                            child: Text('2-wheeler'),
                          ),
                          DropdownMenuItem(value: 'CAR', child: Text('Car')),
                          DropdownMenuItem(value: 'BUS', child: Text('Bus')),
                          DropdownMenuItem(
                            value: 'OTHER',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) => setModalState(
                          () => vehicleType = value ?? vehicleType,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: fuelType,
                        decoration: const InputDecoration(labelText: 'Fuel'),
                        items: const [
                          DropdownMenuItem(
                            value: 'PETROL',
                            child: Text('Petrol'),
                          ),
                          DropdownMenuItem(
                            value: 'DIESEL',
                            child: Text('Diesel'),
                          ),
                          DropdownMenuItem(value: 'CNG', child: Text('CNG')),
                          DropdownMenuItem(
                            value: 'ELECTRIC',
                            child: Text('Electric'),
                          ),
                          DropdownMenuItem(
                            value: 'HYBRID',
                            child: Text('Hybrid'),
                          ),
                          DropdownMenuItem(
                            value: 'OTHER',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) =>
                            setModalState(() => fuelType = value ?? fuelType),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: make,
                        decoration: const InputDecoration(
                          labelText: 'Make (optional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: model,
                        decoration: const InputDecoration(
                          labelText: 'Model (optional)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: registration,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Private label (optional)',
                    helperText: 'Not checked against government records.',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => saving = true);
                          try {
                            await CitizenDataService.instance.addVehicle({
                              'label': label.text.trim(),
                              'vehicleType': vehicleType,
                              'fuelType': fuelType,
                              if (make.text.trim().isNotEmpty)
                                'make': make.text.trim(),
                              if (model.text.trim().isNotEmpty)
                                'model': model.text.trim(),
                              if (registration.text.trim().isNotEmpty)
                                'registrationLabel': registration.text.trim(),
                            });
                            if (!mounted || !sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            await _load();
                          } catch (error) {
                            if (sheetContext.mounted) {
                              setModalState(() => saving = false);
                            }
                            if (mounted) _showError(error);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save vehicle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    label.dispose();
    make.dispose();
    model.dispose();
    registration.dispose();
  }

  Future<void> _addTrip() async {
    final distance = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var mode = 'WALK';
    var selectedVehicleId = _vehicles.isEmpty ? null : _vehicles.first.id;
    var confirmed = false;
    var saving = false;
    var startedAt = DateTime.now().subtract(const Duration(minutes: 30));
    var endedAt = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => _FormSheet(
          title: 'Log a trip',
          subtitle:
              'Enter a trip summary yourself. URJA does not collect or store your GPS route.',
          onClose: () => Navigator.pop(sheetContext),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  decoration: const InputDecoration(labelText: 'Travel mode'),
                  items: const [
                    DropdownMenuItem(value: 'WALK', child: Text('Walk')),
                    DropdownMenuItem(value: 'BICYCLE', child: Text('Bicycle')),
                    DropdownMenuItem(
                      value: 'PUBLIC_TRANSIT',
                      child: Text('Public transit'),
                    ),
                    DropdownMenuItem(
                      value: 'PRIVATE_VEHICLE',
                      child: Text('Private vehicle'),
                    ),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setModalState(() => mode = value ?? mode),
                ),
                if (mode == 'PRIVATE_VEHICLE' && _vehicles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedVehicleId,
                    decoration: const InputDecoration(labelText: 'Vehicle'),
                    items: _vehicles
                        .map(
                          (vehicle) => DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(vehicle.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setModalState(() => selectedVehicleId = value),
                  ),
                ],
                const SizedBox(height: 12),
                _TripTimeSelector(
                  startedAt: startedAt,
                  endedAt: endedAt,
                  onChanged: (start, end) => setModalState(() {
                    startedAt = start;
                    endedAt = end;
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: distance,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Distance',
                    suffixText: 'km',
                  ),
                  validator: (value) {
                    final number = double.tryParse(value ?? '');
                    if (number == null || number <= 0 || number > 2000) {
                      return 'Enter a distance between 0 and 2,000 km';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g. Home to campus',
                  ),
                ),
                CheckboxListTile(
                  value: confirmed,
                  onChanged: (value) =>
                      setModalState(() => confirmed = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I confirm these trip details',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'This is a user-confirmed summary; no emissions are calculated.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (!confirmed) {
                            _showError(
                              'Confirm the trip summary before saving.',
                            );
                            return;
                          }
                          if (!endedAt.isAfter(startedAt)) {
                            _showError(
                              'Trip end time must be after start time.',
                            );
                            return;
                          }
                          setModalState(() => saving = true);
                          try {
                            await CitizenDataService.instance.addTrip(
                              mode: mode,
                              distanceKm: double.parse(distance.text.trim()),
                              startedAt: startedAt,
                              endedAt: endedAt,
                              userConfirmed: confirmed,
                              vehicleId: mode == 'PRIVATE_VEHICLE'
                                  ? selectedVehicleId
                                  : null,
                              notes: notes.text,
                            );
                            if (!mounted || !sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            await _load();
                          } catch (error) {
                            if (sheetContext.mounted) {
                              setModalState(() => saving = false);
                            }
                            if (mounted) _showError(error);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save trip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    distance.dispose();
    notes.dispose();
  }

  Future<void> _removeVehicle(CitizenVehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove vehicle?'),
        content: Text('Remove ${vehicle.label} from your saved vehicles?'),
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
      await CitizenDataService.instance.removeVehicle(vehicle.id);
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: UrjaTheme.canvas,
    appBar: AppBar(
      title: const Text('Your records'),
      bottom: TabBar(
        controller: _tabs,
        labelColor: UrjaTheme.forest,
        unselectedLabelColor: UrjaTheme.muted,
        indicatorColor: UrjaTheme.leaf,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        tabs: const [
          Tab(text: 'Utilities'),
          Tab(text: 'Vehicles'),
          Tab(text: 'Trips'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body:
        _error != null &&
            _readings.isEmpty &&
            _vehicles.isEmpty &&
            _trips.isEmpty
        ? _ErrorState(message: _error!, onRetry: _load)
        : TabBarView(
            controller: _tabs,
            children: [_buildReadings(), _buildVehicles(), _buildTrips()],
          ),
  );

  Widget _buildReadings() => _RecordsList(
    loading: _loading && _readings.isEmpty,
    emptyTitle: 'No utility records',
    emptyMessage:
        'Add a bill or meter value for electricity, water, or gas. Each record is clearly labeled as citizen-entered.',
    onRefresh: _load,
    onAdd: _addReading,
    addLabel: 'Add reading',
    children: [
      for (final reading in _readings)
        _RecordCard(
          icon: switch (reading.utility) {
            'ELECTRICITY' => Icons.bolt_rounded,
            'WATER' => Icons.water_drop_rounded,
            _ => Icons.local_fire_department_rounded,
          },
          title: reading.utility.toLowerCase(),
          value: '${reading.value.toStringAsFixed(1)} ${reading.unit}',
          detail: '${reading.periodStart} — ${reading.periodEnd}',
          badge: 'USER ENTERED',
        ),
    ],
  );

  Widget _buildVehicles() => _RecordsList(
    loading: _loading && _vehicles.isEmpty,
    emptyTitle: 'No saved vehicles',
    emptyMessage:
        'Add your own vehicle details to use when you record a trip. Registration lookup is not available.',
    onRefresh: _load,
    onAdd: _addVehicle,
    addLabel: 'Add vehicle',
    children: [
      for (final vehicle in _vehicles)
        _RecordCard(
          icon: _vehicleIcon(vehicle.vehicleType),
          title: vehicle.label,
          value: vehicle.fuelType.replaceAll('_', ' '),
          detail:
              [
                if (vehicle.make?.isNotEmpty ?? false) vehicle.make!,
                if (vehicle.model?.isNotEmpty ?? false) vehicle.model!,
                if (vehicle.modelYear != null) '${vehicle.modelYear}',
                if (vehicle.registrationLabel?.isNotEmpty ?? false)
                  vehicle.registrationLabel!,
              ].join(' · ').isEmpty
              ? vehicle.vehicleType.replaceAll('_', ' ').toLowerCase()
              : [
                  if (vehicle.make?.isNotEmpty ?? false) vehicle.make!,
                  if (vehicle.model?.isNotEmpty ?? false) vehicle.model!,
                  if (vehicle.modelYear != null) '${vehicle.modelYear}',
                  if (vehicle.registrationLabel?.isNotEmpty ?? false)
                    vehicle.registrationLabel!,
                ].join(' · '),
          badge: 'SAVED TO ACCOUNT',
          onDelete: () => _removeVehicle(vehicle),
        ),
    ],
  );

  Widget _buildTrips() => _RecordsList(
    loading: _loading && _trips.isEmpty,
    emptyTitle: 'No trips recorded',
    emptyMessage:
        'Add a trip summary after you travel. The app does not collect GPS routes, and emissions are not inferred.',
    onRefresh: _load,
    onAdd: _addTrip,
    addLabel: 'Log a trip',
    children: [
      for (final trip in _trips)
        _RecordCard(
          icon: _tripIcon(trip.mode),
          title: trip.mode.replaceAll('_', ' ').toLowerCase(),
          value: '${trip.distanceKm.toStringAsFixed(1)} km',
          detail:
              DateTime.tryParse(trip.startedAt)?.toLocal().toString() ??
              trip.startedAt,
          badge: trip.evidenceTier.replaceAll('_', ' '),
        ),
    ],
  );

  IconData _vehicleIcon(String type) => switch (type) {
    'TWO_WHEELER' => Icons.two_wheeler_rounded,
    'BUS' => Icons.directions_bus_rounded,
    'CAR' => Icons.directions_car_rounded,
    _ => Icons.commute_rounded,
  };

  IconData _tripIcon(String mode) => switch (mode) {
    'WALK' => Icons.directions_walk_rounded,
    'BICYCLE' => Icons.pedal_bike_rounded,
    'PUBLIC_TRANSIT' => Icons.directions_transit_rounded,
    'PRIVATE_VEHICLE' => Icons.directions_car_rounded,
    _ => Icons.route_rounded,
  };
}

class _RecordsList extends StatelessWidget {
  const _RecordsList({
    required this.loading,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onAdd,
    required this.addLabel,
    required this.children,
  });

  final bool loading;
  final String emptyTitle;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final String addLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    color: UrjaTheme.leaf,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (children.isEmpty && !loading)
          _EmptyRecords(title: emptyTitle, message: emptyMessage),
        ...children,
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(addLabel),
        ),
      ],
    ),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.badge,
    this.onDelete,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final String badge;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: UrjaTheme.mint,
            foregroundColor: UrjaTheme.forest,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title[0].toUpperCase() + title.substring(1),
                  style: const TextStyle(
                    color: UrjaTheme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: UrjaTheme.muted, fontSize: 10),
                ),
                const SizedBox(height: 6),
                Text(
                  badge,
                  style: const TextStyle(
                    color: UrjaTheme.leaf,
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: UrjaTheme.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove vehicle',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: UrjaTheme.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: UrjaTheme.leaf,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: UrjaTheme.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: UrjaTheme.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FormSheet extends StatelessWidget {
  const _FormSheet({
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: UrjaTheme.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: UrjaTheme.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: UrjaTheme.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.start,
    required this.end,
    required this.onChanged,
  });

  final DateTime start;
  final DateTime end;
  final void Function(DateTime start, DateTime end) onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: start,
              firstDate: DateTime(2000),
              lastDate: end,
            );
            if (picked != null) onChanged(picked, end);
          },
          child: Text('From ${_date(start)}'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: end,
              firstDate: start,
              lastDate: DateTime.now(),
            );
            if (picked != null) onChanged(start, picked);
          },
          child: Text('To ${_date(end)}'),
        ),
      ),
    ],
  );

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

class _TripTimeSelector extends StatelessWidget {
  const _TripTimeSelector({
    required this.startedAt,
    required this.endedAt,
    required this.onChanged,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final void Function(DateTime startedAt, DateTime endedAt) onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Trip time',
        style: TextStyle(
          color: UrjaTheme.ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final picked = await _pickDateTime(context, startedAt);
                if (picked == null) return;
                onChanged(picked, endedAt);
              },
              child: Text('Start · ${_format(startedAt)}'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final picked = await _pickDateTime(
                  context,
                  endedAt,
                  firstDate: startedAt,
                );
                if (picked == null) return;
                onChanged(startedAt, picked);
              },
              child: Text('End · ${_format(endedAt)}'),
            ),
          ),
        ],
      ),
    ],
  );

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial, {
    DateTime? firstDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _format(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: UrjaTheme.muted, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Records could not be loaded',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: UrjaTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
