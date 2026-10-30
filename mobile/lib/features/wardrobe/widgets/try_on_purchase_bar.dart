import 'package:flutter/material.dart';

class TryOnPurchaseBar extends StatelessWidget {
  final String title;
  final int cost;
  final int citizenCoins;
  final VoidCallback onBuy;
  final VoidCallback onCancel;

  const TryOnPurchaseBar({
    super.key,
    required this.title,
    required this.cost,
    required this.citizenCoins,
    required this.onBuy,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final hasEnoughCoins = citizenCoins >= cost;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3D8BD), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A2F4A2A),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2F4A2A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('Cost: ', style: TextStyle(color: Color(0xFF718096), fontSize: 11)),
                    const Text('🪙 ', style: TextStyle(fontSize: 11)),
                    Text(
                      '$cost coins',
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!hasEnoughCoins) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(Need ${cost - citizenCoins} more)',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Cancel button
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE3D8BD)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF2F4A2A), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),

          // Buy button
          ElevatedButton(
            onPressed: hasEnoughCoins ? onBuy : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F8F2E),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text('Buy $cost', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
