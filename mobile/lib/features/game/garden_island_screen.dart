import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';
import 'garden_3d_stage.dart';

/// Production 3D Floating Garden Island Screen.
///
/// Features:
/// - Starts with ONLY the centerpiece Sparrow Eco Home; all other 8 plots are free.
/// - Garden objects do NOT generate fake CO2e or coins (purely decorative & sanctuary habitat).
/// - Double-finger pinch-to-zoom directly on 3D canvas (dock zoom buttons removed).
/// - Floating toggle for "Build Mode" <-> "Normal Mode".
/// - Tapping an empty plot in Build Mode opens the Build Catalog sheet with prices.
/// - Placement preview bar with Rotate 90° and "Place for X 🪙" confirmation.
/// - Sparrow Eco Home cannot be removed/sold, only relocated to a free plot.
/// - Empty blocks cannot be sold (no unlimited coin exploit).
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

  bool _isBuildMode = false;
  bool _isAutoSpin = false;

  // Selected tile state
  Map<String, dynamic>? _selectedTile; // Occupied tile info
  Map<String, int>? _selectedEmptyPlot; // {x, z}

  // Active Placement Preview State (when picking an item from catalog)
  Map<String, dynamic>? _activePlacement; // {x, z, item, rotation}

  // Moving State (when user clicks Move on an existing object)
  Map<String, dynamic>? _tileBeingMoved; // {fromX, fromZ, id, r}

  final List<Map<String, dynamic>> _buildCatalog = [
    {
      'id': 'FLOWER_BED',
      'name': 'Fragrant Flower Bed',
      'cat': 'Flora',
      'price': 20,
      'icon': '🌷',
      'desc': 'Blooming marigolds and jasmine attracting native butterflies.',
    },
    {
      'id': 'TREE_LARGE',
      'name': 'Large Apple Tree',
      'cat': 'Flora',
      'price': 40,
      'icon': '🌳',
      'desc': 'Full shade canopy providing fruit and perching branches for sparrows.',
    },
    {
      'id': 'GARDEN_GATE',
      'name': 'Floral Garden Gate',
      'cat': 'Paths',
      'price': 25,
      'icon': '⛩️',
      'desc': 'Wooden trellis arch covered in pink bougainvillea vines.',
    },
    {
      'id': 'SPARROW_BATH',
      'name': 'Bird Bath Fountain',
      'cat': 'Water',
      'price': 35,
      'icon': '⛲',
      'desc': 'Clean freshwater basin for sanctuary sparrows to drink and splash.',
    },
    {
      'id': 'SOLAR_STREET_LAMP',
      'name': 'Solar Lantern Post',
      'cat': 'Energy',
      'price': 30,
      'icon': '🏮',
      'desc': 'Clean solar-charged warm lantern glowing softly during twilight.',
    },
    {
      'id': 'WINDMILL_RUSTIC',
      'name': 'Old Stone Windmill',
      'cat': 'Energy',
      'price': 60,
      'icon': '🌬️',
      'desc': 'Rustic wind-powered kinetic windmill celebrating Gujarat breezes.',
    },
    {
      'id': 'ROCK_BOULDER',
      'name': 'Zen Milestone Boulder',
      'cat': 'Flora',
      'price': 15,
      'icon': '🪨',
      'desc': 'Weathered granite boulder with mossy perches.',
    },
    {
      'id': 'CAMPFIRE_PIT',
      'name': 'Cozy Sanctuary Campfire',
      'cat': 'Furniture',
      'price': 25,
      'icon': '🔥',
      'desc': 'Stone fire ring for evening sanctuary gatherings.',
    },
    {
      'id': 'COMPOST_TUMBLER',
      'name': 'Organic Compost Bin',
      'cat': 'Energy',
      'price': 30,
      'icon': '♻️',
      'desc': 'Closed-loop tumbler converting garden leaves into rich soil.',
    },
  ];

  void _toggleBuildMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isBuildMode = !_isBuildMode;
      _selectedTile = null;
      _selectedEmptyPlot = null;
      _activePlacement = null;
      _tileBeingMoved = null;
    });
    _gardenKey.currentState?.setBuildMode(_isBuildMode);
  }

  void _onTileTapped(Map<String, dynamic> data) {
    HapticFeedback.lightImpact();

    // If we were in the middle of moving a tile and tapped an occupied tile
    if (_tileBeingMoved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ That plot is already occupied. Tap an empty green lawn plot to move!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedTile = data;
      _selectedEmptyPlot = null;
      _activePlacement = null;
    });
  }

  void _onEmptyTileTapped(int x, int z) {
    HapticFeedback.lightImpact();

    // 1. If we are currently moving a tile
    if (_tileBeingMoved != null) {
      final fromX = _tileBeingMoved!['fromX'] as int;
      final fromZ = _tileBeingMoved!['fromZ'] as int;
      final moved = _state.moveGardenTile(
        fromX: fromX,
        fromZ: fromZ,
        toX: x,
        toZ: z,
      );
      if (moved) {
        _gardenKey.currentState?.moveTile(fromX, fromZ, x, z);
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
        _selectedEmptyPlot = null;
      });
      return;
    }

    // 2. If in Build Mode: open the Build Catalog bottom sheet
    setState(() {
      _selectedEmptyPlot = {'x': x, 'z': z};
      _selectedTile = null;
      _activePlacement = null;
    });

    if (_isBuildMode) {
      _openBuildCatalogSheet(x, z);
    }
  }

  void _openBuildCatalogSheet(int x, int z) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.70,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0C2417),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Garden Sanctuary Catalog',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Select an item to place on this free plot',
                        style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(
                          '${_state.coins}',
                          style: const TextStyle(
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _buildCatalog.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final item = _buildCatalog[i];
                  final price = item['price'] as int;
                  final canAfford = _state.coins >= price;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _startPlacementPreview(x, z, item);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF143522),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                item['icon'] as String,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['desc'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? const Color(0xFF22C55E)
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$price 🪙',
                              style: TextStyle(
                                color: canAfford ? Colors.black : Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startPlacementPreview(int x, int z, Map<String, dynamic> item) {
    HapticFeedback.selectionClick();
    setState(() {
      _activePlacement = {
        'x': x,
        'z': z,
        'item': item,
        'rotation': 0,
      };
    });
    _gardenKey.currentState?.previewPlacement(
      x,
      z,
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

    if (_state.coins < price) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🪙 Not enough Urja Mudra coins ($price needed, you have ${_state.coins}). Complete eco habits to earn!'),
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
      _gardenKey.currentState?.confirmPlacement(
        x,
        z,
        item['id'] as String,
        rotation,
      );
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
            ? '📍 Select any empty green lawn plot to relocate your Sparrow Eco Home!'
            : '📍 Select any empty green lawn plot to move this structure.'),
        backgroundColor: const Color(0xFF0F3822),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _demolishSelectedTile() {
    if (_selectedTile == null) return;
    final x = _selectedTile!['x'] as int;
    final z = _selectedTile!['z'] as int;
    final isHome = _selectedTile!['isHome'] == true;

    if (isHome) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛡️ Sparrow Eco Home cannot be removed! It is the eternal sanctuary centerpiece.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _state.demolishGardenTile(x, z);
    _gardenKey.currentState?.removeTile(x, z);
    setState(() => _selectedTile = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧹 Cleared structure. Plot returned to natural green lawn.'),
        backgroundColor: Color(0xFF374151),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF081C12),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Atmospheric Background Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFBAE6FD),
                      Color(0xFFD1FAE5),
                      Color(0xFF081C12),
                    ],
                    stops: [0.0, 0.40, 0.90],
                  ),
                ),
              ),

              // Interactive 3D Garden Island Canvas
              Garden3DStage(
                key: _gardenKey,
                onTileTapped: _onTileTapped,
                onEmptyTileTapped: _onEmptyTileTapped,
                onIslandUpdated: (slots) => _state.syncGardenGrid(slots),
              ),

              // Top Floating Navigation Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: _buildTopBar(),
              ),

              // Minimal Camera Utilities (Rotate 90°, Auto-spin, Reset) — NO ZOOM BUTTONS
              Positioned(
                top: MediaQuery.of(context).padding.top + 76,
                right: 16,
                child: _buildCameraToolsDock(),
              ),

              // Build Mode Toggle Pill (Floating Bottom Left)
              Positioned(
                bottom: 24,
                left: 16,
                child: _buildBuildModeTogglePill(),
              ),

              // Placement Preview Confirmation Bar
              if (_activePlacement != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 84,
                  child: _buildPlacementBar(),
                ),

              // Moving In-Progress Banner
              if (_tileBeingMoved != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 84,
                  child: _buildMovingBanner(),
                ),

              // Selected Placed Object Info & Action Card
              if (_selectedTile != null && _activePlacement == null && _tileBeingMoved == null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 84,
                  child: _buildSelectedTileCard(),
                ),

              // Selected Empty Plot Card (when not in placement)
              if (_selectedEmptyPlot != null && !_isBuildMode && _selectedTile == null && _activePlacement == null && _tileBeingMoved == null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 84,
                  child: _buildEmptyPlotPromptCard(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F2B1A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0x221B6B44)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (_state.soundEnabled) HapticFeedback.selectionClick();
              widget.onScrollToSanctuary();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B6B44),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Mascot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isBuildMode ? 'Sanctuary Architect 🔨' : 'Floating Island 🏝️',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F2B1A),
                  ),
                ),
                Text(
                  _isBuildMode ? 'Tap free plots to build' : 'Pinch with 2 fingers to zoom',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 13)),
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

  Widget _buildCameraToolsDock() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2416).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0x3334D399)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rotate 90°
          _buildDockIconButton(
            icon: Icons.rotate_right_rounded,
            tooltip: 'Rotate 90°',
            onTap: () {
              if (_state.soundEnabled) HapticFeedback.lightImpact();
              _gardenKey.currentState?.rotate90();
            },
          ),
          const SizedBox(height: 6),
          // Auto-Spin toggle
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
          // Reset View
          _buildDockIconButton(
            icon: Icons.center_focus_strong_rounded,
            tooltip: 'Reset View',
            onTap: () {
              if (_state.soundEnabled) HapticFeedback.selectionClick();
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

  Widget _buildBuildModeTogglePill() {
    return GestureDetector(
      onTap: _toggleBuildMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isBuildMode ? const Color(0xFF22C55E) : const Color(0xFF0F3120),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isBuildMode ? Colors.white : const Color(0xFF34D399),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isBuildMode ? Icons.check_circle : Icons.construction,
              color: _isBuildMode ? Colors.black : Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _isBuildMode ? '✓ Done Building' : '🔨 Build Mode',
              style: TextStyle(
                color: _isBuildMode ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Text(item['icon'] as String, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Cost: $price 🪙 Urja Mudra',
                  style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: _cancelActivePlacement,
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
          ElevatedButton(
            onPressed: _confirmPlacement,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Place', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMovingBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF34D399), width: 1.5),
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
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Tap any empty green lawn plot to place it there.',
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
    final cat = _selectedTile!['cat'] as String? ?? 'Sanctuary';
    final isHome = _selectedTile!['isHome'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isHome
                          ? 'Sanctuary Centerpiece • Cannot be sold'
                          : '$cat Asset • Beautiful Wildlife Habitat',
                      style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedTile = null),
                icon: const Icon(Icons.close, color: Colors.white60, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Rotate 90 deg
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rotateSelectedTile,
                  icon: const Icon(Icons.rotate_right_rounded, size: 16),
                  label: const Text('Rotate 90°'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Move
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startRelocatingTile,
                  icon: const Icon(Icons.open_with_rounded, size: 16),
                  label: const Text('Move'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B6B44),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              // Demolish (only for non-home)
              if (!isHome) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _demolishSelectedTile,
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF87171)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlotPromptCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3120),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Free Sanctuary Lawn Plot',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Switch to Build Mode to place trees, fountains & lanterns!',
                  style: TextStyle(color: Color(0xFF86EFAC), fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _toggleBuildMode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Build Here', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
