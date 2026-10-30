import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../wardrobe/wardrobe_screen.dart';
import 'widgets/floating_isometric_grid.dart';
import 'widgets/mascot_house_hero.dart';
import 'widgets/tile_detail_sheet.dart';

class SanctuaryHomeScreen extends StatefulWidget {
  final int initialCoins;
  final ValueChanged<int>? onCoinsChanged;
  final VoidCallback? onOpenWardrobe;

  const SanctuaryHomeScreen({
    super.key,
    this.initialCoins = 500,
    this.onCoinsChanged,
    this.onOpenWardrobe,
  });

  @override
  State<SanctuaryHomeScreen> createState() => _SanctuaryHomeScreenState();
}

class _SanctuaryHomeScreenState extends State<SanctuaryHomeScreen> {
  late int _coins;
  int _vitality = 85;
  String _speechText = 'Chirp! Welcome to your sanctuary! Scroll down to explore our floating island garden! 🌱';
  final ScrollController _scrollController = ScrollController();

  // Starter 3x3 Garden Grid with center tile (1,1) locked to SPARROW_HOME
  final List<GardenTileModel> _tiles = [
    // Center House (1,1) - permanent companion home
    const GardenTileModel(
      id: 'SPARROW_HOME',
      name: 'Chibi Sparrow Manor',
      category: 'Buildings',
      x: 1,
      y: 1,
      iconEmoji: '🏡',
      level: 5,
      cost: 800,
      isProtectedHome: true,
    ),
    // Surrounding 3x3 tiles
    const GardenTileModel(
      id: 'TULSI_KYARO',
      name: 'Sacred Tulsi Altar',
      category: 'Flora',
      x: 0,
      y: 1,
      iconEmoji: '🪴',
      level: 1,
      cost: 250,
    ),
    const GardenTileModel(
      id: 'SOLAR_PANEL_T1',
      name: 'Mini Solar Flower',
      category: 'Energy',
      x: 2,
      y: 1,
      iconEmoji: '🌻',
      level: 1,
      cost: 500,
    ),
    const GardenTileModel(
      id: 'POND_TILE',
      name: 'Lily Pond Tile',
      category: 'Water',
      x: 1,
      y: 0,
      iconEmoji: '🪷',
      level: 1,
      cost: 350,
    ),
    const GardenTileModel(
      id: 'WINDMILL_RUSTIC',
      name: 'Mini Kinetic Windmill',
      category: 'Energy',
      x: 1,
      y: 2,
      iconEmoji: '🎐',
      level: 5,
      cost: 750,
    ),
    const GardenTileModel(
      id: 'GRASS_TILE',
      name: 'Lush Meadow',
      category: 'Paths',
      x: 0,
      y: 0,
      iconEmoji: '🌾',
      level: 1,
      cost: 50,
    ),
    const GardenTileModel(
      id: 'VEGETABLE_PLOT',
      name: 'Organic Veg Plot',
      category: 'Flora',
      x: 2,
      y: 0,
      iconEmoji: '🥕',
      level: 2,
      cost: 300,
    ),
    const GardenTileModel(
      id: 'STONE_PATH',
      name: 'Cobblestone Way',
      category: 'Paths',
      x: 0,
      y: 2,
      iconEmoji: '🪨',
      level: 1,
      cost: 100,
    ),
    const GardenTileModel(
      id: 'BIRD_HOUSE',
      name: 'Wooden Bird House',
      category: 'Furniture',
      x: 2,
      y: 2,
      iconEmoji: '🪵',
      level: 1,
      cost: 200,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _coins = widget.initialCoins;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _interactWithSparrow() {
    setState(() {
      _vitality = (_vitality + 5).clamp(0, 100);
      _coins += 2;
      _speechText = 'Chirp! Tap received! +5 Vitality & +2 Urja Mudra coins! ⚡';
    });
    widget.onCoinsChanged?.call(_coins);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tapped Chirpy! +5 Vitality · +2 Coins 🪙'),
        backgroundColor: Color(0xFF1B6B44),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  void _scrollToGarden() {
    _scrollController.animateTo(
      420,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onTileTap(GardenTileModel tile) {
    TileDetailSheet.show(
      context,
      tile: tile,
      onStoreInInventory: () {
        setState(() {
          _tiles.removeWhere((t) => t.x == tile.x && t.y == tile.y);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stored ${tile.name} in your sanctuary inventory 📦'),
            backgroundColor: const Color(0xFF1B6B44),
          ),
        );
      },
      onSellTile: () {
        final resale = (tile.cost * 0.8).round();
        setState(() {
          _tiles.removeWhere((t) => t.x == tile.x && t.y == tile.y);
          _coins += resale;
        });
        widget.onCoinsChanged?.call(_coins);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sold ${tile.name}! Recovered $resale coins 🪙'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
      },
    );
  }

  void _openWardrobeScreen() {
    if (widget.onOpenWardrobe != null) {
      widget.onOpenWardrobe!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WardrobeScreen(
            initialCoins: _coins,
            onCoinsChanged: (c) {
              setState(() => _coins = c);
              widget.onCoinsChanged?.call(c);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: URJA ONE Title + Coins + Vitality + Wardrobe Button
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                '$_coins',
                                style: const TextStyle(
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Wardrobe Pill Button
                        InkWell(
                          onTap: _openWardrobeScreen,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B6B44),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Color(0x331B6B44), blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Text('👗', style: TextStyle(fontSize: 13)),
                                SizedBox(width: 4),
                                Text(
                                  'Wardrobe',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Greeting & Vitality Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning,',
                          style: TextStyle(
                            color: UrjaColors.textSub,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Vivek 👋',
                          style: TextStyle(
                            color: UrjaColors.textMain,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2EBE5)),
                      ),
                      child: Row(
                        children: [
                          const Text('⚡ Vitality: ', style: TextStyle(color: UrjaColors.textSub, fontSize: 12, fontWeight: FontWeight.w700)),
                          Text(
                            '$_vitality%',
                            style: const TextStyle(
                              color: Color(0xFF1B6B44),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. MAIN HERO: Sparrow Mascot centered in front of the Sparrow Manor House
              MascotHouseHero(
                onSparrowTap: _interactWithSparrow,
                onScrollDownTap: _scrollToGarden,
                speechText: _speechText,
              ),

              const SizedBox(height: 24),

              // 4. FLOATING GARDEN GRID SECTION HEADER (Coin Master / Sim Companies style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'FLOATING GARDEN',
                          style: TextStyle(
                            color: Color(0xFF0F291E),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text('🏝️', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '3×3 Starter Land',
                        style: TextStyle(
                          color: Color(0xFF1B6B44),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Text(
                  'Tap any floating block to inspect, store, or sell (80% recovery)',
                  style: TextStyle(
                    color: UrjaColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 5. 3D ISOMETRIC FLOATING BLOCKS (Coin Master / Sim Companies style)
              FloatingIsometricGrid(
                tiles: _tiles,
                gridSize: 3,
                onTileTap: _onTileTap,
              ),

              const SizedBox(height: 20),

              // 6. Impact Metric Card (CO2e saved & clean energy)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2EBE5)),
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

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
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
