import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../activity/activity_feed_screen.dart';

class SanctuaryHomeScreen extends StatefulWidget {
  const SanctuaryHomeScreen({super.key});

  @override
  State<SanctuaryHomeScreen> createState() => _SanctuaryHomeScreenState();
}

class _SanctuaryHomeScreenState extends State<SanctuaryHomeScreen> {
  int _coins = 50; // Starting 50 bonus coins
  int _vitality = 85;
  final int _mascotLevel = 1;
  String _expression = 'excited';
  String _speechText = 'Chirp! ⚡ Gujarat solar generation is peaking! Great time to power our sanctuary!';
  String _currentSeason = 'summer'; // spring, summer, autumn, winter, rainy, festive
  double _cameraTransition = 0.0; // 0.0 = 3D Character focus, 1.0 = 2.5D Sanctuary overview

  // Sanctuary Grid (3x3 default, Sparrow Home at center)
  final List<GardenTileData> _placedTiles = [
    GardenTileData(id: 'SPARROW_HOME', name: 'Sparrow Manor', category: 'Buildings', x: 1, y: 1, emoji: '🏡', isProtectedHome: true),
    GardenTileData(id: 'TULSI_KYARO', name: 'Tulsi Altar', category: 'Flora', x: 0, y: 1, emoji: '🪴'),
    GardenTileData(id: 'SOLAR_STREET_LAMP', name: 'Solar Lamp', category: 'Energy', x: 2, y: 1, emoji: '🏮'),
  ];

  final List<SeasonalOutfit> _outfits = const [
    SeasonalOutfit(id: 'spring', name: 'Spring Blossom', season: 'spring', emoji: '🌸', head: 'flowers', fx: 'petals'),
    SeasonalOutfit(id: 'summer', name: 'Summer Breeze', season: 'summer', emoji: '🕶️', head: 'straw', fx: 'butterflies'),
    SeasonalOutfit(id: 'autumn', name: 'Autumn Harvest', season: 'autumn', emoji: '🍂', head: 'acorn', fx: 'leaves'),
    SeasonalOutfit(id: 'winter', name: 'Cozy Winter', season: 'winter', emoji: '❄️', head: 'beanie', fx: 'snow'),
    SeasonalOutfit(id: 'rainy', name: 'Monsoon Splash', season: 'rainy', emoji: '🌧️', head: 'rainhat', fx: 'rain'),
    SeasonalOutfit(id: 'festive', name: 'Festive Celebration', season: 'festive', emoji: '🎉', head: 'santa', fx: 'snow'),
  ];

  void _interactWithSparrow() {
    setState(() {
      _vitality = (_vitality + 5).clamp(0, 100);
      _coins += 2;
      _expression = 'curious';
      _speechText = 'Flutter! Tap received! +5 Vitality and +2 Urja Mudra coins awarded!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tapped Chirpy! +5 Vitality · +2 Urja Mudra 🪙'),
        backgroundColor: UrjaColors.primaryGreen,
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  void _equipSeasonalOutfit(SeasonalOutfit outfit) {
    setState(() {
      _currentSeason = outfit.season;
      _expression = 'celebrating';
      _speechText = 'Wearing ${outfit.name}! Real-time weather ambience updated to ${outfit.season.toUpperCase()}!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Equipped ${outfit.name} ${outfit.emoji} with seasonal weather FX!'),
        backgroundColor: UrjaColors.primaryGreen,
      ),
    );
  }

  void _onTileTap(GardenTileData tile) {
    if (tile.isProtectedHome) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: UrjaColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text('🏡', style: TextStyle(fontSize: 26)),
              SizedBox(width: 10),
              Text('Sparrow Manor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: const Text(
            'The Sparrow Home is the permanent sanctuary centerpiece and home backdrop.\n\nIt cannot be removed or sold, keeping your companion protected across all seasons!',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood', style: TextStyle(color: UrjaColors.primaryGreen, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: UrjaColors.cardSurface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  Text(tile.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
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
                        side: const BorderSide(color: UrjaColors.borderGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Store in Inventory', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _placedTiles.remove(tile);
                          _coins += 80; // 80% resale
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sold ${tile.name}! Recovered 80% price (+80 coins)')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UrjaColors.amberGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Sell (80% Return)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
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
      backgroundColor: UrjaColors.emeraldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Citizen Profile Pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: UrjaColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: UrjaColors.borderGreen),
                        ),
                        child: const Text('🕊️', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chirpy · Lvl $_mascotLevel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: UrjaColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Mood: $_expression',
                                style: const TextStyle(
                                  color: UrjaColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Coins Pill + Activity Icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: UrjaColors.amberGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: UrjaColors.amberGold.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '$_coins',
                              style: const TextStyle(
                                color: UrjaColors.sunnyYellow,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ActivityFeedScreen()),
                          );
                        },
                        icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: UrjaColors.cardSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: UrjaColors.borderGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Real-Time Seasonal Weather Showcase Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: UrjaColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: UrjaColors.borderGreen),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(_getSeasonIcon(_currentSeason), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Season: ${_currentSeason.toUpperCase()} · Gujarat Solar Peak',
                          style: const TextStyle(
                            color: UrjaColors.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      '32°C · ☀️ 5.8 kWh/m²',
                      style: TextStyle(
                        color: UrjaColors.sunnyYellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Camera / View Transition Slider (Scroll Simulation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Text('👤 3D Focus', style: TextStyle(color: UrjaColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: _cameraTransition,
                      onChanged: (val) => setState(() => _cameraTransition = val),
                      activeColor: UrjaColors.primaryGreen,
                      inactiveColor: UrjaColors.borderGreen,
                    ),
                  ),
                  const Text('🗺️ 2.5D Garden', style: TextStyle(color: UrjaColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Dynamic 3D Scene / 2.5D Grid View
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color.lerp(const Color(0xFF1E3A2B), const Color(0xFF0F261B), _cameraTransition)!,
                      const Color(0xFF08140E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: UrjaColors.borderGreen),
                ),
                child: Stack(
                  children: [
                    // A. Background Sparrow Manor Home
                    Positioned(
                      top: 20 - (_cameraTransition * 20),
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: (1.0 - (_cameraTransition * 0.4)).clamp(0.0, 1.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                                border: Border.all(color: UrjaColors.primaryGreen.withValues(alpha: 0.3)),
                              ),
                              child: const Text('🏡', style: TextStyle(fontSize: 60)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sparrow Manor (Protected Sanctuary Centerpiece)',
                              style: TextStyle(
                                color: UrjaColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // B. Interactive 2.5D Garden Sanctuary Grid (Blends in as camera tilts down)
                    if (_cameraTransition > 0.25)
                      Positioned.fill(
                        top: 100,
                        child: Opacity(
                          opacity: ((_cameraTransition - 0.25) / 0.75).clamp(0.0, 1.0),
                          child: Center(
                            child: SizedBox(
                              width: 270,
                              height: 270,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: 9,
                                itemBuilder: (context, idx) {
                                  final x = idx % 3;
                                  final y = idx ~/ 3;
                                  final tile = _placedTiles.cast<GardenTileData?>().firstWhere(
                                        (t) => t?.x == x && t?.y == y,
                                        orElse: () => null,
                                      );

                                  return GestureDetector(
                                    onTap: () {
                                      if (tile != null) _onTileTap(tile);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: tile?.isProtectedHome == true
                                            ? const Color(0xFF244837)
                                            : UrjaColors.cardSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: tile?.isProtectedHome == true
                                              ? UrjaColors.primaryGreen
                                              : UrjaColors.borderGreen,
                                          width: tile?.isProtectedHome == true ? 2 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          tile?.emoji ?? '🌱',
                                          style: TextStyle(
                                            fontSize: tile?.isProtectedHome == true ? 28 : 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                    // C. 3D Sparrow Mascot in Foreground (Transitions smoothly)
                    if (_cameraTransition < 0.85)
                      Positioned(
                        bottom: 20 + (_cameraTransition * 30),
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: (1.0 - (_cameraTransition * 1.1)).clamp(0.0, 1.0),
                          child: GestureDetector(
                            onTap: _interactWithSparrow,
                            child: Column(
                              children: [
                                // Speech Bubble
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: UrjaColors.primaryGreen.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    _speechText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Mascot Avatar
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [Color(0xFF34D399), Color(0xFF065F46)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: UrjaColors.primaryGreen.withValues(alpha: 0.4),
                                        blurRadius: 25,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text('🕊️', style: TextStyle(fontSize: 50)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Tap Chirpy to play (+5 Vitality, +2 🪙)',
                                  style: TextStyle(
                                    color: UrjaColors.primaryGreen.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
            ),

            // Outfits & Seasonal Wardrobe Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: UrjaColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: UrjaColors.borderGreen)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seasonal Wardrobe & Ambient FX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _outfits.length,
                      itemBuilder: (context, index) {
                        final o = _outfits[index];
                        final isEquipped = o.season == _currentSeason;

                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: ActionChip(
                            avatar: Text(o.emoji, style: const TextStyle(fontSize: 16)),
                            label: Text(o.name),
                            onPressed: () => _equipSeasonalOutfit(o),
                            backgroundColor: isEquipped ? UrjaColors.primaryGreen : UrjaColors.cardHover,
                            labelStyle: TextStyle(
                              color: isEquipped ? Colors.white : UrjaColors.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isEquipped ? UrjaColors.primaryGreen : UrjaColors.borderGreen,
                              ),
                            ),
                          ),
                        );
                      },
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
  final String season;
  final String emoji;
  final String head;
  final String fx;

  const SeasonalOutfit({
    required this.id,
    required this.name,
    required this.season,
    required this.emoji,
    required this.head,
    required this.fx,
  });
}
