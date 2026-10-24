import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../../core/theme/app_colors.dart';
import '../../features/battle/domain/models/bastion_node.dart';
import '../../features/battle/domain/models/match_state.dart';

/// Grade tática de rede onde nós de defesa são alocados (estilo Legion TD).
class NetworkGridComponent extends PositionComponent with TapCallbacks {
  final int columns;
  final int rows;
  final Map<String, BastionNode> Function() getNodes;
  final MatchPhase Function() getMatchPhase;
  final void Function(int gridX, int gridY) onCellTapped;

  int? selectedGridX;
  int? selectedGridY;

  late final Paint _gridLinePaint;
  late final Paint _lanePaint;
  late final Paint _selectedCellPaint;
  late final Paint _corePaint;
  late final Paint _coreGlowPaint;

  NetworkGridComponent({
    required Vector2 position,
    required Vector2 size,
    required this.getNodes,
    required this.getMatchPhase,
    required this.onCellTapped,
    this.columns = 4,
    this.rows = 6,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _gridLinePaint = Paint()
      ..color = AppColors.border.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _lanePaint = Paint()
      ..color = AppColors.blueTeam.withOpacity(0.10)
      ..strokeWidth = 36.0
      ..style = PaintingStyle.stroke;

    _selectedCellPaint = Paint()
      ..color = AppColors.blueTeam.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    _corePaint = Paint()
      ..color = AppColors.coreAi
      ..style = PaintingStyle.fill;

    _coreGlowPaint = Paint()
      ..color = AppColors.coreAi.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cellWidth = size.x / columns;
    final cellHeight = size.y / rows;

    // 1. Desenha as 2 Rotas Principais de Tráfego de Pacotes (Lanes estilo Clash Royale)
    final lane1X = cellWidth * 1.0;
    final lane2X = cellWidth * 3.0;

    canvas.drawLine(Offset(lane1X, 0), Offset(lane1X, size.y), _lanePaint);
    canvas.drawLine(Offset(lane2X, 0), Offset(lane2X, size.y), _lanePaint);

    // 2. Destaca a célula selecionada
    if (selectedGridX != null && selectedGridY != null) {
      final selRect = Rect.fromLTWH(
        selectedGridX! * cellWidth,
        selectedGridY! * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(selRect, _selectedCellPaint);
      final borderPaint = Paint()
        ..color = AppColors.blueTeam
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(selRect, borderPaint);
    }

    // 3. Linhas da Grade de Construção (Legion TD)
    for (int col = 0; col <= columns; col++) {
      final x = col * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _gridLinePaint);
    }
    for (int row = 0; row <= rows; row++) {
      final y = row * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), _gridLinePaint);
    }

    // 4. Desenha o LLM Core na base do grid (Torre Rei / Cérebro da Cidadela)
    final coreCenter = Offset(size.x / 2, size.y - (cellHeight / 2));
    canvas.drawCircle(coreCenter, 24, _coreGlowPaint);
    canvas.drawCircle(coreCenter, 20, _corePaint);

    // 5. Desenha os Nós Defensivos alocados com suas respectivas cores e anéis
    final nodes = getNodes();
    final isPrepPhase = getMatchPhase() == MatchPhase.preparation;

    nodes.forEach((key, node) {
      final nodeCenterX = (node.gridX * cellWidth) + (cellWidth / 2);
      final nodeCenterY = (node.gridY * cellHeight) + (cellHeight / 2);
      final center = Offset(nodeCenterX, nodeCenterY);

      // Raio de alcance na fase de preparação ou se a célula estiver em foco
      if (isPrepPhase || (selectedGridX == node.gridX && selectedGridY == node.gridY)) {
        final rangePaint = Paint()
          ..color = node.nodeColor.withOpacity(0.08)
          ..style = PaintingStyle.fill;
        final rangeBorder = Paint()
          ..color = node.nodeColor.withOpacity(0.35)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(center, node.attackRange, rangePaint);
        canvas.drawCircle(center, node.attackRange, rangeBorder);
      }

      // Base do Nó com cor de seu tipo
      final nodePaint = Paint()
        ..color = node.nodeColor
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = node.nodeColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(center, 18, glowPaint);
      canvas.drawCircle(center, 16, nodePaint);

      // Barra de Integridade do Nó
      final integrityRatio = (node.currentIntegrity / node.maxIntegrity).clamp(0.0, 1.0);
      final barWidth = 30.0;
      final barHeight = 4.0;
      final barLeft = nodeCenterX - (barWidth / 2);
      final barTop = nodeCenterY - 24;

      final bgPaint = Paint()..color = AppColors.surface;
      final fillPaint = Paint()
        ..color = integrityRatio > 0.5
            ? AppColors.bandwidth
            : (integrityRatio > 0.25 ? AppColors.cpuClock : AppColors.redTeam);

      canvas.drawRect(Rect.fromLTWH(barLeft, barTop, barWidth, barHeight), bgPaint);
      canvas.drawRect(
        Rect.fromLTWH(barLeft, barTop, barWidth * integrityRatio, barHeight),
        fillPaint,
      );
    });
  }

  @override
  void onTapDown(TapDownEvent event) {
    final cellWidth = size.x / columns;
    final cellHeight = size.y / rows;

    final localPos = event.localPosition;
    final gridX = (localPos.x / cellWidth).floor().clamp(0, columns - 1);
    final gridY = (localPos.y / cellHeight).floor().clamp(0, rows - 1);

    selectedGridX = gridX;
    selectedGridY = gridY;

    onCellTapped(gridX, gridY);
  }

  void clearSelection() {
    selectedGridX = null;
    selectedGridY = null;
  }
}
