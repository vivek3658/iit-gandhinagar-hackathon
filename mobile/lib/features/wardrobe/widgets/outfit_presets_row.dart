import 'package:flutter/material.dart';
import '../models/wardrobe_models.dart';

class OutfitPresetsRow extends StatelessWidget {
  final List<String> ownedItems;
  final Map<String, String?> currentEquipped;
  final ValueChanged<OutfitDef> onSelectOutfit;

  const OutfitPresetsRow({
    super.key,
    required this.ownedItems,
    required this.currentEquipped,
    required this.onSelectOutfit,
  });

  bool _isOutfitWorn(OutfitDef outfit) {
    if (outfit.id == 'none') {
      return currentEquipped.values.every((v) => v == null);
    }
    return currentEquipped['head'] == outfit.head &&
        currentEquipped['face'] == outfit.face &&
        currentEquipped['neck'] == outfit.neck &&
        currentEquipped['held'] == outfit.held &&
        currentEquipped['fx'] == outfit.fx;
  }

  bool _isOutfitOwned(OutfitDef outfit) {
    return outfit.allItems.every((itemId) => ownedItems.contains(itemId));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'SEASONAL SETS (10% BUNDLE DISCOUNT)',
            style: TextStyle(
              color: Color(0xFF2F4A2A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: WardrobeCatalog.outfits.length,
            itemBuilder: (context, index) {
              final outfit = WardrobeCatalog.outfits[index];
              final isWorn = _isOutfitWorn(outfit);
              final isOwned = _isOutfitOwned(outfit);

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => onSelectOutfit(outfit),
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isWorn ? const Color(0xFF5F8F2E) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isWorn ? const Color(0xFF5F8F2E) : const Color(0xFFE3D8BD),
                        width: 1.2,
                      ),
                      boxShadow: isWorn
                          ? const [
                              BoxShadow(color: Color(0x335F8F2E), blurRadius: 8, offset: Offset(0, 3)),
                            ]
                          : const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(outfit.iconEmoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          outfit.name,
                          style: TextStyle(
                            color: isWorn ? Colors.white : const Color(0xFF2F4A2A),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (!isOwned) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFFB45309)),
                        ],
                      ],
                    ),
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
