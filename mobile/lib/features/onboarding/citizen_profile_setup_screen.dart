import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/main_two_screen_shell.dart';

/// 3D Skeuomorphic Eco-Pop Profile Setup Questionnaire for Gujarat Citizens
/// Features:
/// - Rich Card UI (not simple lists) with claymorphic elevation and soft gradients
/// - Profile Avatar image selector with preset Gujarat eco-badges and custom URL
/// - Owned Vehicles section with OPTIONAL registration number
/// - Owned Household Devices with multi-domain tags (Water + Energy)
/// - District & Ward dropdowns for all Gujarat Municipal Corporations
class CitizenProfileSetupScreen extends StatefulWidget {
  const CitizenProfileSetupScreen({super.key});

  @override
  State<CitizenProfileSetupScreen> createState() => _CitizenProfileSetupScreenState();
}

class _CitizenProfileSetupScreenState extends State<CitizenProfileSetupScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Profile Avatar
  String _selectedAvatar = '🌿';
  final List<String> _avatarPresets = ['🌿', '🦅', '🦁', '🌸', '🌞', '🌱', '🦜', '🌳'];

  // Step 1: Location & House
  String _selectedDistrict = 'Ahmedabad';
  String _selectedWard = 'Navrangpura';
  String _houseType = 'apartment';
  int _householdMembers = 4;

  // Step 2: Owned Vehicles (Vehicle Number is OPTIONAL!)
  final List<Map<String, String>> _ownedVehicles = [
    {
      'type': 'ev_2wheeler',
      'label': '🛵 Electric Scooter (EV)',
      'regNumber': '',
    },
    {
      'type': 'cycle',
      'label': '🚲 Bicycle / E-Bike',
      'regNumber': '',
    },
  ];

  // Step 3: Water Supply & Storage
  String _waterSupplyType = 'municipal_piped';
  String _waterStorageType = 'both_sump_overhead';

  // Step 4: Electricity & Normalized Appliances
  String _electricityProviderId = 'torrent_power';
  double _monthlyBillRupees = 2200;
  final Set<String> _selectedDevices = {'ro_purifier', 'refrigerator', 'air_conditioner'};

  // Step 5: Cooking Gas Provider
  String _gasProviderId = 'adani_png';

  // Step 6: Companion Sparrow
  final TextEditingController _mascotNameController = TextEditingController(text: 'Cheechee');

  // Municipal Districts & Wards in Gujarat
  final Map<String, List<String>> _districtWards = {
    'Ahmedabad': [
      'Navrangpura',
      'Bodakdev',
      'Maninagar',
      'Paldi',
      'Satellite',
      'Chandkheda',
      'Ellisbridge',
      'Thaltej',
      'Ghatlodia',
      'Sabarmati',
      'Naranpura',
      'Jodhpur',
      'Vasna',
    ],
    'Surat': [
      'Adajan',
      'Vesu',
      'Athwa',
      'Rander',
      'Katargam',
      'Varachha',
      'Udhna',
      'Limbayat',
    ],
    'Vadodara': [
      'Alkapuri',
      'Akota',
      'Fatehgunj',
      'Karelibaug',
      'Manjalpur',
      'Sayajigunj',
    ],
    'Rajkot': [
      'Kalawad Road',
      'University Road',
      'Yagnik Road',
      'Nana Mava',
      'Bhaktinagar',
    ],
    'Gandhinagar': [
      'Sector 1-10',
      'Sector 11-20',
      'Sector 21-30',
      'Infocity',
      'Kudasan',
      'Raysan',
    ],
    'Bhavnagar': ['Kalanala', 'Ghogha Road', 'Subhashnagar', 'Sardarnagar'],
    'Jamnagar': ['Digvijay Plot', 'Patel Colony', 'Gulabnagar', 'Khodiyar Colony'],
    'Junagadh': ['Zanzarda Road', 'Moti Baug', 'Joshipura', 'Kalva Chowk'],
  };

  @override
  void dispose() {
    _mascotNameController.dispose();
    super.dispose();
  }

  void _onDistrictChanged(String? newDistrict) {
    if (newDistrict == null) return;
    setState(() {
      _selectedDistrict = newDistrict;
      final wards = _districtWards[newDistrict] ?? ['Central Ward'];
      _selectedWard = wards.first;

      if (newDistrict == 'Ahmedabad' || newDistrict == 'Gandhinagar' || newDistrict == 'Surat') {
        _electricityProviderId = 'torrent_power';
      } else if (newDistrict == 'Vadodara') {
        _electricityProviderId = 'mgvcl';
      } else if (newDistrict == 'Rajkot' || newDistrict == 'Bhavnagar' || newDistrict == 'Jamnagar' || newDistrict == 'Junagadh') {
        _electricityProviderId = 'pgvcl';
      }
    });
  }

  void _addVehicleDialog() {
    String selectedType = 'ev_2wheeler';
    final regController = TextEditingController();

    final vehicleTypes = [
      {'id': 'ev_2wheeler', 'label': '🛵 Electric Scooter (EV)'},
      {'id': 'cycle', 'label': '🚲 Bicycle / E-Bike'},
      {'id': 'ev_car', 'label': '⚡ Electric Car (EV)'},
      {'id': 'petrol_2wheeler', 'label': '🏍️ Petrol 2-Wheeler'},
      {'id': 'petrol_car', 'label': '🚗 Petrol / CNG Car'},
      {'id': 'public_transit_pass', 'label': '🚇 Metro / Bus Smart Card'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Text('🚗', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('Add Household Vehicle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vehicle Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _claymorphicFieldDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedType,
                    items: vehicleTypes.map((v) {
                      return DropdownMenuItem(value: v['id'], child: Text(v['label']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Vehicle Number (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('e.g. GJ-01-AB-1234 (Optional, for green toll/parking perks)', style: TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _claymorphicFieldDecoration(),
                child: TextField(
                  controller: regController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'GJ-01-XX-0000 (Optional)',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.1),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () {
                final found = vehicleTypes.firstWhere((t) => t['id'] == selectedType);
                setState(() {
                  _ownedVehicles.add({
                    'type': selectedType,
                    'label': found['label']!,
                    'regNumber': regController.text.trim(),
                  });
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B6B44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);

    final vehicleIds = _ownedVehicles.map((v) => v['type']!).toList();

    await AuthService.instance.completeProfile(
      district: _selectedDistrict,
      ward: _selectedWard,
      houseType: _houseType,
      householdMembers: _householdMembers,
      monthlyBillRupees: _monthlyBillRupees,
      electricityProviderId: _electricityProviderId,
      gasProviderId: _gasProviderId,
      waterSupplyType: _waterSupplyType,
      waterStorageType: _waterStorageType,
      defaultTransitModes: vehicleIds,
      deviceCatalogIds: _selectedDevices.toList(),
      vehicleCatalogIds: vehicleIds,
      mascotName: _mascotNameController.text.trim().isNotEmpty
          ? _mascotNameController.text.trim()
          : 'Cheechee',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainTwoScreenShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Text('🌿', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'Citizen Sanctuary Setup',
              style: TextStyle(
                color: Color(0xFF1B6B44),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator (6 Steps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: List.generate(6, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF1B6B44) : const Color(0xFFD2E6DB),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1LocationAndHouse();
      case 1:
        return _buildStep2Vehicles();
      case 2:
        return _buildStep3WaterSupply();
      case 3:
        return _buildStep4ElectricityAndDevices();
      case 4:
        return _buildStep5CookingGas();
      case 5:
        return _buildStep6SparrowCompanion();
      default:
        return const SizedBox();
    }
  }

  // --- Step 1: Location & House ---
  Widget _buildStep1LocationAndHouse() {
    final wards = _districtWards[_selectedDistrict] ?? ['Central Ward'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar Profile Badge Card
        _buildAvatarProfileCard(),
        const SizedBox(height: 16),

        _buildHeroCard(
          icon: '📍',
          title: 'Gujarat Home & District',
          subtitle: 'Select your home district and municipal ward for ward-level clean air and energy leaderboards.',
        ),
        const SizedBox(height: 16),

        // Location Card
        _buildSectionCard(
          title: 'Municipal Location',
          icon: '🏛️',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('District'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _claymorphicFieldDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedDistrict,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1B6B44)),
                    items: _districtWards.keys.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.w700)));
                    }).toList(),
                    onChanged: _onDistrictChanged,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Municipal Ward'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _claymorphicFieldDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: wards.contains(_selectedWard) ? _selectedWard : wards.first,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1B6B44)),
                    items: wards.map((w) {
                      return DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedWard = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // House & Household Card
        _buildSectionCard(
          title: 'House & Family Size',
          icon: '🏡',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Residence Type'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip('apartment', '🏢 Apartment / Flat', _houseType, (v) => setState(() => _houseType = v)),
                  _buildChoiceChip('tenement', '🏘️ Tenement', _houseType, (v) => setState(() => _houseType = v)),
                  _buildChoiceChip('bungalow', '🏡 Bungalow', _houseType, (v) => setState(() => _houseType = v)),
                  _buildChoiceChip('row_house', '🏠 Row House', _houseType, (v) => setState(() => _houseType = v)),
                ],
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Household Members: $_householdMembers people (1-20)'),
              Row(
                children: [
                  IconButton.filled(
                    onPressed: _householdMembers > 1 ? () => setState(() => _householdMembers--) : null,
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF1B6B44)),
                  ),
                  Expanded(
                    child: Slider(
                      value: _householdMembers.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      activeColor: const Color(0xFF1B6B44),
                      label: '$_householdMembers people',
                      onChanged: (val) => setState(() => _householdMembers = val.round()),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _householdMembers < 20 ? () => setState(() => _householdMembers++) : null,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF1B6B44)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Avatar Card UI with image selection
  Widget _buildAvatarProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD2E6DB), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F5E9),
              border: Border.all(color: const Color(0xFF1B6B44), width: 2),
            ),
            child: Center(
              child: Text(_selectedAvatar, style: const TextStyle(fontSize: 34)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Citizen Sanctuary Avatar',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1B6B44)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Pick your eco-citizen badge for Gujarat leaderboards',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _avatarPresets.map((a) {
                      final isSelected = a == _selectedAvatar;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = a),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFF1B6B44) : const Color(0xFFF1F8F5),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1B6B44) : const Color(0xFFD2E6DB),
                              width: 1.5,
                            ),
                          ),
                          child: Text(a, style: const TextStyle(fontSize: 18)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Owned Vehicles (with OPTIONAL registration number) ---
  Widget _buildStep2Vehicles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(
          icon: '🚗',
          title: 'Owned Household Vehicles',
          subtitle: 'Register your electric and daily mobility modes. Vehicle numbers are completely optional.',
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Registered Household Fleet (${_ownedVehicles.length})',
          icon: '⚡',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._ownedVehicles.asMap().entries.map((entry) {
                final idx = entry.key;
                final v = entry.value;
                final reg = v['regNumber'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FDFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD2E6DB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🚘', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v['label']!,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reg.isNotEmpty ? 'Reg No: $reg' : 'No number registered (Optional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: reg.isNotEmpty ? const Color(0xFF1B6B44) : Colors.black45,
                                fontWeight: reg.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          setState(() => _ownedVehicles.removeAt(idx));
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addVehicleDialog,
                  icon: const Icon(Icons.add_rounded, color: Color(0xFF1B6B44)),
                  label: const Text('+ Add Vehicle Owned (EV, Bike, Car)', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B6B44),
                    side: const BorderSide(color: Color(0xFF1B6B44), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 3: Water Supply & Storage ---
  Widget _buildStep3WaterSupply() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(
          icon: '💧',
          title: 'Water Supply & Storage',
          subtitle: 'Tell us how water reaches your home. In-ground sump and overhead tank configurations calibrate motor cut-off prompts.',
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Primary Water Source',
          icon: '🚰',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip('municipal_piped', '🚰 Municipal Tap (AMC / SMC / VMC)', _waterSupplyType, (v) => setState(() => _waterSupplyType = v)),
              _buildChoiceChip('borewell', '⚡ Borewell / Submersible Pump', _waterSupplyType, (v) => setState(() => _waterSupplyType = v)),
              _buildChoiceChip('tanker', '🚚 Private Tanker Supply', _waterSupplyType, (v) => setState(() => _waterSupplyType = v)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Water Storage Configuration',
          icon: '🏗️',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip('underground_sump', '🧱 In-Ground Tanki (Underground Sump)', _waterStorageType, (v) => setState(() => _waterStorageType = v)),
              _buildChoiceChip('overhead_tank', '🏗️ Rooftop Overhead Tank', _waterStorageType, (v) => setState(() => _waterStorageType = v)),
              _buildChoiceChip('both_sump_overhead', '🔄 Both (Underground Sump + Rooftop)', _waterStorageType, (v) => setState(() => _waterStorageType = v)),
              _buildChoiceChip('tubs_drums', '🪣 Storage Tubs / Drums', _waterStorageType, (v) => setState(() => _waterStorageType = v)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 4: Electricity & Normalized Appliances ---
  Widget _buildStep4ElectricityAndDevices() {
    final discoms = [
      {'id': 'torrent_power', 'name': '⚡ Torrent Power (Ahmedabad/Surat/Gandhinagar)'},
      {'id': 'ugvcl', 'name': '⚡ UGVCL (Uttar Gujarat Vij)'},
      {'id': 'dgvcl', 'name': '⚡ DGVCL (Dakshin Gujarat Vij)'},
      {'id': 'mgvcl', 'name': '⚡ MGVCL (Madhya Gujarat Vij)'},
      {'id': 'pgvcl', 'name': '⚡ PGVCL (Paschim Gujarat Vij)'},
    ];

    final devices = [
      {'id': 'ro_purifier', 'name': '💧⚡ RO Water Purifier', 'domains': 'Water + Energy', 'desc': 'Wastes ~3L per 1L drinking water unless reject water collected.'},
      {'id': 'air_conditioner', 'name': '❄️ Air Conditioner (AC)', 'domains': 'High Power', 'desc': 'Consumes ~1.5 kWh/hr. 24°C saves 24% bill.'},
      {'id': 'induction_stove', 'name': '🍲 Induction Cooker', 'domains': 'Cooking + Electricity', 'desc': 'Clean electric cooking replacing LPG.'},
      {'id': 'water_geyser', 'name': '🚿 Water Geyser / Heater', 'domains': 'Peak Load', 'desc': '2 kW heating coil with timer opportunity.'},
      {'id': 'refrigerator', 'name': '🧊 Refrigerator', 'domains': 'Always On', 'desc': 'Clean coil & seal checks prevent continuous compressor run.'},
      {'id': 'washing_machine', 'name': '🧺 Washing Machine', 'domains': 'Water + Energy', 'desc': 'Eco mode & full load washing saves 40L per cycle.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(
          icon: '⚡',
          title: 'Electricity & High-Drain Appliances',
          subtitle: 'Linked directly with your Gujarat DISCOM. Multi-domain normalization links RO Purifier to both water and power.',
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Gujarat DISCOM & Monthly Bill',
          icon: '💡',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Electricity Provider'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _claymorphicFieldDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _electricityProviderId,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1B6B44)),
                    items: discoms.map((d) {
                      return DropdownMenuItem(
                        value: d['id'],
                        child: Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _electricityProviderId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Approximate Monthly Bill: ₹${_monthlyBillRupees.toInt()}'),
              Slider(
                value: _monthlyBillRupees,
                min: 400,
                max: 10000,
                divisions: 24,
                activeColor: const Color(0xFF1B6B44),
                label: '₹${_monthlyBillRupees.toInt()}',
                onChanged: (val) => setState(() => _monthlyBillRupees = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Household Registered Devices (${_selectedDevices.length})',
          icon: '📱',
          child: Column(
            children: devices.map((dev) {
              final id = dev['id']!;
              final isSelected = _selectedDevices.contains(id);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1B6B44) : const Color(0xFFE2EBE5),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: CheckboxListTile(
                  value: isSelected,
                  activeColor: const Color(0xFF1B6B44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(dev['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(
                    'Link: ${dev['domains']} • ${dev['desc']}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedDevices.add(id);
                      } else {
                        _selectedDevices.remove(id);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- Step 5: Cooking Gas ---
  Widget _buildStep5CookingGas() {
    final gasProviders = [
      {'id': 'adani_png', 'name': '🔥 Adani Total Gas (Piped PNG)'},
      {'id': 'gujarat_gas', 'name': '🔥 Gujarat Gas (Piped PNG)'},
      {'id': 'indane_lpg', 'name': '🛢️ Indane (LPG Cylinder)'},
      {'id': 'bharat_gas', 'name': '🛢️ Bharat Gas (LPG Cylinder)'},
      {'id': 'hp_gas', 'name': '🛢️ HP Gas (LPG Cylinder)'},
      {'id': 'electric_only', 'name': '⚡ All-Electric Induction Kitchen'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(
          icon: '🍳',
          title: 'Kitchen Cooking Energy',
          subtitle: 'Track LPG refill cycles or pipeline flow to earn badges for pulse-soaking and lid-covered boiling.',
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Primary Cooking Fuel Provider',
          icon: '🔥',
          child: Column(
            children: gasProviders.map((p) {
              final id = p['id']!;
              final isSelected = _gasProviderId == id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1B6B44) : const Color(0xFFE2EBE5),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1B6B44)) : null,
                  onTap: () => setState(() => _gasProviderId = id),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- Step 6: Sparrow Companion Adoption ---
  Widget _buildStep6SparrowCompanion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeroCard(
          icon: '🕊️',
          title: 'Adopt Your Sparrow Companion',
          subtitle: 'Gujarat House Sparrow (Chakli) will guide your daily energy quests and react to your real-world conservation.',
        ),
        const SizedBox(height: 20),

        // 3D Mascot Avatar Circle
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFDFF0FE),
            border: Border.all(color: const Color(0xFF1B6B44), width: 3.5),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 18, offset: Offset(0, 6)),
            ],
          ),
          child: const Center(
            child: Text('🐦', style: TextStyle(fontSize: 72)),
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionCard(
          title: 'Name Your Companion Sparrow',
          icon: '🏷️',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _claymorphicFieldDecoration(),
            child: TextField(
              controller: _mascotNameController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g. Cheechee, Chaklo, Mitra',
              ),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFBBF24), width: 1.2),
          ),
          child: const Row(
            children: [
              Text('🎁', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Adopting your sparrow awards +100 Urja Mudra coins and unlocks your 3D Garden Sanctuary!',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- UI Card Helpers ---
  Widget _buildSectionCard({required String title, required String icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD2E6DB), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1B6B44)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildHeroCard({required String icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD2E6DB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1B6B44)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF263238)),
      ),
    );
  }

  Widget _buildChoiceChip(String value, String label, String currentSelected, ValueChanged<String> onSelected) {
    final isSelected = value == currentSelected;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1B6B44),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1B6B44) : const Color(0xFFD2E6DB),
          width: 1.5,
        ),
      ),
      onSelected: (_) => onSelected(value),
    );
  }

  BoxDecoration _claymorphicFieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD2E6DB), width: 1.5),
      boxShadow: const [
        BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
      ],
    );
  }

  Widget _buildBottomControls() {
    final isLastStep = _currentStep == 5;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B6B44),
                side: const BorderSide(color: Color(0xFF1B6B44), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (isLastStep) {
                        _submitOnboarding();
                      } else {
                        setState(() => _currentStep++);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B6B44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 3,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      isLastStep ? 'Complete & Enter Sanctuary 🌿' : 'Next Step →',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
