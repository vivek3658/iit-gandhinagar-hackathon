import 'package:flutter/material.dart';
import '../models/wardrobe_models.dart';

class ItemPickerGrid extends StatefulWidget {
  final List<String> ownedItems;
  final Map<String, String?> currentEquipped;
  final ValueChanged<WardrobeItemDef?> onItemTapped;

  const ItemPickerGrid({
    super.key,
    required this.ownedItems,
    required this.currentEquipped,
    required this.onItemTapped,
  });

  @override
  State<ItemPickerGrid> createState() => _ItemPickerGridState();
}

class _ItemPickerGridState extends State<ItemPickerGrid> {
  int _selectedCategoryIndex = 0;

  final List<_CategoryTab> _categories = const [
    _CategoryTab(slot: 'head', title: 'Hats', icon: '👒'),
    _CategoryTab(slot: 'face', title: 'Eyewear', icon: '🕶️'),
    _CategoryTab(slot: 'neck', title: 'Neckwear', icon: '🧣'),
    _CategoryTab(slot: 'held', title: 'Props', icon: '☂️'),
    _CategoryTab(slot: 'fx', title: 'Weather', icon: '✨'),
  ];

  List<WardrobeItemDef> _getItemsForSlot(String slot) {
    switch (slot) {
      case 'head':
        return WardrobeCatalog.headItems;
      case 'face':
        return WardrobeCatalog.faceItems;
      case 'neck':
        return WardrobeCatalog.neckItems;
      case 'held':
        return WardrobeCatalog.heldItems;
      case 'fx':
        return WardrobeCatalog.fxItems;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSlot = _categories[_selectedCategoryIndex].slot;
    final items = _getItemsForSlot(activeSlot);
    final currentlyEquippedId = widget.currentEquipped[activeSlot];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Pills
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = index == _selectedCategoryIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  avatar: Text(cat.icon, style: const TextStyle(fontSize: 14)),
                  label: Text(cat.title),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategoryIndex = index),
                  selectedColor: const Color(0xFF2F4A2A),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF2F4A2A),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2F4A2A) : const Color(0xFFE3D8BD),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Grid of items + "None" button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
            ),
            itemCount: items.length + 1, // +1 for "None / Remove"
            itemBuilder: (context, index) {
              if (index == 0) {
                // "None / Unequip" Card
                final isNoneSelected = currentlyEquippedId == null;
                return InkWell(
                  onTap: () => widget.onItemTapped(null),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isNoneSelected ? const Color(0xFFE9F5D8) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isNoneSelected ? const Color(0xFF5F8F2E) : const Color(0xFFE3D8BD),
                        width: isNoneSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.do_not_disturb_alt_rounded, size: 28, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 6),
                        const Text(
                          'None',
                          style: TextStyle(
                            color: Color(0xFF2F4A2A),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        if (isNoneSelected)
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF5F8F2E)),
                          ),
                      ],
                    ),
                  ),
                );
              }

              final item = items[index - 1];
              final isOwned = widget.ownedItems.contains(item.id);
              final isEquipped = currentlyEquippedId == item.id;

              return InkWell(
                onTap: () => widget.onItemTapped(item),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEquipped ? const Color(0xFFE9F5D8) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isEquipped ? const Color(0xFF5F8F2E) : const Color(0xFFE3D8BD),
                      width: isEquipped ? 2.0 : 1.0,
                    ),
                    boxShadow: isEquipped
                        ? const [
                            BoxShadow(color: Color(0x335F8F2E), blurRadius: 6, offset: Offset(0, 2)),
                          ]
                        : const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                          ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.iconEmoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            item.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2F4A2A),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isOwned) ...[
                                const Text('🪙 ', style: TextStyle(fontSize: 10)),
                                Text(
                                  '${item.price}',
                                  style: const TextStyle(
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Owned',
                                  style: TextStyle(
                                    color: Color(0xFF5F8F2E),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (!isOwned)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(Icons.lock_rounded, size: 14, color: Color(0xFFB45309)),
                        ),
                      if (isEquipped)
                        const Positioned(
                          top: 0,
                          left: 0,
                          child: Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF5F8F2E)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTab {
  final String slot;
  final String title;
  final String icon;

  const _CategoryTab({required this.slot, required this.title, required this.icon});
}
