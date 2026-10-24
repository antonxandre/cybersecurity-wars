import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Renderiza o cenário de fundo panorâmico com os dois campos (Blue vs Red),
/// túneis centrais de fibra ótica e indicadores cibernéticos de alta velocidade.
class PanoramicBackgroundComponent extends PositionComponent {
  double _pulseTimer = 0.0;

  PanoramicBackgroundComponent()
      : super(
          position: Vector2(-900, -500),
          size: Vector2(1800, 1000),
          priority: -10,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer = (_pulseTimer + dt * 2.5) % (math.pi * 2);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pulse = 0.5 + 0.5 * math.sin(_pulseTimer);

    // 1. Grid Cibernético de Fundo (World Grid)
    final gridPaint = Paint()
      ..color = const Color(0xFF141926).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.x; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    // 2. Campo do Time Aliado (Esquerda - Blue Team)
    final blueZoneRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(180, 220, 520, 560),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      blueZoneRect,
      Paint()
        ..color = AppColors.blueTeam.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      blueZoneRect,
      Paint()
        ..color = AppColors.blueTeam.withValues(alpha: 0.3)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // 3. Campo do Time Oponente (Direita - Red Team)
    final redZoneRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1100, 220, 520, 560),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      redZoneRect,
      Paint()
        ..color = AppColors.redTeam.withValues(alpha: 0.04)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      redZoneRect,
      Paint()
        ..color = AppColors.redTeam.withValues(alpha: 0.3)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // 4. Túneis Centrais de Fibra Ótica Inter-Bases (Conectores de Tráfego)
    const tunnelY1 = 440.0;
    const tunnelY2 = 540.0;

    final tunnelPipePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2.0;

    final tunnelFlowPaint = Paint()
      ..color = AppColors.coreAi.withValues(alpha: 0.4 + (pulse * 0.4))
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Tubo Superior
    canvas.drawLine(const Offset(700, tunnelY1), const Offset(1100, tunnelY1), tunnelPipePaint);
    canvas.drawLine(const Offset(700, tunnelY1), const Offset(1100, tunnelY1), tunnelFlowPaint);

    // Tubo Inferior
    canvas.drawLine(const Offset(700, tunnelY2), const Offset(1100, tunnelY2), tunnelPipePaint);
    canvas.drawLine(const Offset(700, tunnelY2), const Offset(1100, tunnelY2), tunnelFlowPaint);

    // Rótulos Centrais dos Túneis
    final textPainter = TextPainter(
      text: TextSpan(
        text: '<< TÚNEIS DE TRÁFEGO DE ALTA VELOCIDADE // FIBRA ÓTICA >>',
        style: TextStyle(
          color: AppColors.coreAi.withValues(alpha: 0.8),
          fontSize: 11,
          fontFamily: 'JetBrainsMono',
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, const Offset(710, 485));
  }
}
