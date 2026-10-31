import 'dart:math' as math;
import 'package:flutter/material.dart';

class WeatherFxOverlay extends StatelessWidget {
  final String? activeFx;
  final String? activeProp;
  final double animationValue;

  const WeatherFxOverlay({
    super.key,
    this.activeFx,
    this.activeProp,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    if (activeFx == null && activeProp == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _WeatherFxPainter(
        fx: activeFx,
        prop: activeProp,
        t: animationValue,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _WeatherFxPainter extends CustomPainter {
  final String? fx;
  final String? prop;
  final double t;

  _WeatherFxPainter({
    required this.fx,
    required this.prop,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Paint active weather effect
    if (fx != null) {
      switch (fx) {
        case 'petals':
          _drawPetals(canvas, w, h);
          break;
        case 'butterflies':
          _drawButterflies(canvas, w, h);
          break;
        case 'leaves':
          _drawLeaves(canvas, w, h);
          break;
        case 'snow':
          _drawSnow(canvas, w, h);
          break;
        case 'rain':
          _drawRain(canvas, w, h);
          break;
        case 'sparks':
          _drawSparks(canvas, w, h);
          break;
      }
    }

    // Paint active pose prop
    if (prop != null) {
      switch (prop) {
        case 'hearts':
          _drawFloatingHearts(canvas, w, h);
          break;
        case 'steam':
          _drawSteamPuffs(canvas, w, h);
          break;
        case 'tears':
          _drawTears(canvas, w, h);
          break;
        case 'scribble':
          _drawScribbleCloud(canvas, w, h);
          break;
        case 'sadcloud':
          _drawRainCloud(canvas, w, h);
          break;
      }
    }
  }

  void _drawPetals(Canvas canvas, double w, double h) {
    final paint = Paint()..style = PaintingStyle.fill;
    const count = 18;
    for (int i = 0; i < count; i++) {
      final seed = i * 137.5;
      final speed = 0.35 + (i % 4) * 0.15;
      final progress = (t * speed + (i / count)) % 1.0;
      final x = (math.sin(seed + t * 2.5) * 40.0 + (i * (w / count)) + progress * 60.0) % w;
      final y = progress * h;
      final angle = t * 3.0 + i;

      paint.color = i % 2 == 0
          ? const Color(0xFFF8BBD0).withValues(alpha: 0.85)
          : const Color(0xFFF48FB1).withValues(alpha: 0.75);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, -7)
        ..quadraticBezierTo(5, -2, 0, 7)
        ..quadraticBezierTo(-5, -2, 0, -7);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _drawButterflies(Canvas canvas, double w, double h) {
    // Warm sun in top corner
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFEE77), Color(0xFFFFCC33), Color(0x00FFCC33)],
        stops: [0.2, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: const Offset(40, 40), radius: 55));
    canvas.drawCircle(const Offset(40, 40), 55, sunPaint);

    final colors = [
      const Color(0xFFFF9800),
      const Color(0xFF29B6F6),
      const Color(0xFFFFD54F),
    ];

    for (int i = 0; i < colors.length; i++) {
      final angle = t * (1.2 + i * 0.4) + i * 2.1;
      final cx = w * 0.5 + math.cos(angle) * (w * 0.35);
      final cy = h * 0.4 + math.sin(angle * 1.5) * 55.0 + i * 15.0;
      final wingFlap = math.sin(t * 18.0 + i * 3.0).abs();

      final wingPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(cx, cy);
      // Left wing
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-6 * wingFlap, 0), width: 12 * wingFlap, height: 10),
        wingPaint,
      );
      // Right wing
      canvas.drawOval(
        Rect.fromCenter(center: Offset(6 * wingFlap, 0), width: 12 * wingFlap, height: 10),
        wingPaint,
      );
      // Butterfly body
      final bodyPaint = Paint()..color = const Color(0xFF3E2723);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 3, height: 10), bodyPaint);
      canvas.restore();
    }
  }

  void _drawLeaves(Canvas canvas, double w, double h) {
    final colors = [
      const Color(0xFFD84315),
      const Color(0xFFEF6C00),
      const Color(0xFFF9A825),
      const Color(0xFF8D6E63),
    ];

    final paint = Paint()..style = PaintingStyle.fill;
    const count = 16;
    for (int i = 0; i < count; i++) {
      final progress = (t * 0.4 + (i / count)) % 1.0;
      final x = (math.sin(i * 99.0 + t * 2.0) * 50.0 + (i * (w / count)) + progress * 50.0) % w;
      final y = progress * h;
      final angle = t * 2.5 + i;

      paint.color = colors[i % colors.length].withValues(alpha: 0.85);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, -9)
        ..quadraticBezierTo(6, 0, 0, 9)
        ..quadraticBezierTo(-6, 0, 0, -9);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _drawSnow(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    const count = 28;
    for (int i = 0; i < count; i++) {
      final speed = 0.2 + (i % 3) * 0.15;
      final progress = (t * speed + (i / count)) % 1.0;
      final x = ((i * (w / count)) + math.sin(t * 1.5 + i) * 20.0) % w;
      final y = progress * h;
      final radius = 2.0 + (i % 4) * 1.2;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawRain(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.6)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const count = 35;
    for (int i = 0; i < count; i++) {
      final progress = (t * 1.6 + (i / count)) % 1.0;
      final x = ((i * (w / count)) + 15.0) % w;
      final y = progress * h;
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 18), paint);
    }
  }

  void _drawSparks(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    const count = 15;
    for (int i = 0; i < count; i++) {
      final progress = (t * 0.5 + (i / count)) % 1.0;
      final x = (w * 0.25 + (i * (w * 0.5 / count)) + math.sin(t * 3.0 + i) * 15.0);
      final y = (1.0 - progress) * h * 0.8 + h * 0.1;
      final alpha = (1.0 - (progress - 0.5).abs() * 2.0).clamp(0.0, 1.0);
      paint.color = const Color(0xFFFFD54F).withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 4.0 + i);
      _drawSparkleStar(canvas, 5.0, paint);
      canvas.restore();
    }
  }

  void _drawSparkleStar(Canvas canvas, double r, Paint paint) {
    final path = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..quadraticBezierTo(0, 0, 0, r)
      ..quadraticBezierTo(0, 0, -r, 0)
      ..quadraticBezierTo(0, 0, 0, -r);
    canvas.drawPath(path, paint);
  }

  void _drawFloatingHearts(Canvas canvas, double w, double h) {
    final paint = Paint()..style = PaintingStyle.fill;
    const count = 6;
    for (int i = 0; i < count; i++) {
      final progress = (t * 0.7 + (i / count)) % 1.0;
      final x = w * 0.5 + math.sin(i * 2.3 + t * 3.0) * 60.0;
      final y = h * 0.55 - progress * (h * 0.4);
      final scale = (0.5 + math.sin(progress * math.pi) * 0.6).clamp(0.0, 1.2);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      paint.color = const Color(0xFFFF4081).withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);
      _drawHeartShape(canvas, paint);
      canvas.restore();
    }
  }

  void _drawHeartShape(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(0, 4)
      ..cubicTo(-6, -6, -14, 0, 0, 14)
      ..cubicTo(14, 0, 6, -6, 0, 4);
    canvas.drawPath(path, paint);
  }

  void _drawSteamPuffs(Canvas canvas, double w, double h) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final dir in [-1.0, 1.0]) {
      for (int i = 0; i < 4; i++) {
        final progress = (t * 0.9 + i * 0.25) % 1.0;
        final x = w * 0.5 + dir * (40.0 + progress * 35.0);
        final y = h * 0.35 - progress * 40.0;
        final radius = 6.0 + progress * 10.0;
        final alpha = (1.0 - progress) * 0.6;
        paint.color = Colors.white.withValues(alpha: alpha);
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  void _drawTears(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (final dir in [-1.0, 1.0]) {
      final progress = (t * 1.2) % 1.0;
      final x = w * 0.5 + dir * 24.0;
      final y = h * 0.42 + progress * 55.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 5, height: 10),
        paint,
      );
    }
  }

  void _drawScribbleCloud(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = w * 0.5;
    final cy = h * 0.22;
    final path = Path()..moveTo(cx - 20, cy);
    for (int i = 0; i < 20; i++) {
      final angle = i * 0.6 + t * 4.0;
      final r = 12.0 + (i % 3) * 6.0;
      path.lineTo(cx + math.cos(angle) * r, cy + math.sin(angle) * (r * 0.6));
    }
    canvas.drawPath(path, paint);
  }

  void _drawRainCloud(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..style = PaintingStyle.fill;

    final cx = w * 0.5;
    final cy = h * 0.22;

    canvas.drawCircle(Offset(cx - 15, cy), 14, cloudPaint);
    canvas.drawCircle(Offset(cx + 15, cy), 16, cloudPaint);
    canvas.drawCircle(Offset(cx, cy - 8), 18, cloudPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 6), width: 48, height: 16),
        const Radius.circular(8),
      ),
      cloudPaint,
    );

    // Droplets
    final dropPaint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..strokeWidth = 1.8;

    for (int i = -1; i <= 1; i++) {
      final progress = (t * 1.5 + i * 0.3) % 1.0;
      final dx = cx + i * 14.0;
      final dy = cy + 16.0 + progress * 30.0;
      canvas.drawLine(Offset(dx, dy), Offset(dx, dy + 6), dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherFxPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.fx != fx || oldDelegate.prop != prop;
  }
}
