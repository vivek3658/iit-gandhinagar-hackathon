import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/auth_session.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _districts = [
    'Ahmedabad',
    'Amreli',
    'Anand',
    'Aravalli',
    'Banaskantha',
    'Bharuch',
    'Bhavnagar',
    'Botad',
    'Chhota Udaipur',
    'Dahod',
    'Dang',
    'Devbhoomi Dwarka',
    'Gandhinagar',
    'Gir Somnath',
    'Jamnagar',
    'Junagadh',
    'Kheda',
    'Kutch',
    'Mahisagar',
    'Mehsana',
    'Morbi',
    'Narmada',
    'Navsari',
    'Panchmahal',
    'Patan',
    'Porbandar',
    'Rajkot',
    'Sabarkantha',
    'Surat',
    'Surendranagar',
    'Tapi',
    'Vadodara',
    'Valsad',
  ];

  final _wardController = TextEditingController();
  String? _district;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _wardController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final district = _district;
    if (district == null) {
      setState(() => _error = 'Choose your district to continue.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthSession.instance.completeProfile(
        district: district,
        ward: _wardController.text,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = AuthSession.instance.user?['name'] as String? ?? 'friend';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: UrjaColors.canvas,
        title: const Text('Make it yours'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: UrjaColors.mint,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome, ${userName.split(' ').first}!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A couple of details help us make your missions local and useful.',
                          style: TextStyle(color: UrjaColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset('assets/images/cheerful_bird_512.png', width: 88),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Where do you live?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            const Text(
              'Used for local community and service-area suggestions. No GPS needed.',
              style: TextStyle(color: UrjaColors.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _district,
              decoration: const InputDecoration(
                labelText: 'Gujarat district',
                prefixIcon: Icon(Icons.location_city_rounded),
              ),
              items: _districts
                  .map(
                    (district) => DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _district = value),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _wardController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ward or area (optional)',
                prefixIcon: Icon(Icons.map_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Grow my garden'),
            ),
          ],
        ),
      ),
    );
  }
}
