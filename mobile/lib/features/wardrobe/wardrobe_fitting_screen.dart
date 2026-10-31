import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/game_state_service.dart';
import '../game/sparrow_3d_stage.dart';

/// Production 3D Wardrobe Fitting Studio with Preview-First Confirmation Flow.
///
/// Features:
/// - Tap to PREVIEW on 3D sparrow without purchasing.
/// - Clear Buy & Wear confirmation bar like Fortnite / Animal Crossing.
/// - Full catalog of official accessories from EcoNest Sparrow 3D.
/// - Level lock protection and coin balance validation.
class WardrobeFittingScreen extends StatefulWidget {
  final VoidCallback onBackToSanctuary;

  const WardrobeFittingScreen({
    super.key,
    required this.onBackToSanctuary,
  });

  @override
  State<WardrobeFittingScreen> createState() => _WardrobeFittingScreenState();
}

class _WardrobeFittingScreenState extends State<WardrobeFittingScreen> {
  final GameStateService _state = GameStateService.instance;
  final GlobalKey<Sparrow3DStageState> _sparrowKey =
      GlobalKey<Sparrow3DStageState>();

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Hats', 'Face', 'Neck', 'Held', 'Outfits'];

  // Current preview state (item selected to preview before purchase/equip)
  Map<String, dynamic>? _previewItem;

  final Map<String, List<Map<String, dynamic>>> _catalog = {
    'Hats': [
      {
        'id': 'straw',
        'slot': 'head',
        'key': 'straw',
        'name': 'Eco Straw Sunhat',
        'icon': '👒',
        'price': 150,
        'reqLevel': 1,
        'desc': 'Woven natural straw hat for sunny Gujarat days',
      },
      {
        'id': 'acorn',
        'slot': 'head',
        'key': 'acorn',
        'name': 'Acorn Cap Beret',
        'icon': '🌰',
        'price': 130,
        'reqLevel': 1,
        'desc': 'Wild acorn cap with autumn leaf crest',
      },
      {
        'id': 'beanie',
        'slot': 'head',
        'key': 'beanie',
        'name': 'Cozy Knit Beanie',
        'icon': '🧶',
        'price': 160,
        'reqLevel': 1,
        'desc': 'Warm knit cap from upcycled organic cotton',
      },
      {
        'id': 'flowers',
        'slot': 'head',
        'key': 'flowers',
        'name': 'Floral Spring Crown',
        'icon': '🌸',
        'price': 140,
        'reqLevel': 1,
        'desc': 'Fresh blossom plumeria and jasmine wreath',
      },
      {
        'id': 'rainhat',
        'slot': 'head',
        'key': 'rainhat',
        'name': 'Yellow Rainhat',
        'icon': '🌧️',
        'price': 150,
        'reqLevel': 1,
        'desc': 'Waterproof yellow rainhat with wide brim',
      },
      {
        'id': 'santa',
        'slot': 'head',
        'key': 'santa',
        'name': 'Festive Santa Hat',
        'icon': '🎅',
        'price': 180,
        'reqLevel': 2,
        'desc': 'Holiday celebratory cap with fluffy pom-pom',
      },
    ],
    'Face': [
      {
        'id': 'readers',
        'slot': 'face',
        'key': 'readers',
        'name': 'Round Readers Glasses',
        'icon': '👓',
        'price': 80,
        'reqLevel': 1,
        'desc': 'Vintage tortoiseshell circular frames',
      },
      {
        'id': 'sunnies',
        'slot': 'face',
        'key': 'sunnies',
        'name': 'Solar UV Sunglasses',
        'icon': '🕶️',
        'price': 90,
        'reqLevel': 1,
        'desc': 'Dark polarized glasses for summer sunshine',
      },
    ],
    'Neck': [
      {
        'id': 'plaid',
        'slot': 'neck',
        'key': 'plaid',
        'name': 'Autumn Plaid Scarf',
        'icon': '🍂',
        'price': 100,
        'reqLevel': 1,
        'desc': 'Warm orange checkered autumn muffler',
      },
      {
        'id': 'knit',
        'slot': 'neck',
        'key': 'knit',
        'name': 'Wool Knit Scarf',
        'icon': '🧣',
        'price': 100,
        'reqLevel': 1,
        'desc': 'Soft wrap muffler from organic wool',
      },
      {
        'id': 'bow',
        'slot': 'neck',
        'key': 'bow',
        'name': 'Dapper Bow Tie',
        'icon': '🎀',
        'price': 70,
        'reqLevel': 1,
        'desc': 'Neat green bow tie for formal occasions',
      },
      {
        'id': 'collar',
        'slot': 'neck',
        'key': 'collar',
        'name': 'Water Drop Collar',
        'icon': '🔔',
        'price': 80,
        'reqLevel': 1,
        'desc': 'Neat blue band with water conservation droplet',
      },
      {
        'id': 'lei',
        'slot': 'neck',
        'key': 'lei',
        'name': 'Tropical Lei',
        'icon': '🌺',
        'price': 90,
        'reqLevel': 1,
        'desc': 'Fragrant garland of plumeria flowers',
      },
      {
        'id': 'xmas',
        'slot': 'neck',
        'key': 'xmas',
        'name': 'Holiday Scarf',
        'icon': '🎄',
        'price': 110,
        'reqLevel': 2,
        'desc': 'Festive red & white holiday knitted scarf',
      },
    ],
    'Held': [
      {
        'id': 'leafbrella',
        'slot': 'held',
        'key': 'leafbrella',
        'name': 'Dewy Leaf Umbrella',
        'icon': '🍃',
        'price': 170,
        'reqLevel': 2,
        'desc': 'Oversized lotus leaf shelter with rain droplets',
      },
      {
        'id': 'umbrella',
        'slot': 'held',
        'key': 'umbrella',
        'name': 'Classic Rain Umbrella',
        'icon': '☔',
        'price': 140,
        'reqLevel': 1,
        'desc': 'Sturdy eco umbrella for monsoon rains',
      },
    ],
    'Outfits': [
      {
        'id': 'none',
        'name': 'Natural Plumage',
        'icon': '🕊️',
        'price': 0,
        'reqLevel': 1,
        'desc': 'Pure wild Gujarati sparrow plumage',
        'slots': {'head': null, 'face': null, 'neck': null, 'held': null},
      },
      {
        'id': 'autumn',
        'name': 'Autumn Harvest',
        'icon': '🍁',
        'price': 250,
        'reqLevel': 1,
        'desc': 'Acorn cap, round readers & plaid scarf set',
        'slots': {'head': 'acorn', 'face': 'readers', 'neck': 'plaid', 'held': null},
      },
      {
        'id': 'winter',
        'name': 'Winter Cozy',
        'icon': '❄️',
        'price': 260,
        'reqLevel': 1,
        'desc': 'Wool beanie & knit scarf winter warmth set',
        'slots': {'head': 'beanie', 'face': null, 'neck': 'knit', 'held': null},
      },
      {
        'id': 'rainy',
        'name': 'Monsoon Splash',
        'icon': '🌧️',
        'price': 280,
        'reqLevel': 1,
        'desc': 'Yellow rainhat, collar & dewy leaf umbrella set',
        'slots': {'head': 'rainhat', 'face': null, 'neck': 'collar', 'held': 'leafbrella'},
      },
      {
        'id': 'spring',
        'name': 'Spring Blossom',
        'icon': '🌸',
        'price': 210,
        'reqLevel': 1,
        'desc': 'Floral crown and dapper bow tie ensemble',
        'slots': {'head': 'flowers', 'face': null, 'neck': 'bow', 'held': null},
      },
      {
        'id': 'summer',
        'name': 'Summer Breeze',
        'icon': '🕶️',
        'price': 240,
        'reqLevel': 1,
        'desc': 'Straw hat, sunglasses & tropical lei set',
        'slots': {'head': 'straw', 'face': 'sunnies', 'neck': 'lei', 'held': null},
      },
    ],
  };

  void _onSelectPreview(Map<String, dynamic> item) {
    HapticFeedback.selectionClick();
    setState(() => _previewItem = item);

    final isOutfit = item.containsKey('slots');
    if (isOutfit) {
      _sparrowKey.currentState?.previewOutfit(item['id'] as String);
    } else {
      final slot = item['slot'] as String;
      final key = item['key'] as String;
      _sparrowKey.currentState?.preview(slot, key);
    }
  }

  void _cancelPreview() {
    HapticFeedback.lightImpact();
    setState(() => _previewItem = null);
    _sparrowKey.currentState?.cancelPreview();
  }

  void _confirmPurchaseOrEquip() {
    if (_previewItem == null) return;
    final item = _previewItem!;
    final itemId = item['id'] as String;
    final isOutfit = item.containsKey('slots');
    final price = item['price'] as int;
    final reqLevel = item['reqLevel'] as int;

    // 1. Level Check
    if (_state.mascotLevel < reqLevel) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Locked! Reach Level $reqLevel with real CO2e savings to unlock.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    final isOwned = isOutfit ? (price == 0) : _state.ownedItems.contains(itemId);

    // 2. Purchase if unowned
    if (!isOwned) {
      if (_state.coins < price) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🪙 Not enough Urja Mudra coins ($price needed, you have ${_state.coins}). Complete green actions to earn!'),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
        return;
      }

      // Deduct coins & add to inventory
      final bought = _state.buyAccessory(
        itemId: itemId,
        price: price,
        requiredLevel: reqLevel,
      );
      if (!bought) return;
    }

    // 3. Equip Permanently
    HapticFeedback.mediumImpact();
    if (isOutfit) {
      final slots = Map<String, String?>.from(item['slots'] as Map);
      _state.equipOutfit(itemId, slots);
      _sparrowKey.currentState?.dress(itemId);
    } else {
      final slot = item['slot'] as String;
      final key = item['key'] as String;
      _state.equipItem(slot, key);
      _sparrowKey.currentState?.wear(slot, key);
    }

    _sparrowKey.currentState?.setExpression('excited');
    setState(() => _previewItem = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Equipped ${item['name']}! Looking fantastic!'),
        backgroundColor: const Color(0xFF1B6B44),
      ),
    );
  }

  void _takeOffPreviewedItem() {
    if (_previewItem == null) return;
    final item = _previewItem!;
    final isOutfit = item.containsKey('slots');
    HapticFeedback.lightImpact();

    if (isOutfit) {
      _state.equipOutfit('none', {'head': null, 'face': null, 'neck': null, 'held': null});
      _sparrowKey.currentState?.dress('none');
    } else {
      final slot = item['slot'] as String;
      _state.equipItem(slot, null);
      _sparrowKey.currentState?.wear(slot, null);
    }

    setState(() => _previewItem = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final currentCategory = _categories[_selectedCategoryIndex];
        final currentList = _catalog[currentCategory] ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFF071B11),
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
                      Color(0xFF0F2619),
                    ],
                    stops: [0.0, 0.38, 0.85],
                  ),
                ),
              ),

              // 3D Sparrow Stage
              Positioned(
                top: 36,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.44,
                child: Sparrow3DStage(key: _sparrowKey),
              ),

              // Top Bar Navigation
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: _buildTopBar(),
              ),

              // Bottom Catalog & Shop Sheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).size.height * 0.52,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A2216),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tabs
                      _buildCategoryTabs(),
                      const SizedBox(height: 10),

                      // Items Grid
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.65,
                          ),
                          itemCount: currentList.length,
                          itemBuilder: (ctx, i) {
                            final item = currentList[i];
                            return _buildItemCard(item);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Preview-First Confirmation Bottom Bar
              if (_previewItem != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: _buildPreviewActionBar(),
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
        color: const Color(0xFF0F2B1A).withValues(alpha: 0.95),
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
          // 3D Return Button
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onBackToSanctuary();
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
                  Icon(Icons.arrow_back_rounded, color: Colors.black, size: 15),
                  SizedBox(width: 4),
                  Text(
                    'Sanctuary',
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

          // Star Crest Level Badge (Coin Master / Clash of Clans)
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF78350F), offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Text(
                    '★ Lv 1',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Urja Wardrobe Studio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Tap to Preview • Confirm to Buy',
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

          // Chunky 3D Coin Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final isSelected = _selectedCategoryIndex == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategoryIndex = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF143522),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFDE68A) : Colors.white12,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? const [BoxShadow(color: Color(0xFF92400E), offset: Offset(0, 3))]
                    : const [BoxShadow(color: Colors.black26, offset: Offset(0, 2))],
              ),
              child: Center(
                child: Text(
                  _categories[i],
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    final isOutfit = item.containsKey('slots');
    final name = item['name'] as String;
    final icon = item['icon'] as String;
    final price = item['price'] as int;
    final reqLevel = item['reqLevel'] as int;

    final isLocked = _state.mascotLevel < reqLevel;
    final isOwned = isOutfit ? (price == 0) : _state.ownedItems.contains(itemId);
    final isPreviewing = _previewItem != null && _previewItem!['id'] == itemId;

    bool isEquipped = false;
    if (isOutfit) {
      isEquipped = _state.equippedOutfit == itemId;
    } else {
      final slot = item['slot'] as String;
      final key = item['key'] as String;
      if (slot == 'head') isEquipped = _state.equippedHead == key;
      if (slot == 'face') isEquipped = _state.equippedFace == key;
      if (slot == 'neck') isEquipped = _state.equippedNeck == key;
      if (slot == 'held') isEquipped = _state.equippedHeld == key;
    }

    Color borderColor = Colors.white12;
    Color bgColor = const Color(0xFF122C1D);

    if (isPreviewing) {
      borderColor = const Color(0xFFFBBF24); // Golden preview glow
      bgColor = const Color(0xFF24482F);
    } else if (isEquipped) {
      borderColor = const Color(0xFF22C55E); // Green equipped border
      bgColor = const Color(0xFF18422A);
    }

    return GestureDetector(
      onTap: () => _onSelectPreview(item),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isPreviewing ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isPreviewing)
                    const Text(
                      '👁️ Previewing...',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (isEquipped)
                    const Text(
                      '✓ Wearing',
                      style: TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (isLocked)
                    Text(
                      '🔒 Lv $reqLevel Req',
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (isOwned)
                    const Text(
                      'Owned • Tap Preview',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    )
                  else
                    Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 2),
                        Text(
                          '$price',
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewActionBar() {
    final item = _previewItem!;
    final itemId = item['id'] as String;
    final isOutfit = item.containsKey('slots');
    final name = item['name'] as String;
    final price = item['price'] as int;
    final reqLevel = item['reqLevel'] as int;

    final isLocked = _state.mascotLevel < reqLevel;
    final isOwned = isOutfit ? (price == 0) : _state.ownedItems.contains(itemId);

    bool isEquipped = false;
    if (isOutfit) {
      isEquipped = _state.equippedOutfit == itemId;
    } else {
      final slot = item['slot'] as String;
      final key = item['key'] as String;
      if (slot == 'head') isEquipped = _state.equippedHead == key;
      if (slot == 'face') isEquipped = _state.equippedFace == key;
      if (slot == 'neck') isEquipped = _state.equippedNeck == key;
      if (slot == 'held') isEquipped = _state.equippedHeld == key;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isOwned
                      ? (isEquipped ? 'Currently Worn' : 'Owned Item')
                      : (isLocked
                          ? 'Locked (Lv $reqLevel Required)'
                          : 'Price: $price 🪙 Urja Mudra'),
                  style: TextStyle(
                    color: isLocked ? const Color(0xFFF87171) : const Color(0xFF86EFAC),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Cancel Preview Button
          OutlinedButton(
            onPressed: _cancelPreview,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),

          // Action Button (Buy & Wear OR Wear / Take Off)
          if (isEquipped)
            ElevatedButton(
              onPressed: _takeOffPreviewedItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B5563),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Take Off', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton.icon(
              onPressed: isLocked ? null : _confirmPurchaseOrEquip,
              icon: Icon(
                isOwned ? Icons.check : Icons.shopping_bag_outlined,
                size: 14,
              ),
              label: Text(
                isOwned ? 'Wear Now' : 'Buy ($price 🪙)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked ? Colors.grey : const Color(0xFF22C55E),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }
}
