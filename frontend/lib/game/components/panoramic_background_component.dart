import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Renderiza o cenário de fundo panorâmico com os dois campos (Blue vs Red).
class PanoramicBackgroundComponent extends PositionComponent {
  PanoramicBackgroundComponent()
      : super(
          position: Vector2(-1600, -1100),
          size: Vector2(4200, 2200),
          priority: -10,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

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

    // 2. Campo do Time Aliado (Esquerda - Blue Team, centrado em x = -440 no mundo -> cx = 1160)
    final blueZoneRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(450, 240, 1420, 1720),
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

    // 3. Campo do Time Oponente (Direita - Red Team: centrado em x = 1240 no mundo -> cx = 2840)
    final redZoneRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2130, 240, 1420, 1720),
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
  }
}

