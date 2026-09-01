import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Falling paper rectangles for a stage clear.
///
/// Hand-rolled rather than pulled from a package: it is one painter and one
/// controller, and it lets the confetti use the brand palette directly — which
/// is, after all, where the "confetti card" language comes from.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    this.pieceCount = 70,
    this.duration = const Duration(milliseconds: 2600),
  });

  final int pieceCount;
  final Duration duration;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const _palette = [
    AppColors.hiVisYellow,
    AppColors.butteryYellow,
    AppColors.bubblegumPink,
    AppColors.matchaCream,
    AppColors.magentaPunch,
    AppColors.firecrackerRed,
    AppColors.boneWhite,
  ];

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  late final List<_Piece> _pieces = _makePieces();

  List<_Piece> _makePieces() {
    final random = Random(11);
    return List.generate(widget.pieceCount, (i) {
      return _Piece(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        fallSpeed: 0.75 + random.nextDouble() * 0.5,
        drift: (random.nextDouble() - 0.5) * 0.35,
        spin: (random.nextDouble() - 0.5) * 9,
        width: 6 + random.nextDouble() * 8,
        height: 9 + random.nextDouble() * 12,
        color: _palette[i % _palette.length],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_pieces, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.fallSpeed,
    required this.drift,
    required this.spin,
    required this.width,
    required this.height,
    required this.color,
  });

  final double x;
  final double delay;
  final double fallSpeed;
  final double drift;
  final double spin;
  final double width;
  final double height;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final piece in pieces) {
      final local = ((t - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final progress = local * piece.fallSpeed;
      final dy = (progress * (size.height + 120)) - 60;
      if (dy > size.height + 60) continue;

      final dx = size.width * (piece.x + piece.drift * sin(progress * pi * 2));
      // Fade out over the last third so the overlay can be removed cleanly.
      paint.color = piece.color.withValues(
        alpha: local > 0.7 ? (1 - (local - 0.7) / 0.3).clamp(0.0, 1.0) : 1.0,
      );

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(progress * piece.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.width,
            // Flipping the height fakes the paper turning edge-on.
            height: piece.height * cos(progress * piece.spin * 1.7).abs(),
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
