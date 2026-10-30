import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../activity/activity_feed_screen.dart';

class SanctuaryHomeScreen extends StatefulWidget {
  const SanctuaryHomeScreen({super.key});

  @override
  State<SanctuaryHomeScreen> createState() => _SanctuaryHomeScreenState();
}

class _SanctuaryHomeScreenState extends State<SanctuaryHomeScreen> {
  int _coins = 50; // New citizen starts with 50 coins!
  int _vitality = 85;
  String _currentSeason = 'summer';
  String _speechText = 'Chirp! You saved 1.2 kg CO₂e yesterday! Keep going! 🌱';
  double _viewTransition = 0.0; // 0.0 = 3D Hero character focus, 1.0 = 2.5D Isometric Garden view

  final List<GardenTileData> _placedTiles = [
    GardenTileData(id: 'SPARROW_HOME', name: 'Sparrow Manor', category: 'Buildings', x: 1, y: 1, emoji: '🏡', isProtectedHome: true),
    GardenTileData(id: 'TULSI_KYARO', name: 'Tulsi Altar', category: 'Flora', x: 0, y: 1, emoji: '🪴'),
    GardenTileData(id: 'CHERRY_TREE', name: 'Cherry Tree', category: 'Flora', x: 2, y: 1, emoji: '🌸'),
    GardenTileData(id: 'SOLAR_LAMP', name: 'Solar Lamp', category: 'Energy', x: 1, y: 2, emoji: '🏮'),
  ];

  final List<SeasonalOutfit> _outfits = const [
    SeasonalOutfit(id: 'summer', name: 'Summer', emoji: '🕶️', season: 'summer'),
    SeasonalOutfit(id: 'spring', name: 'Spring', emoji: '🌸', season: 'spring'),
    SeasonalOutfit(id: 'autumn', name: 'Autumn', emoji: '🍂', season: 'autumn'),
    SeasonalOutfit(id: 'winter', name: 'Winter', emoji: '❄️', season: 'winter'),
    SeasonalOutfit(id: 'rainy', name: 'Monsoon', emoji: '🌧️', season: 'rainy'),
    SeasonalOutfit(id: 'festive', name: 'Festive', emoji: '🎉', season: 'festive'),
  ];

  void _interactWithSparrow() {
    setState(() {
      _vitality = (_vitality + 5).clamp(0, 100);
      _coins += 2;
      _speechText = 'Chirp! Tap received! +5 Vitality & +2 Urja Mudra coins! ⚡';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tapped Chirpy! +5 Vitality · +2 Coins 🪙'),
        backgroundColor: Color(0xFF1B6B44),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  void _onTileTap(GardenTileData tile) {
    if (tile.isProtectedHome) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Text('🏡', style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Text('Sparrow Manor', style: TextStyle(color: UrjaColors.textMain, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: const Text(
            'The Sparrow Home is your sanctuary\'s permanent centerpiece and home backdrop.\n\nIt cannot be removed or sold, keeping your companion protected across all seasons!',
            style: TextStyle(color: UrjaColors.textSub, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood', style: TextStyle(color: Color(0xFF1B6B44), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(tile.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Text(tile.name, style: const TextStyle(color: UrjaColors.textMain, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Category: ${tile.category} · Coordinates (${tile.x}, ${tile.y})', style: const TextStyle(color: UrjaColors.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _placedTiles.remove(tile);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Stored ${tile.name} in inventory')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2EBE5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Store in Inventory', style: TextStyle(color: UrjaColors.textMain, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _placedTiles.remove(tile);
                          _coins += 80; // 80% resale recovery!
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sold ${tile.name}! Recovered 80% price (+80 coins)')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Sell (80% Return)', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5), // Clean Nature Palette from mockup
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Logo + Coins Pill + Notification Bell + Avatar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'URJA ONE',
                          style: TextStyle(
                            color: Color(0xFF1B6B44),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text('🌿', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    Row(
                      children: [
                        // Coins Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '$_coins',
                                style: const TextStyle(
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Notification Bell with Red Dot
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ActivityFeedScreen()),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.notifications_none_rounded, color: UrjaColors.textMain),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Profile Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/cheerful_bird_512.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Greeting Row
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning,',
                      style: TextStyle(
                        color: UrjaColors.textSub,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Vivek 👋',
                      style: TextStyle(
                        color: UrjaColors.textMain,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Every small step counts!',
                      style: TextStyle(
                        color: UrjaColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Real-Time Season Showcase Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2EBE5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(_getSeasonIcon(_currentSeason), style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'Season: ${_currentSeason.toUpperCase()}',
                            style: const TextStyle(
                              color: Color(0xFF1B6B44),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '☀️ Solar Peak · 32°C',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Camera Transition Slider (Scroll Simulation: 3D Character -> 2.5D Isometric Garden)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    const Text('👤 3D Mascot', style: TextStyle(color: UrjaColors.textSub, fontSize: 11, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Slider(
                        value: _viewTransition,
                        onChanged: (val) => setState(() => _viewTransition = val),
                        activeColor: const Color(0xFF1B6B44),
                        inactiveColor: const Color(0xFFE2EBE5),
                      ),
                    ),
                    const Text('🗺️ 2.5D Garden', style: TextStyle(color: UrjaColors.textSub, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),

              // Visual Stage: 3D Character Hero vs 2.5D Isometric Garden Grid
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 290,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Stack(
                  children: [
                    // A. 3D Isometric Garden Grid (Displays when transitioned)
                    Positioned.fill(
                      child: Opacity(
                        opacity: _viewTransition,
                        child: GestureDetector(
                          onTap: () {
                            if (_placedTiles.isNotEmpty) _onTileTap(_placedTiles.first);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/garden_isometric_3d.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Tap tiles to inspect, store in inventory or resell (80% return)',
                                  style: TextStyle(
                                    color: UrjaColors.textMain,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // B. 3D Articulated Sparrow on Branch Hero (Displays in character focus)
                    if (_viewTransition < 0.95)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 1.0 - _viewTransition,
                          child: GestureDetector(
                            onTap: _interactWithSparrow,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.asset(
                                      'assets/images/sparrow_branch_hero.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Floating Speech Bubble on right
                                Positioned(
                                  top: 24,
                                  right: 16,
                                  left: 120,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                                      ],
                                      border: Border.all(color: const Color(0xFFE2EBE5)),
                                    ),
                                    child: Text(
                                      _speechText,
                                      style: const TextStyle(
                                        color: UrjaColors.textMain,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                                // Tap prompt
                                Positioned(
                                  bottom: 12,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Tap Chirpy to play (+5 ⚡)',
                                      style: TextStyle(
                                        color: Color(0xFF1B6B44),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Seasonal Wardrobe Outfit Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _outfits.length,
                    itemBuilder: (context, index) {
                      final o = _outfits[index];
                      final isSelected = o.season == _currentSeason;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Text(o.emoji, style: const TextStyle(fontSize: 15)),
                          label: Text(o.name),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _currentSeason = o.season;
                              _speechText = 'Wearing ${o.name}! Seasonal weather FX updated to ${o.season.toUpperCase()}! 🌿';
                            });
                          },
                          selectedColor: const Color(0xFF1B6B44),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : UrjaColors.textMain,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF1B6B44) : const Color(0xFFE2EBE5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CO2e Saved Card (Identical to Eco Quest Screen 1 mockup)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'CO₂e Saved',
                                style: TextStyle(
                                  color: UrjaColors.textMain,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text('🌱', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '↑ 42% vs last 30 days',
                              style: TextStyle(
                                color: Color(0xFF1B6B44),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '38.4 kg',
                        style: TextStyle(
                          color: UrjaColors.textMain,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFF1F5F2)),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetricSubColumn(icon: '⚡', title: 'Energy Saved', value: '48.6 kWh'),
                          _MetricSubColumn(icon: '₹', title: 'Money Saved', value: '₹182'),
                          _MetricSubColumn(icon: '🌲', title: 'Equiv. Trees', value: '1.9'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Today's Progress Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Progress',
                            style: TextStyle(
                              color: UrjaColors.textMain,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '3/6 tasks',
                            style: TextStyle(
                              color: UrjaColors.textSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 6 circular checkmarks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (idx) {
                          final isDone = idx < 3;
                          return Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDone ? const Color(0xFF1B6B44) : const Color(0xFFF1F5F2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: isDone ? Colors.white : const Color(0xFFCBD5E1),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _getSeasonIcon(String season) {
    switch (season) {
      case 'spring':
        return '🌸';
      case 'summer':
        return '☀️';
      case 'autumn':
        return '🍂';
      case 'winter':
        return '❄️';
      case 'rainy':
        return '🌧️';
      case 'festive':
        return '🎉';
      default:
        return '🌿';
    }
  }
}

class _MetricSubColumn extends StatelessWidget {
  final String icon;
  final String title;
  final String value;

  const _MetricSubColumn({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: UrjaColors.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: UrjaColors.textMain,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class GardenTileData {
  final String id;
  final String name;
  final String category;
  final int x;
  final int y;
  final String emoji;
  final bool isProtectedHome;

  GardenTileData({
    required this.id,
    required this.name,
    required this.category,
    required this.x,
    required this.y,
    required this.emoji,
    this.isProtectedHome = false,
  });
}

class SeasonalOutfit {
  final String id;
  final String name;
  final String emoji;
  final String season;

  const SeasonalOutfit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.season,
  });
}
