import 'package:flutter/material.dart';
import '../models/wardrobe_models.dart';

class ExpressionsCarousel extends StatelessWidget {
  final String activePoseId;
  final ValueChanged<MascotPoseDef> onSelectPose;

  const ExpressionsCarousel({
    super.key,
    required this.activePoseId,
    required this.onSelectPose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EXPRESSIONS',
                style: TextStyle(
                  color: Color(0xFF2F4A2A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'Tap sparrow to pet',
                style: TextStyle(
                  color: const Color(0xFF2F4A2A).withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: WardrobeCatalog.poses.length,
            itemBuilder: (context, index) {
              final pose = WardrobeCatalog.poses[index];
              final isSelected = pose.id == activePoseId;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => onSelectPose(pose),
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF5F8F2E) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF5F8F2E) : const Color(0xFFE3D8BD),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x335F8F2E),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pose.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          pose.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF2F4A2A),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
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
