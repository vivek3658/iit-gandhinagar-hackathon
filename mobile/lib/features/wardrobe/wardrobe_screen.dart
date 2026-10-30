import 'package:flutter/material.dart';
import 'models/wardrobe_models.dart';
import 'widgets/expressions_carousel.dart';
import 'widgets/interactive_mascot_stage.dart';
import 'widgets/item_picker_grid.dart';
import 'widgets/outfit_presets_row.dart';
import 'widgets/try_on_purchase_bar.dart';

class WardrobeScreen extends StatefulWidget {
  final int initialCoins;
  final ValueChanged<int>? onCoinsChanged;
  final ValueChanged<Map<String, String?>>? onEquippedChanged;

  const WardrobeScreen({
    super.key,
    this.initialCoins = 500,
    this.onCoinsChanged,
    this.onEquippedChanged,
  });

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late int _coins;

  // Starter owned items matching EcoNest HTML: ['acorn', 'readers', 'plaid', 'leaves']
  final List<String> _ownedItems = [
    'acorn',
    'readers',
    'plaid',
    'leaves',
  ];

  // Currently equipped items
  Map<String, String?> _equipped = {
    'head': 'acorn',
    'face': 'readers',
    'neck': 'plaid',
    'held': null,
    'fx': 'leaves',
  };

  // Backed up equipped state before starting a "try-on" session
  Map<String, String?>? _preTryOnEquipped;
  String? _tryOnTitle;
  int _tryOnCost = 0;
  List<String> _tryOnPendingItemIds = [];

  // Active pose/expression
  MascotPoseDef _currentPose = WardrobeCatalog.poses.first;

  @override
  void initState() {
    super.initState();
    _coins = widget.initialCoins;
  }

  void _addDemoCoins() {
    setState(() {
      _coins += 100;
    });
    widget.onCoinsChanged?.call(_coins);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Received +100 Urja Mudra coins! 🪙'),
        backgroundColor: Color(0xFF5F8F2E),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  void _onPetSparrow() {
    setState(() {
      _currentPose = WardrobeCatalog.poses.firstWhere((p) => p.id == 'petted');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chirp! You petted Chirpy! 💖 +5 Vitality'),
        backgroundColor: Color(0xFF5F8F2E),
        duration: Duration(milliseconds: 1200),
      ),
    );

    // Return to happy after 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted && _currentPose.id == 'petted') {
        setState(() {
          _currentPose = WardrobeCatalog.poses.first;
        });
      }
    });
  }

  void _onSelectPose(MascotPoseDef pose) {
    setState(() {
      _currentPose = pose;
    });
  }

  void _onSelectOutfit(OutfitDef outfit) {
    if (outfit.id == 'none') {
      _cancelTryOn();
      setState(() {
        _equipped = {
          'head': null,
          'face': null,
          'neck': null,
          'held': null,
          'fx': null,
        };
      });
      widget.onEquippedChanged?.call(_equipped);
      return;
    }

    final missingItems = outfit.allItems.where((id) => !_ownedItems.contains(id)).toList();

    if (missingItems.isEmpty) {
      // User owns all items! Equip them directly
      _cancelTryOn();
      setState(() {
        _equipped = {
          'head': outfit.head,
          'face': outfit.face,
          'neck': outfit.neck,
          'held': outfit.held,
          'fx': outfit.fx,
        };
      });
      widget.onEquippedChanged?.call(_equipped);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Equipped ${outfit.name} set! 🌿'),
          backgroundColor: const Color(0xFF5F8F2E),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    } else {
      // Activate try-on mode with 10% bundle discount!
      _startTryOn(
        title: '${outfit.name} Set (${missingItems.length} new items · 10% off)',
        items: missingItems,
        applyBundleDiscount: true,
        previewEquipped: {
          'head': outfit.head,
          'face': outfit.face,
          'neck': outfit.neck,
          'held': outfit.held,
          'fx': outfit.fx,
        },
      );
    }
  }

  void _onItemTapped(WardrobeItemDef? item) {
    if (item == null) {
      // Unequip currently selected category slot
      _cancelTryOn();
      // Notice: ItemPickerGrid passes null when citizen taps "None"
      return;
    }

    final isOwned = _ownedItems.contains(item.id);

    if (isOwned) {
      // Already owned: equip or toggle off
      _cancelTryOn();
      setState(() {
        final currentInSlot = _equipped[item.slot];
        if (currentInSlot == item.id) {
          _equipped[item.slot] = null; // Unequip
        } else {
          _equipped[item.slot] = item.id; // Equip
        }
      });
      widget.onEquippedChanged?.call(_equipped);
    } else {
      // Not owned: Enter Try-On mode
      _startTryOn(
        title: 'Trying on ${item.name}',
        items: [item.id],
        applyBundleDiscount: false,
        previewEquipped: {
          ..._equipped,
          item.slot: item.id,
        },
      );
    }
  }

  void _startTryOn({
    required String title,
    required List<String> items,
    required bool applyBundleDiscount,
    required Map<String, String?> previewEquipped,
  }) {
    _preTryOnEquipped ??= Map<String, String?>.from(_equipped);

    int rawCost = 0;
    for (final id in items) {
      final def = WardrobeCatalog.findItem(id);
      if (def != null) rawCost += def.price;
    }

    final finalCost = applyBundleDiscount ? (rawCost * 0.9).round() : rawCost;

    setState(() {
      _tryOnTitle = title;
      _tryOnCost = finalCost;
      _tryOnPendingItemIds = items;
      _equipped = previewEquipped;
    });
  }

  void _cancelTryOn() {
    if (_preTryOnEquipped != null) {
      setState(() {
        _equipped = Map<String, String?>.from(_preTryOnEquipped!);
        _preTryOnEquipped = null;
        _tryOnTitle = null;
        _tryOnCost = 0;
        _tryOnPendingItemIds = [];
      });
    }
  }

  void _confirmPurchase() {
    if (_coins < _tryOnCost) return;

    setState(() {
      _coins -= _tryOnCost;
      for (final id in _tryOnPendingItemIds) {
        if (!_ownedItems.contains(id)) {
          _ownedItems.add(id);
        }
      }
      _preTryOnEquipped = null; // Keep the newly equipped pieces
      _tryOnTitle = null;
      _tryOnCost = 0;
      _tryOnPendingItemIds = [];
    });

    widget.onCoinsChanged?.call(_coins);
    widget.onEquippedChanged?.call(_equipped);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Purchase confirmed! Items permanently unlocked & equipped! 🎉'),
        backgroundColor: Color(0xFF5F8F2E),
        duration: Duration(milliseconds: 1800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInTryOn = _tryOnTitle != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E3), // Warm linen from EcoNest HTML
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
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
                                color: Color(0xFF2F4A2A),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text('👗', style: TextStyle(fontSize: 18)),
                          ],
                        ),

                        // Coins pill + earn demo button
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE3D8BD)),
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
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _addDemoCoins,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5F8F2E),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  '+100',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Mascot Stage
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: InteractiveMascotStage(
                      equipped: _equipped,
                      currentPose: _currentPose,
                      onPet: _onPetSparrow,
                      height: 290,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Expressions Carousel
                  ExpressionsCarousel(
                    activePoseId: _currentPose.id,
                    onSelectPose: _onSelectPose,
                  ),

                  const SizedBox(height: 18),

                  // Outfit Presets (Seasonal sets with 10% discount)
                  OutfitPresetsRow(
                    ownedItems: _ownedItems,
                    currentEquipped: _equipped,
                    onSelectOutfit: _onSelectOutfit,
                  ),

                  const SizedBox(height: 18),

                  // Mix & Match Slots (Hats, Eyewear, Scarves, Props, Weather)
                  ItemPickerGrid(
                    ownedItems: _ownedItems,
                    currentEquipped: _equipped,
                    onItemTapped: _onItemTapped,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Fixed Bottom Try-On Purchase Bar
            if (isInTryOn)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TryOnPurchaseBar(
                  title: _tryOnTitle!,
                  cost: _tryOnCost,
                  citizenCoins: _coins,
                  onBuy: _confirmPurchase,
                  onCancel: _cancelTryOn,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
