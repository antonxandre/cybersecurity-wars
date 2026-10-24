import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../../core/theme/app_colors.dart';
import '../../features/battle/domain/models/bastion_node.dart';
import '../cyber_arena_game.dart';

/// Componente visual e físico do Nó Defensivo no Flame Engine.
class BastionNodeComponent extends PositionComponent with HasGameReference<CyberArenaGame> {
  final BastionNode node;
  final bool showRange;

  double _pulseTime = 0.0;
  late final Paint _rangePaint;
  late final Paint _rangeBorderPaint;
  late final Paint _basePaint;
  late final Paint _ringPaint;
  late final Paint _glowPaint;

  BastionNodeComponent({
    required this.node,
    required Vector2 position,
    this.showRange = true,
  }) : super(
          position: position,
          size: Vector2(40, 40),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final color = node.nodeColor;

    _rangePaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    _rangeBorderPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _basePaint = Paint()
      ..color = AppColors.cardSurface
      ..style = PaintingStyle.fill;

    _ringPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final pulseScale = 1.0 + (sin(_pulseTime * 3) * 0.08);

    // 1. Círculo do Raio de Alcance (se ativado na fase de preparação ou foco)
    if (showRange) {
      canvas.drawCircle(center, node.attackRange, _rangePaint);
      canvas.drawCircle(center, node.attackRange, _rangeBorderPaint);
    }

    // 2. Anel de Pulso Neon Externo
    canvas.drawCircle(center, (size.x / 2 + 2) * pulseScale, _glowPaint);

    // 3. Base do Nó
    canvas.drawCircle(center, size.x / 2, _basePaint);
    canvas.drawCircle(center, size.x / 2, _ringPaint);

    // 4. Desenha o Glifo Central característico do Nó
    _renderNodeGlyph(canvas, center);

    // 5. Barra de Integridade Superior
    _renderHealthBar(canvas, center);
  }

  void _renderNodeGlyph(Canvas canvas, Offset center) {
    final glyphPaint = Paint()
      ..color = node.nodeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    switch (node.type) {
      case BastionNodeType.firewall:
        // Desenha um Escudo Estilizado
        final path = Path()
          ..moveTo(center.dx, center.dy - 10)
          ..lineTo(center.dx + 8, center.dy - 6)
          ..lineTo(center.dx + 6, center.dy + 6)
          ..lineTo(center.dx, center.dy + 10)
          ..lineTo(center.dx - 6, center.dy + 6)
          ..lineTo(center.dx - 8, center.dy - 6)
          ..close();
        canvas.drawPath(path, glyphPaint);
        break;

      case BastionNodeType.idsSentinel:
        // Desenha uma Mira Radar com círculos concêntricos
        canvas.drawCircle(center, 6, glyphPaint);
        canvas.drawLine(
          Offset(center.dx - 9, center.dy),
          Offset(center.dx + 9, center.dy),
          glyphPaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - 9),
          Offset(center.dx, center.dy + 9),
          glyphPaint,
        );
        break;

      case BastionNodeType.wafProxy:
        // Desenha um Funil de Filtro Semântico
        final path = Path()
          ..moveTo(center.dx - 8, center.dy - 8)
          ..lineTo(center.dx + 8, center.dy - 8)
          ..lineTo(center.dx + 2, center.dy + 2)
          ..lineTo(center.dx + 2, center.dy + 8)
          ..lineTo(center.dx - 2, center.dy + 8)
          ..lineTo(center.dx - 2, center.dy + 2)
          ..close();
        canvas.drawPath(path, glyphPaint);
        break;

      case BastionNodeType.honeypot:
        // Desenha um Hexágono de Colmeia
        final r = 8.0;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60) * (pi / 180);
          final x = center.dx + r * cos(angle);
          final y = center.dy + r * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, glyphPaint);
        break;

      case BastionNodeType.vpnGateway:
        // Desenha uma Chave / Cadeado
        canvas.drawCircle(Offset(center.dx, center.dy - 3), 4, glyphPaint);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: 10, height: 7),
          glyphPaint,
        );
        break;
    }
  }

  void _renderHealthBar(Canvas canvas, Offset center) {
    final barWidth = 32.0;
    final barHeight = 4.0;
    final barLeft = center.dx - (barWidth / 2);
    final barTop = center.dy - (size.y / 2) - 8;

    final ratio = (node.currentIntegrity / node.maxIntegrity).clamp(0.0, 1.0);

    final bgPaint = Paint()..color = AppColors.surface;
    final fillPaint = Paint()
      ..color = ratio > 0.5
          ? AppColors.bandwidth
          : (ratio > 0.25 ? AppColors.cpuClock : AppColors.redTeam);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        const Radius.circular(2),
      ),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth * ratio, barHeight),
        const Radius.circular(2),
      ),
      fillPaint,
    );
  }
}
