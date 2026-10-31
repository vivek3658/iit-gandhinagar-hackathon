import 'package:flutter/material.dart';
import 'floating_isometric_grid.dart';

/// 3D Bottom Sheet for inspecting and managing sanctuary garden tiles.
///
/// Features:
/// - Centerpiece Sparrow Home is moveable to any free space, but cannot be removed/stored.
/// - Other structures offer "Save to Inventory" (no forced selling).
/// - Coin Master / Clash of Clans tactile styling.
class TileDetailSheet extends StatelessWidget {
  final GardenTileModel tile;
  final VoidCallback onStoreInInventory;
  final VoidCallback? onMoveTile;

  const TileDetailSheet({
    super.key,
    required this.tile,
    required this.onStoreInInventory,
    this.onMoveTile,
  });

  static void show(
    BuildContext context, {
    required GardenTileModel tile,
    required VoidCallback onStoreInInventory,
    VoidCallback? onMoveTile,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => TileDetailSheet(
        tile: tile,
        onStoreInInventory: onStoreInInventory,
        onMoveTile: onMoveTile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFB45309), offset: Offset(0, 3)),
                  ],
                ),
                child: Center(
                  child: Text(tile.iconEmoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.name,
                      style: const TextStyle(
                        color: Color(0xFF0F291E),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${tile.category} · Plot (${tile.x}, ${tile.y}) · Level ${tile.level}',
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (tile.isProtectedHome) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF59E0B)),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF92400E), offset: Offset(0, 2)),
                ],
              ),
              child: const Row(
                children: [
                  Text('🛡️', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sanctuary Centerpiece House: Cannot be removed or sold! However, you can freely move it to any other space on your 3×3 grid.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onMoveTile?.call();
                },
                icon: const Icon(Icons.open_with_rounded, size: 16),
                label: const Text('Move to Another Space', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6B44),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2EBE5)),
              ),
              child: const Row(
                children: [
                  Text('📦', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Store in Inventory: Removes this structure from the garden grid and keeps it safely in your backpack. You can place it again anytime at 0 🪙 cost.',
                      style: TextStyle(
                        color: Color(0xFF2F4A2A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (onMoveTile != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onMoveTile?.call();
                      },
                      icon: const Icon(Icons.open_with_rounded, size: 16),
                      label: const Text('Move'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1B6B44)),
                        foregroundColor: const Color(0xFF1B6B44),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onStoreInInventory();
                    },
                    icon: const Icon(Icons.inventory_2_rounded, size: 16),
                    label: const Text('Save in Inventory 📦'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
