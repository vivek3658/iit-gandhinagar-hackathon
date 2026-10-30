import 'dart:math' as math;
import 'package:flutter/material.dart';

class GardenTileModel {
  final String id;
  final String name;
  final String category;
  final int x;
  final int y;
  final String iconEmoji;
  final int level;
  final int cost;
  final bool isProtectedHome;
  final int rotation; // 0, 1, 2, 3 (0°, 90°, 180°, 270°)

  const GardenTileModel({
    required this.id,
    required this.name,
    required this.category,
    required this.x,
    required this.y,
    required this.iconEmoji,
    this.level = 1,
    this.cost = 50,
    this.isProtectedHome = false,
    this.rotation = 0,
  });

  GardenTileModel copyWith({int? rotation}) {
    return GardenTileModel(
      id: id,
      name: name,
      category: category,
      x: x,
      y: y,
      iconEmoji: iconEmoji,
      level: level,
      cost: cost,
      isProtectedHome: isProtectedHome,
      rotation: rotation ?? this.rotation,
    );
  }
}

class FloatingIsometricGrid extends StatefulWidget {
  final List<GardenTileModel> tiles;
  final int gridSize; // 3 for 3x3
  final ValueChanged<GardenTileModel> onTileTap;

  const FloatingIsometricGrid({
    super.key,
    required this.tiles,
    this.gridSize = 3,
    required this.onTileTap,
  });

  @override
  State<FloatingIsometricGrid> createState() => _FloatingIsometricGridState();
}

class _FloatingIsometricGridState extends State<FloatingIsometricGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _levitateController;

  @override
  void initState() {
    super.initState();
    _levitateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _levitateController.dispose();
    super.dispose();
  }

  GardenTileModel? _getTileAt(int x, int y) {
    for (final t in widget.tiles) {
      if (t.x == x && t.y == y) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final centerX = screenWidth / 2;

        return AnimatedBuilder(
          animation: _levitateController,
          builder: (context, _) {
            final levitate = math.sin(_levitateController.value * math.pi) * 8.0;

            return SizedBox(
              width: double.infinity,
              height: 380,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Floating ground ambient shadow
                  Positioned(
                    bottom: 24,
                    child: Container(
                      width: 280,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.elliptical(280, 100)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332F4A2A),
                            blurRadius: 36,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3D Isometric Floating Block Grid (Coin Master / Sim Companies style)
                  CustomPaint(
                    size: Size(screenWidth, 380),
                    painter: _IsometricGridPainter(
                      gridSize: widget.gridSize,
                      tiles: widget.tiles,
                      levitateOffset: levitate,
                      animTime: _levitateController.value,
                    ),
                  ),

                  // Interactive hit-test touch overlays for each tile
                  ..._buildInteractiveTileButtons(levitate, centerX),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildInteractiveTileButtons(double levitate, double centerX) {
    final widgets = <Widget>[];
    const tileW = 96.0;
    const tileH = 48.0;
    const centerY = 140.0;

    // Render from back to front: row 0 to 2, col 0 to 2
    for (int y = 0; y < widget.gridSize; y++) {
      for (int x = 0; x < widget.gridSize; x++) {
        final isoX = centerX + (x - y) * (tileW / 2) - (tileW / 2);
        final isoY = centerY + (x + y) * (tileH / 2) - levitate - 30.0;

        final tile = _getTileAt(x, y);

        widgets.add(
          Positioned(
            left: isoX,
            top: isoY,
            child: GestureDetector(
              onTap: () {
                if (tile != null) {
                  widget.onTileTap(tile);
                } else {
                  // Empty plot tapped
                  widget.onTileTap(
                    GardenTileModel(
                      id: 'EMPTY_LAND',
                      name: 'Empty Garden Plot',
                      category: 'Paths',
                      x: x,
                      y: y,
                      iconEmoji: '🌱',
                    ),
                  );
                }
              },
              child: Container(
                width: tileW,
                height: tileH + 40,
                color: Colors.transparent,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

class _IsometricGridPainter extends CustomPainter {
  final int gridSize;
  final List<GardenTileModel> tiles;
  final double levitateOffset;
  final double animTime;

  _IsometricGridPainter({
    required this.gridSize,
    required this.tiles,
    required this.levitateOffset,
    required this.animTime,
  });

  GardenTileModel? _getTile(int x, int y) {
    for (final t in tiles) {
      if (t.x == x && t.y == y) return t;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const tileW = 96.0;
    const tileH = 48.0;
    const blockDepth = 24.0;
    final centerX = size.width / 2;
    final centerY = size.height * 0.38 - levitateOffset;

    // Render tiles in painter's isometric depth order (back-to-front: col+row ascending)
    for (int sum = 0; sum <= (gridSize - 1) * 2; sum++) {
      for (int x = 0; x < gridSize; x++) {
        final y = sum - x;
        if (y < 0 || y >= gridSize) continue;

        final isoX = centerX + (x - y) * (tileW / 2);
        final isoY = centerY + (x + y) * (tileH / 2);

        final tile = _getTile(x, y);
        _drawFloatingBlock(canvas, isoX, isoY, tileW, tileH, blockDepth, tile);
      }
    }
  }

  void _drawFloatingBlock(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    double depth,
    GardenTileModel? tile,
  ) {
    final hw = w / 2;
    final hh = h / 2;

    // Block Top Diamond points
    final top = Offset(cx, cy - hh);
    final right = Offset(cx + hw, cy);
    final bottom = Offset(cx, cy + hh);
    final left = Offset(cx - hw, cy);

    // Block Bottom Extruded points
    final bLeft = Offset(left.dx, left.dy + depth);
    final bBottom = Offset(bottom.dx, bottom.dy + depth);
    final bRight = Offset(right.dx, right.dy + depth);

    // 1. Soft Tile Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final shadowPath = Path()
      ..moveTo(left.dx, bLeft.dy + 8)
      ..lineTo(bottom.dx, bBottom.dy + 8)
      ..lineTo(right.dx, bRight.dy + 8)
      ..lineTo(bottom.dx, bBottom.dy + 14)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Left 3D Face (shaded earth / stone)
    final leftFacePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6B4423), Color(0xFF4A2F1B)],
      ).createShader(Rect.fromPoints(left, bBottom));

    final leftFace = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bBottom.dx, bBottom.dy)
      ..lineTo(bLeft.dx, bLeft.dy)
      ..close();
    canvas.drawPath(leftFace, leftFacePaint);

    // 3. Right 3D Face (darker shaded earth)
    final rightFacePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5A3615), Color(0xFF381F0E)],
      ).createShader(Rect.fromPoints(bottom, bRight));

    final rightFace = Path()
      ..moveTo(bottom.dx, bottom.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bRight.dx, bRight.dy)
      ..lineTo(bBottom.dx, bBottom.dy)
      ..close();
    canvas.drawPath(rightFace, rightFacePaint);

    // 4. Top Face: Color depending on tile type
    Color topGradStart = const Color(0xFF75B946);
    Color topGradEnd = const Color(0xFF5F8F2E);

    if (tile != null) {
      if (tile.id == 'SPARROW_HOME') {
        topGradStart = const Color(0xFF86C957);
        topGradEnd = const Color(0xFF5F8F2E);
      } else if (tile.id == 'POND_TILE') {
        topGradStart = const Color(0xFF60A5FA);
        topGradEnd = const Color(0xFF2563EB);
      } else if (tile.id == 'STONE_PATH') {
        topGradStart = const Color(0xFFE2E8F0);
        topGradEnd = const Color(0xFF94A3B8);
      } else if (tile.id == 'VEGETABLE_PLOT') {
        topGradStart = const Color(0xFF8B5A2B);
        topGradEnd = const Color(0xFF6B4423);
      } else if (tile.id == 'WOOD_PATH' || tile.id == 'WOOD_FENCE') {
        topGradStart = const Color(0xFFD97706);
        topGradEnd = const Color(0xFFB45309);
      }
    } else {
      // Empty plot
      topGradStart = const Color(0xFF86A76E);
      topGradEnd = const Color(0xFF6F8F56);
    }

    final topFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [topGradStart, topGradEnd],
      ).createShader(Rect.fromPoints(top, bottom));

    final topFace = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(topFace, topFacePaint);

    // Bevel edge highlight on top face
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(topFace, borderPaint);

    // 5. Render Structure on Top of Block
    if (tile != null) {
      _drawTileStructure(canvas, cx, cy - 4, tile);
    }
  }

  void _drawTileStructure(Canvas canvas, double cx, double cy, GardenTileModel tile) {
    switch (tile.id) {
      case 'SPARROW_HOME':
        _drawSparrowManor(canvas, cx, cy);
        break;
      case 'TULSI_KYARO':
        _drawTulsiAltar(canvas, cx, cy);
        break;
      case 'SOLAR_PANEL_T1':
        _drawSolarFlower(canvas, cx, cy);
        break;
      case 'POND_TILE':
        _drawPondTile(canvas, cx, cy);
        break;
      case 'WINDMILL_RUSTIC':
        _drawWindmill(canvas, cx, cy);
        break;
      case 'VEGETABLE_PLOT':
        _drawVegetablePlot(canvas, cx, cy);
        break;
      case 'BIRD_HOUSE':
        _drawBirdHouse(canvas, cx, cy);
        break;
      default:
        _drawGenericTileIcon(canvas, cx, cy, tile.iconEmoji);
        break;
    }
  }

  void _drawSparrowManor(Canvas canvas, double cx, double cy) {
    // 3D House Base
    final houseBasePaint = Paint()..color = const Color(0xFFE8CF9F);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - 14), width: 34, height: 22),
      houseBasePaint,
    );

    // Roof: sloped mossy roof
    final roofPaint = Paint()..color = const Color(0xFF5C8F2E);
    final roofPath = Path()
      ..moveTo(cx - 22, cy - 22)
      ..lineTo(cx, cy - 36)
      ..lineTo(cx + 22, cy - 22)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Chimney + puffing smoke
    final chimneyPaint = Paint()..color = const Color(0xFFA8553A);
    canvas.drawRect(Rect.fromLTWH(cx + 8, cy - 38, 7, 12), chimneyPaint);

    final smokeProgress = (animTime * 2.0) % 1.0;
    final smokePaint = Paint()
      ..color = Colors.white.withValues(alpha: (1.0 - smokeProgress) * 0.65);
    canvas.drawCircle(
      Offset(cx + 11.5 + math.sin(smokeProgress * 6) * 3, cy - 40 - smokeProgress * 16),
      3 + smokeProgress * 4,
      smokePaint,
    );

    // Warm glowing window
    final windowPaint = Paint()..color = const Color(0xFFFFC766);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 6, cy - 14), width: 8, height: 8),
        const Radius.circular(2),
      ),
      windowPaint,
    );

    // Timber door
    final doorPaint = Paint()..color = const Color(0xFF7C4A24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 2, cy - 15, 8, 13),
        const Radius.circular(2),
      ),
      doorPaint,
    );
  }

  void _drawTulsiAltar(Canvas canvas, double cx, double cy) {
    // Terracotta pedestal
    final potPaint = Paint()..color = const Color(0xFFEA580C);
    final potPath = Path()
      ..moveTo(cx - 10, cy)
      ..lineTo(cx + 10, cy)
      ..lineTo(cx + 7, cy - 14)
      ..lineTo(cx - 7, cy - 14)
      ..close();
    canvas.drawPath(potPath, potPaint);

    // Sacred Basil foliage
    final plantPaint = Paint()..color = const Color(0xFF22C55E);
    canvas.drawCircle(Offset(cx, cy - 20), 8, plantPaint);
    canvas.drawCircle(Offset(cx - 5, cy - 16), 5, plantPaint);
    canvas.drawCircle(Offset(cx + 5, cy - 16), 5, plantPaint);
  }

  void _drawSolarFlower(Canvas canvas, double cx, double cy) {
    // Metal post
    final polePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 18), polePaint);

    // Revolving solar disc
    final panelPaint = Paint()..color = const Color(0xFF1E3A8A);
    final discRect = Rect.fromCenter(center: Offset(cx, cy - 22), width: 26, height: 14);
    canvas.drawOval(discRect, panelPaint);

    // Solar gridlines
    final gridPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(cx - 11, cy - 22), Offset(cx + 11, cy - 22), gridPaint);
    canvas.drawLine(Offset(cx, cy - 28), Offset(cx, cy - 16), gridPaint);
  }

  void _drawPondTile(Canvas canvas, double cx, double cy) {
    // Glistening water center
    final waterPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 44, height: 22),
      waterPaint,
    );

    // Lily pad
    final padPaint = Paint()..color = const Color(0xFF4ADE80);
    canvas.drawCircle(Offset(cx - 8, cy - 2), 6, padPaint);

    // Pink lotus flower
    final flowerPaint = Paint()..color = const Color(0xFFF472B6);
    canvas.drawCircle(Offset(cx - 8, cy - 3), 3, flowerPaint);
  }

  void _drawWindmill(Canvas canvas, double cx, double cy) {
    // Tower body
    final towerPaint = Paint()..color = const Color(0xFFF3E6C8);
    final towerPath = Path()
      ..moveTo(cx - 8, cy)
      ..lineTo(cx + 8, cy)
      ..lineTo(cx + 4, cy - 24)
      ..lineTo(cx - 4, cy - 24)
      ..close();
    canvas.drawPath(towerPath, towerPaint);

    // Red conical cap
    final capPaint = Paint()..color = const Color(0xFF92400E);
    final capPath = Path()
      ..moveTo(cx - 6, cy - 24)
      ..lineTo(cx, cy - 32)
      ..lineTo(cx + 6, cy - 24)
      ..close();
    canvas.drawPath(capPath, capPaint);

    // Rotating 4-blade turbine
    final bladeAngle = animTime * math.pi * 4.0;
    final hub = Offset(cx, cy - 24);
    final bladePaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final a = bladeAngle + (i * math.pi / 2);
      final tip = Offset(hub.dx + math.cos(a) * 14, hub.dy + math.sin(a) * 14);
      canvas.drawLine(hub, tip, bladePaint);
    }
  }

  void _drawVegetablePlot(Canvas canvas, double cx, double cy) {
    // Tilled soil ridges
    final ridgePaint = Paint()
      ..color = const Color(0xFF4A2F1B)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(cx - 16, cy - 4), Offset(cx + 16, cy - 4), ridgePaint);
    canvas.drawLine(Offset(cx - 16, cy + 3), Offset(cx + 16, cy + 3), ridgePaint);

    // Orange carrot tops
    final carrotPaint = Paint()..color = const Color(0xFFF97316);
    final greenPaint = Paint()..color = const Color(0xFF22C55E);

    for (int i = -1; i <= 1; i++) {
      final carrotPos = Offset(cx + i * 11, cy - 2);
      canvas.drawCircle(carrotPos, 3, carrotPaint);
      canvas.drawCircle(Offset(carrotPos.dx, carrotPos.dy - 4), 2.5, greenPaint);
    }
  }

  void _drawBirdHouse(Canvas canvas, double cx, double cy) {
    // Wooden post
    final postPaint = Paint()
      ..color = const Color(0xFF8A5A2B)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 20), postPaint);

    // Wooden nest box
    final boxPaint = Paint()..color = const Color(0xFFD08A3E);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 25), width: 14, height: 12), boxPaint);

    // Sloped roof
    final roofPaint = Paint()..color = const Color(0xFF8A3B1E);
    final roof = Path()
      ..moveTo(cx - 10, cy - 31)
      ..lineTo(cx, cy - 38)
      ..lineTo(cx + 10, cy - 31)
      ..close();
    canvas.drawPath(roof, roofPaint);
  }

  void _drawGenericTileIcon(Canvas canvas, double cx, double cy, String emoji) {
    final textPainter = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 20)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - 20));
  }

  @override
  bool shouldRepaint(covariant _IsometricGridPainter oldDelegate) {
    return oldDelegate.animTime != animTime ||
        oldDelegate.levitateOffset != levitateOffset ||
        oldDelegate.tiles != tiles;
  }
}
