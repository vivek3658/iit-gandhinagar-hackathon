import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';
import 'garden_3d_stage.dart';

/// Production 3D Floating Garden Island Screen (Pokémon GO / Wardrobe Studio Design).
///
/// Features:
/// - Double-finger pinch-to-zoom directly on 3D canvas with live scale tracking.
/// - Tactical 3×3 Grid Matrix Mini-Map HUD for instant, 100% accurate plot targeting.
/// - Pokémon GO / Wardrobe-Style Bottom Tray:
///   - Horizontal category chips (All, Flora, Energy, Water, Paths, Furniture, Inventory).
///   - Chunky claymorphic item cards carousel with live 3D preview-first placement.
/// - Placement Action Bar with Rotate 90°, Targeted Plot Badge, and Place/Deploy confirmation.
/// - Sparrow Eco Home cannot be removed/sold, only relocated to a free plot.
/// - Stored items from Inventory can be deployed for free at 0 🪙 cost.
class GardenIslandScreen extends StatefulWidget {
  final VoidCallback onScrollToSanctuary;

  const GardenIslandScreen({
    super.key,
    required this.onScrollToSanctuary,
  });

  @override
  State<GardenIslandScreen> createState() => _GardenIslandScreenState();
}

class _GardenIslandScreenState extends State<GardenIslandScreen> {
  final GameStateService _state = GameStateService.instance;
  final GlobalKey<Garden3DStageState> _gardenKey =
      GlobalKey<Garden3DStageState>();

  bool _isAutoSpin = false;
  bool _isTrayExpanded = true;
  int _selectedCategoryIndex = 0;

  // Camera zoom tracking
  double _currentZoom = 2.45;
  double _baseZoom = 2.45;

  // Targeted Plot State (Selected either by tapping 3D canvas or 3×3 Matrix HUD)
  Map<String, int>? _selectedPlotCoords; // {'x': 0, 'z': 1}

  // Selected Placed Tile State (Occupied plot info)
  Map<String, dynamic>? _selectedTile;

  // Active Placement Preview State (when picking an item from catalog)
  Map<String, dynamic>? _activePlacement; // {'x', 'z', 'item', 'rotation'}

  // Moving State (when user clicks Move on an existing object)
  Map<String, dynamic>? _tileBeingMoved; // {'fromX', 'fromZ', 'id', 'r', 'isHome'}

  final List<String> _categories = [
    'All',
    'Flora 🌷',
    'Energy ⚡',
    'Water ⛲',
    'Paths ⛩️',
    'Furniture 🪑',
    'Inventory 📦',
  ];

  final List<Map<String, dynamic>> _buildCatalog = [
    {
      'id': 'FLOWER_BED',
      'name': 'Fragrant Flower Bed',
      'cat': 'Flora 🌷',
      'price': 45,
      'icon': '🌷',
      'desc': 'Blooming marigolds and jasmine attracting native butterflies.',
    },
    {
      'id': 'TREE_LARGE',
      'name': 'Large Apple Tree',
      'cat': 'Flora 🌷',
      'price': 160,
      'icon': '🌳',
      'desc': 'Full shade canopy providing fruit and perching branches for sparrows.',
    },
    {
      'id': 'FREEDOM_TREE',
      'name': 'Canopy Tree',
      'cat': 'Flora 🌷',
      'price': 180,
      'icon': '🌸',
      'desc': 'Vibrant pink blossoming canopy celebrating nature.',
    },
    {
      'id': 'TULSI_KYARO',
      'name': 'Sacred Tulsi Altar',
      'cat': 'Flora 🌷',
      'price': 65,
      'icon': '🌿',
      'desc': 'Traditional medicinal sacred basil planter in terracotta pedestal.',
    },
    {
      'id': 'ROSE_BUSH',
      'name': 'Flowering Bush',
      'cat': 'Flora 🌷',
      'price': 50,
      'icon': '🌹',
      'desc': 'Lush hedge with vibrant red and pink blossoms.',
    },
    {
      'id': 'ROCK_BOULDER',
      'name': 'Zen Milestone Boulder',
      'cat': 'Flora 🌷',
      'price': 45,
      'icon': '🪨',
      'desc': 'Weathered granite boulder with mossy perches.',
    },
    {
      'id': 'SPARROW_BATH',
      'name': 'Bird Bath Fountain',
      'cat': 'Water ⛲',
      'price': 120,
      'icon': '⛲',
      'desc': 'Clean freshwater basin for sanctuary sparrows to drink and splash.',
    },
    {
      'id': 'POND_TILE',
      'name': 'Lily Pond Tile',
      'cat': 'Water ⛲',
      'price': 140,
      'icon': '🪷',
      'desc': 'Shimmering clear pool with pink water lilies and stone rim.',
    },
    {
      'id': 'WATER_WELL',
      'name': 'Stone Recharge Well',
      'cat': 'Water ⛲',
      'price': 220,
      'icon': '🚰',
      'desc': 'Traditional stone rainwater recharge well with timber roof.',
    },
    {
      'id': 'WOODEN_BRIDGE_TILE',
      'name': 'Garden Footbridge',
      'cat': 'Water ⛲',
      'price': 180,
      'icon': '🌉',
      'desc': 'Arched cedar footbridge spanning over garden waterways.',
    },
    {
      'id': 'SOLAR_STREET_LAMP',
      'name': 'Solar Lantern Post',
      'cat': 'Energy ⚡',
      'price': 110,
      'icon': '🏮',
      'desc': 'Clean solar-charged warm lantern glowing softly during twilight.',
    },
    {
      'id': 'SOLAR_PANEL_T1',
      'name': 'Mini Solar Flower',
      'cat': 'Energy ⚡',
      'price': 240,
      'icon': '☀️',
      'desc': 'Hexagonal tracking photovoltaic panel capturing solar rays.',
    },
    {
      'id': 'WINDMILL_RUSTIC',
      'name': 'Old Stone Windmill',
      'cat': 'Energy ⚡',
      'price': 450,
      'icon': '🌬️',
      'desc': 'Rustic wind-powered kinetic windmill celebrating Gujarat breezes.',
    },
    {
      'id': 'COMPOST_TUMBLER',
      'name': 'Organic Compost Bin',
      'cat': 'Energy ⚡',
      'price': 90,
      'icon': '♻️',
      'desc': 'Closed-loop tumbler converting garden leaves into rich soil.',
    },
    {
      'id': 'BIOGAS_DOME',
      'name': 'Village Bio-Digester',
      'cat': 'Energy ⚡',
      'price': 280,
      'icon': '🟢',
      'desc': 'Earthy dome bio-digester recycling kitchen greens into clean fuel.',
    },
    {
      'id': 'GARDEN_GATE',
      'name': 'Floral Garden Gate',
      'cat': 'Paths ⛩️',
      'price': 120,
      'icon': '⛩️',
      'desc': 'Wooden trellis arch covered in pink bougainvillea vines.',
    },
    {
      'id': 'STONE_PATH',
      'name': 'Cobblestone Way',
      'cat': 'Paths ⛩️',
      'price': 35,
      'icon': '🪨',
      'desc': 'Hand-hewn slate stones curving gracefully across the lawn.',
    },
    {
      'id': 'WOOD_PATH',
      'name': 'Timber Deck Tile',
      'cat': 'Paths ⛩️',
      'price': 40,
      'icon': '🪵',
      'desc': 'Warm cedar wood planks with antique iron nails.',
    },
    {
      'id': 'WOOD_FENCE',
      'name': 'Rustic Picket Fence',
      'cat': 'Paths ⛩️',
      'price': 30,
      'icon': '🪵',
      'desc': 'Charming low picket railing bordering wildflower beds.',
    },
    {
      'id': 'CAMPFIRE_PIT',
      'name': 'Cozy Sanctuary Campfire',
      'cat': 'Furniture 🪑',
      'price': 130,
      'icon': '🔥',
      'desc': 'Stone fire ring for evening sanctuary gatherings.',
    },
    {
      'id': 'RUSTIC_BENCH',
      'name': 'Garden Bench',
      'cat': 'Furniture 🪑',
      'price': 90,
      'icon': '🪑',
      'desc': 'Weathered cedar slat bench overlooking the sanctuary flowers.',
    },
    {
      'id': 'ZEN_STONE',
      'name': 'Zen Milestone',
      'cat': 'Furniture 🪑',
      'price': 110,
      'icon': '🧘',
      'desc': 'Polished balancing stone celebrating mind-body-nature harmony.',
    },
  ];

  Map<String, int>? _findFirstFreePlot() {
    const coords = [
      [-1, -1], [0, -1], [1, -1],
      [-1,  0],          [1,  0],
      [-1,  1], [0,  1], [1,  1],
    ];
    for (final c in coords) {
      final occupied = _state.gardenGridSlots.any(
        (s) => s['x'] == c[0] && s['z'] == c[1],
      );
      if (!occupied) return {'x': c[0], 'z': c[1]};
    }
    return null;
  }

  void _onTileTapped(Map<String, dynamic> data) {
    HapticFeedback.lightImpact();

    if (_tileBeingMoved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ That plot is already occupied. Tap an empty plot to relocate!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final x = data['x'] as int? ?? 0;
    final z = data['z'] as int? ?? 0;

    setState(() {
      _selectedPlotCoords = {'x': x, 'z': z};
      _selectedTile = data;
      _activePlacement = null;
    });
  }

  void _onEmptyTileTapped(int x, int z) {
    HapticFeedback.lightImpact();

    // 1. If currently moving an object
    if (_tileBeingMoved != null) {
      _executeMoveTo(x, z);
      return;
    }

    // 2. If an active placement item is selected
    if (_activePlacement != null) {
      final item = _activePlacement!['item'] as Map<String, dynamic>;
      final r = _activePlacement!['rotation'] as int;
      setState(() {
        _selectedPlotCoords = {'x': x, 'z': z};
        _activePlacement!['x'] = x;
        _activePlacement!['z'] = z;
      });
      _gardenKey.currentState?.previewPlacement(x, z, item['id'] as String, r);
      return;
    }

    // 3. Just selecting the empty plot
    setState(() {
      _selectedPlotCoords = {'x': x, 'z': z};
      _selectedTile = null;
    });
  }

  void _onMatrixSlotTapped(int x, int z, bool isOccupied, Map<String, dynamic> slotData) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPlotCoords = {'x': x, 'z': z};
    });

    // 1. If moving
    if (_tileBeingMoved != null) {
      if (isOccupied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Plot is already occupied! Select an empty plot.')),
        );
        return;
      }
      _executeMoveTo(x, z);
      return;
    }

    // 2. If placing a catalog item
    if (_activePlacement != null) {
      if (isOccupied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ That plot is occupied! Select a free plot (+)')),
        );
        return;
      }
      final item = _activePlacement!['item'] as Map<String, dynamic>;
      final r = _activePlacement!['rotation'] as int;
      setState(() {
        _activePlacement!['x'] = x;
        _activePlacement!['z'] = z;
      });
      _gardenKey.currentState?.previewPlacement(x, z, item['id'] as String, r);
      return;
    }

    // 3. Otherwise sync selection with 3D canvas
    if (isOccupied) {
      setState(() {
        _selectedTile = slotData;
      });
      _gardenKey.currentState?.selectPlot(x, z);
    } else {
      setState(() {
        _selectedTile = null;
      });
      _gardenKey.currentState?.selectPlot(x, z);
    }
  }

  void _executeMoveTo(int toX, int toZ) {
    final fromX = _tileBeingMoved!['fromX'] as int;
    final fromZ = _tileBeingMoved!['fromZ'] as int;
    final moved = _state.moveGardenTile(
      fromX: fromX,
      fromZ: fromZ,
      toX: toX,
      toZ: toZ,
    );
    if (moved) {
      _gardenKey.currentState?.moveTile(fromX, fromZ, toX, toZ);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Successfully relocated structure to new plot!'),
          backgroundColor: Color(0xFF1B6B44),
        ),
      );
    }
    setState(() {
      _tileBeingMoved = null;
      _selectedTile = null;
      _selectedPlotCoords = {'x': toX, 'z': toZ};
    });
  }

  void _onCatalogCardTapped(Map<String, dynamic> item) {
    HapticFeedback.selectionClick();

    // Determine target coordinates:
    int targetX = 0;
    int targetZ = 1;

    if (_selectedPlotCoords != null) {
      final isOccupied = _state.gardenGridSlots.any(
        (s) => s['x'] == _selectedPlotCoords!['x'] && s['z'] == _selectedPlotCoords!['z'],
      );
      if (!isOccupied) {
        targetX = _selectedPlotCoords!['x']!;
        targetZ = _selectedPlotCoords!['z']!;
      } else {
        final freePlot = _findFirstFreePlot();
        if (freePlot != null) {
          targetX = freePlot['x']!;
          targetZ = freePlot['z']!;
        }
      }
    } else {
      final freePlot = _findFirstFreePlot();
      if (freePlot != null) {
        targetX = freePlot['x']!;
        targetZ = freePlot['z']!;
      }
    }

    setState(() {
      _selectedPlotCoords = {'x': targetX, 'z': targetZ};
      _activePlacement = {
        'x': targetX,
        'z': targetZ,
        'item': item,
        'rotation': 0,
      };
      _selectedTile = null;
      _tileBeingMoved = null;
    });

    _gardenKey.currentState?.previewPlacement(
      targetX,
      targetZ,
      item['id'] as String,
      0,
    );
  }

  void _rotateActivePlacement() {
    if (_activePlacement == null) return;
    HapticFeedback.lightImpact();
    final curR = _activePlacement!['rotation'] as int;
    final nextR = (curR + 1) % 4;
    setState(() {
      _activePlacement!['rotation'] = nextR;
    });
    final x = _activePlacement!['x'] as int;
    final z = _activePlacement!['z'] as int;
    final item = _activePlacement!['item'] as Map<String, dynamic>;
    _gardenKey.currentState?.previewPlacement(
      x,
      z,
      item['id'] as String,
      nextR,
    );
  }

  void _cancelActivePlacement() {
    HapticFeedback.lightImpact();
    setState(() => _activePlacement = null);
    _gardenKey.currentState?.cancelPreview();
  }

  void _confirmPlacement() {
    if (_activePlacement == null) return;
    final x = _activePlacement!['x'] as int;
    final z = _activePlacement!['z'] as int;
    final item = _activePlacement!['item'] as Map<String, dynamic>;
    final rotation = _activePlacement!['rotation'] as int;
    final price = item['price'] as int;
    final isInventory = _state.gardenInventory.contains(item['id']) || item['cat'].toString().contains('Inventory') || price == 0;

    if (isInventory) {
      // Free deployment from personal inventory
      final deployed = _state.deployInventoryGardenTile(
        x: x,
        z: z,
        tileId: item['id'] as String,
        rotation: rotation,
      );
      if (deployed) {
        HapticFeedback.heavyImpact();
        _gardenKey.currentState?.confirmPlacement(x, z, item['id'] as String, rotation);
        setState(() => _activePlacement = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏡 Deployed "${item['name']}" from your inventory! (0 🪙 cost)'),
            backgroundColor: const Color(0xFF1B6B44),
          ),
        );
      }
      return;
    }

    if (_state.coins < price) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🪙 Not enough Urja Mudra ($price needed, you have ${_state.coins}). Complete eco habits to earn!'),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
      return;
    }

    final placed = _state.buyAndPlaceGardenTile(
      x: x,
      z: z,
      tileId: item['id'] as String,
      cost: price,
      rotation: rotation,
    );

    if (placed) {
      HapticFeedback.heavyImpact();
      _gardenKey.currentState?.confirmPlacement(x, z, item['id'] as String, rotation);
      setState(() => _activePlacement = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🏡 Placed ${item['name']} on your floating sanctuary!'),
          backgroundColor: const Color(0xFF1B6B44),
        ),
      );
    }
  }

  void _rotateSelectedTile() {
    if (_selectedTile == null) return;
    final x = _selectedTile!['x'] as int;
    final z = _selectedTile!['z'] as int;
    HapticFeedback.lightImpact();
    _state.rotateGardenTile(x, z);
    _gardenKey.currentState?.rotateTile(x, z);
  }

  void _startRelocatingTile() {
    if (_selectedTile == null) return;
    HapticFeedback.selectionClick();
    final x = _selectedTile!['x'] as int;
    final z = _selectedTile!['z'] as int;
    final isHome = _selectedTile!['isHome'] == true;

    setState(() {
      _tileBeingMoved = {
        'fromX': x,
        'fromZ': z,
        'id': _selectedTile!['id'],
        'r': _selectedTile!['r'] ?? 0,
        'isHome': isHome,
      };
      _selectedTile = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isHome
            ? '📍 Tap any empty green lawn plot (or matrix slot) to relocate your Sparrow Eco Home!'
            : '📍 Tap any empty green lawn plot to move this structure.'),
        backgroundColor: const Color(0xFF0F3822),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _storeSelectedTileInInventory() {
    if (_selectedTile == null) return;
    final x = _selectedTile!['x'] as int;
    final z = _selectedTile!['z'] as int;
    final isHome = _selectedTile!['isHome'] == true;
    final name = _selectedTile!['name'] as String? ?? 'Sanctuary Object';

    if (isHome) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛡️ Sparrow Eco Home cannot be removed or stored! It is the permanent centerpiece (can only be relocated).'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final stored = _state.storeGardenTileInInventory(x, z);
    if (stored) {
      _gardenKey.currentState?.removeTile(x, z);
      setState(() => _selectedTile = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📦 Stored "$name" in your Sanctuary Inventory! (Deploy it anytime for free)'),
          backgroundColor: const Color(0xFF1B6B44),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Atmospheric Background Sky Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFBAE6FD),
                      Color(0xFFD1FAE5),
                      Color(0xFFF8FAFC),
                    ],
                    stops: [0.0, 0.40, 0.90],
                  ),
                ),
              ),

              // Interactive 3D Canvas with Two-Finger Pinch-To-Zoom Gesture Detector
              Positioned.fill(
                child: GestureDetector(
                  onScaleStart: (details) {
                    _baseZoom = _currentZoom;
                  },
                  onScaleUpdate: (details) {
                    if (details.pointerCount >= 2) {
                      // Pinching: scale > 1 zooms in (closer view), scale < 1 zooms out
                      final targetZoom = (_baseZoom / details.scale).clamp(0.85, 5.5);
                      _currentZoom = targetZoom;
                      _gardenKey.currentState?.setZoom(targetZoom);
                    }
                  },
                  child: Garden3DStage(
                    key: _gardenKey,
                    onTileTapped: _onTileTapped,
                    onEmptyTileTapped: _onEmptyTileTapped,
                    onIslandUpdated: (slots) => _state.syncGardenGrid(slots),
                  ),
                ),
              ),

              // Top Floating Navigation Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: _buildTopBar(),
              ),

              // Camera Utilities (Auto-spin, Rotate 90°, Reset View)
              Positioned(
                top: MediaQuery.of(context).padding.top + 76,
                right: 16,
                child: _buildCameraToolsDock(),
              ),

              // Tactical 3×3 Grid Matrix Mini-Map HUD (Instant Snap Placement & Relocate)
              Positioned(
                top: MediaQuery.of(context).padding.top + 76,
                left: 16,
                child: _buildTacticalPlotMatrix(),
              ),

              // Relocating In-Progress Floating Banner
              if (_tileBeingMoved != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: _isTrayExpanded ? 248 : 66,
                  child: _buildMovingBanner(),
                ),

              // Selected Tile Action Sheet (Rotate, Move, Store)
              if (_selectedTile != null && _activePlacement == null && _tileBeingMoved == null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: _isTrayExpanded ? 248 : 66,
                  child: _buildSelectedTileCard(),
                ),

              // Pokémon GO / Wardrobe Placement Action Bar
              if (_activePlacement != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: _isTrayExpanded ? 248 : 66,
                  child: _buildPlacementBar(),
                ),

              // Pokémon GO / Wardrobe Style Bottom Tray
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildPokemonGoWardrobeTray(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
      ),
      child: Row(
        children: [
          // Return to Mascot Button
          InkWell(
            onTap: () {
              if (_state.soundEnabled) HapticFeedback.selectionClick();
              widget.onScrollToSanctuary();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF14532D), offset: Offset(0, 3)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 15),
                  SizedBox(width: 4),
                  Text(
                    'Mascot',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Star Crest Level Badge
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF78350F), offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Text(
                    '★ Lv 1',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Floating Island 🏝️',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Pinch to Zoom • Snap to Grid',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF86EFAC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chunky Coin Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xFF92400E), offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${_state.coins}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalPlotMatrix() {
    final lvl = _state.mascotLevel;
    final int radius = lvl >= 10 ? 3 : (lvl >= 5 ? 2 : 1);
    final int gridSize = radius * 2 + 1; // 3, 5, or 7
    final List<List<int>> coords = [];
    for (int z = -radius; z <= radius; z++) {
      for (int x = -radius; x <= radius; x++) {
        coords.add([x, z]);
      }
    }

    final double boxDimension = gridSize == 7 ? 126 : (gridSize == 5 ? 108 : 86);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2417).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF34D399), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: Text(
              '$gridSize×$gridSize GRID (LVL $lvl)',
              style: const TextStyle(
                color: Color(0xFF86EFAC),
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            width: boxDimension,
            height: boxDimension,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                crossAxisSpacing: gridSize > 3 ? 2.5 : 4,
                mainAxisSpacing: gridSize > 3 ? 2.5 : 4,
              ),
              itemCount: coords.length,
              itemBuilder: (ctx, idx) {
                final x = coords[idx][0];
                final z = coords[idx][1];
                final isTarget = _selectedPlotCoords != null &&
                    _selectedPlotCoords!['x'] == x &&
                    _selectedPlotCoords!['z'] == z;

                final slot = _state.gardenGridSlots.firstWhere(
                  (s) => s['x'] == x && s['z'] == z,
                  orElse: () => {},
                );
                final isOccupied = slot.isNotEmpty;
                final isHome = slot['id'] == 'SPARROW_HOME';

                String icon = '+';
                if (isHome) {
                  icon = '🏠';
                } else if (isOccupied) {
                  final found = _buildCatalog.firstWhere(
                    (c) => c['id'] == slot['id'],
                    orElse: () => {'icon': '🌿'},
                  );
                  icon = found['icon'] as String;
                }

                return GestureDetector(
                  onTap: () => _onMatrixSlotTapped(x, z, isOccupied, slot),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isTarget
                          ? const Color(0xFFF59E0B)
                          : (isOccupied
                              ? const Color(0xFF1E3A2B)
                              : const Color(0xFF0F3120)),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: isTarget
                            ? Colors.white
                            : (isOccupied ? const Color(0xFF34D399) : Colors.white24),
                        width: isTarget ? 2.0 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: TextStyle(
                          fontSize: gridSize > 3 ? (isOccupied ? 9 : 8) : (isOccupied ? 12 : 11),
                          color: isTarget
                              ? Colors.black
                              : (isOccupied ? Colors.white : Colors.white38),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraToolsDock() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDockIconButton(
            icon: Icons.rotate_right_rounded,
            tooltip: 'Rotate 90°',
            onTap: () {
              if (_state.soundEnabled) HapticFeedback.lightImpact();
              _gardenKey.currentState?.rotate90();
            },
          ),
          const SizedBox(height: 6),
          _buildDockIconButton(
            icon: _isAutoSpin
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_fill_rounded,
            color: _isAutoSpin
                ? const Color(0xFFF59E0B)
                : const Color(0xFF4ADE80),
            tooltip: 'Auto-Spin',
            onTap: () {
              if (_state.soundEnabled) HapticFeedback.selectionClick();
              setState(() => _isAutoSpin = !_isAutoSpin);
              _gardenKey.currentState?.toggleSpin();
            },
          ),
          const SizedBox(height: 6),
          _buildDockIconButton(
            icon: Icons.center_focus_strong_rounded,
            tooltip: 'Reset View',
            onTap: () {
              if (_state.soundEnabled) HapticFeedback.selectionClick();
              _currentZoom = 2.45;
              _gardenKey.currentState?.resetView();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDockIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildPokemonGoWardrobeTray() {
    final currentCategory = _categories[_selectedCategoryIndex];
    List<Map<String, dynamic>> itemsToShow;

    if (currentCategory == 'All') {
      itemsToShow = _buildCatalog;
    } else if (currentCategory.contains('Inventory')) {
      final inventoryIds = _state.gardenInventory;
      itemsToShow = inventoryIds.map((invId) {
        return _buildCatalog.firstWhere(
          (c) => c['id'] == invId,
          orElse: () => {
            'id': invId,
            'name': 'Stored Asset',
            'cat': 'Inventory 📦',
            'price': 0,
            'icon': '📦',
            'desc': 'Ready to deploy for free.',
          },
        );
      }).toList();
    } else {
      itemsToShow = _buildCatalog.where((c) => c['cat'] == currentCategory).toList();
    }

    return Container(
      height: _isTrayExpanded ? 236 : 50,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle & Expand toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isTrayExpanded = !_isTrayExpanded);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isTrayExpanded
                            ? 'Sanctuary Wardrobe Tray'
                            : 'Tap to Browse Structures 🌿',
                        style: const TextStyle(
                          color: const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isTrayExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: const Color(0xFF475569),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_isTrayExpanded) ...[
            // Category Chips (Horizontal Scroll)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final catName = _categories[i];
                  final isSelected = _selectedCategoryIndex == i;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategoryIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? const [BoxShadow(color: Color(0xFF14532D), offset: Offset(0, 2))]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          catName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Item Cards Horizontal Carousel
            Expanded(
              child: itemsToShow.isEmpty
                  ? const Center(
                      child: Text(
                        'No stored structures in inventory.\nStore placed structures to see them here!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      itemCount: itemsToShow.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, idx) {
                        final item = itemsToShow[idx];
                        return _buildCatalogItemCard(item);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCatalogItemCard(Map<String, dynamic> item) {
    final isSelected = _activePlacement != null &&
        (_activePlacement!['item'] as Map<String, dynamic>)['id'] == item['id'];
    final price = item['price'] as int;
    final isInventory = _state.gardenInventory.contains(item['id']) || item['cat'].toString().contains('Inventory') || price == 0;
    final canAfford = isInventory || _state.coins >= price;

    return GestureDetector(
      onTap: () => _onCatalogCardTapped(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 116,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0xFF78350F), offset: Offset(0, 3), blurRadius: 6)]
              : const [BoxShadow(color: Colors.black26, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(item['icon'] as String, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['name'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isInventory
                    ? const Color(0xFF22C55E)
                    : (canAfford ? const Color(0xFFF59E0B) : Colors.white12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isInventory ? 'Free 📦' : '$price 🪙',
                style: TextStyle(
                  color: (isInventory || canAfford) ? Colors.black : Colors.white38,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementBar() {
    final item = _activePlacement!['item'] as Map<String, dynamic>;
    final price = item['price'] as int;
    final x = _activePlacement!['x'] as int;
    final z = _activePlacement!['z'] as int;
    final isInventory = _state.gardenInventory.contains(item['id']) || item['cat'].toString().contains('Inventory') || price == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2416),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Text(item['icon'] as String, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A2B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Plot [$x, $z]',
                        style: const TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isInventory ? 'Free deploy' : '$price 🪙',
                      style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _rotateActivePlacement,
            icon: const Icon(Icons.rotate_90_degrees_ccw, size: 14),
            label: const Text('90°'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: _cancelActivePlacement,
            icon: const Icon(Icons.close, color: const Color(0xFF475569), size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: _confirmPlacement,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(
              isInventory ? 'Deploy ✓' : 'Place ✓',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovingBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF34D399), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Relocating Structure...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Tap any empty plot (+) in 3D or 3×3 Matrix.',
                  style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _tileBeingMoved = null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTileCard() {
    final name = _selectedTile!['name'] as String? ?? 'Sanctuary Object';
    final isHome = _selectedTile!['isHome'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2417),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF34D399)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isHome ? '🏡' : '🌿', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                      ),
                    ),
                    Text(
                      isHome
                          ? 'Sanctuary Centerpiece • Cannot be stored'
                          : 'Sanctuary Asset • Tap Move or Store',
                      style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedTile = null),
                icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rotateSelectedTile,
                  icon: const Icon(Icons.rotate_right_rounded, size: 15),
                  label: const Text('Rotate 90°', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startRelocatingTile,
                  icon: const Icon(Icons.open_with_rounded, size: 15),
                  label: const Text('Move', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B6B44),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (!isHome) ...[
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: _storeSelectedTileInInventory,
                  icon: const Icon(Icons.inventory_2_rounded, size: 15),
                  label: const Text('Store 📦', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
