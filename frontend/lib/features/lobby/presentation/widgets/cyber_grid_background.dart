import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Fundo dinâmico procedural de alta performance (60 FPS) com perspectiva cyber,
/// partículas de dados flutuantes e scanlines táteis.
class CyberGridBackground extends StatefulWidget {
  final Color accentColor;
  final Widget? child;

  const CyberGridBackground({
    super.key,
    this.accentColor = AppColors.blueTeam,
    this.child,
  });

  @override
  State<CyberGridBackground> createState() => _CyberGridBackgroundState();
}

class _CyberGridBackgroundState extends State<CyberGridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_CyberParticle> _particles = [];
  final Random _random = Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Inicializa 45 partículas de dados com posições e velocidades aleatórias
    for (int i = 0; i < 45; i++) {
      _particles.add(
        _CyberParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: 0.04 + _random.nextDouble() * 0.08,
          size: 1.2 + _random.nextDouble() * 2.2,
          opacity: 0.2 + _random.nextDouble() * 0.6,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CyberGridPainter(
              progress: _controller.value,
              accentColor: widget.accentColor,
              particles: _particles,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _CyberParticle {
  double x;
  double y;
  final double speed;
  final double size;
  final double opacity;

  _CyberParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });

  void update(double dt) {
    y -= speed * dt;
    if (y < 0) {
      y = 1.0;
      x = Random().nextDouble();
    }
  }
}

class _CyberGridPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final List<_CyberParticle> particles;

  _CyberGridPainter({
    required this.progress,
    required this.accentColor,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Fundo base profundo
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(rect, bgPaint);

    // 2. Vinheta radial com a cor de acento no topo
    final radialGradient = RadialGradient(
      center: const Alignment(0.0, -0.6),
      radius: 1.2,
      colors: [
        accentColor.withValues(alpha: 0.12),
        accentColor.withValues(alpha: 0.03),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final vignettePaint = Paint()..shader = radialGradient.createShader(rect);
    canvas.drawRect(rect, vignettePaint);

    // 3. Grade em perspectiva cibernética na parte inferior
    _drawPerspectiveGrid(canvas, size);

    // 4. Partículas flutuantes de dados
    _drawParticles(canvas, size);

    // 5. Linhas sutis de scanline de terminal (apenas a cada 4 pixels)
    final scanlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }
  }

  void _drawPerspectiveGrid(Canvas canvas, Size size) {
    final horizonY = size.height * 0.45;
    final gridPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    // Linhas horizontais com espaçamento logarítmico (efeito 3D)
    final gridOffset = (progress * 30) % 30;
    for (double i = 0; i < 15; i++) {
      final t = (i * 20 + gridOffset) / 300;
      final y = horizonY + pow(t, 2.2) * (size.height - horizonY);
      if (y > size.height) break;

      final alpha = (t * 0.25).clamp(0.0, 0.25);
      final linePaint = Paint()
        ..color = accentColor.withValues(alpha: alpha)
        ..strokeWidth = 1.0;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Linhas verticais que convergem para o ponto de fuga central
    final vanishingPoint = Offset(size.width / 2, horizonY);
    const int verticalCount = 18;
    for (int i = -verticalCount; i <= verticalCount; i++) {
      final bottomX = (size.width / 2) + (i * (size.width / 14));
      canvas.drawLine(vanishingPoint, Offset(bottomX, size.height), gridPaint);
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final p in particles) {
      p.update(0.016); // ~60fps step
      final px = p.x * size.width;
      final py = p.y * size.height;

      final pPaint = Paint()
        ..color = accentColor.withValues(alpha: p.opacity * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

      canvas.drawCircle(Offset(px, py), p.size, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberGridPainter oldDelegate) => true;
}
