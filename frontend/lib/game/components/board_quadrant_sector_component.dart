import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/battle/domain/models/bastion_node.dart';
import '../../features/battle/domain/models/match_state.dart';
import '../../features/battle/domain/models/team_player_model.dart';

/// Componente que renderiza um Quadrante 7x10 de Jogador no Tabuleiro Top-Down.
class BoardQuadrantSectorComponent extends PositionComponent with TapCallbacks {
  TeamPlayerModel player;
  bool isLocalPlayer;
  final bool isFogOfWarActive;
  final Map<String, BastionNode> Function() getNodes;
  final MatchPhase Function() getMatchPhase;
  final void Function(int col, int row)? onCellTapped;

  int? selectedCol;
  int? selectedRow;

  static const int columns = 7;
  static const int rows = 10;

  late final Paint _borderPaint;
  late final Paint _gridLinePaint;
  late final Paint _selectedCellPaint;
  late final Paint _spawnZonePaint;
  late final Paint _fogPaint;

  BoardQuadrantSectorComponent({
    required Vector2 position,
    required Vector2 size,
    required this.player,
    required this.isLocalPlayer,
    this.isFogOfWarActive = false,
    required this.getNodes,
    required this.getMatchPhase,
    this.onCellTapped,
  }) : super(position: position, size: size);

  void setLocalPlayer(bool value) {
    isLocalPlayer = value;
  }

  void updatePlayer(TeamPlayerModel newPlayer) {
    player = newPlayer;
    if (isLoaded) {
      _borderPaint.color = player.color;
      _gridLinePaint.color = player.color.withValues(alpha: 0.15);
      _selectedCellPaint.color = player.color.withValues(alpha: 0.25);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _borderPaint = Paint()
      ..color = player.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    _gridLinePaint = Paint()
      ..color = player.color.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _selectedCellPaint = Paint()
      ..color = player.color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    _spawnZonePaint = Paint()
      ..color = AppColors.redTeam.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    _fogPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Fundo do Quadrante
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final bgPaint = Paint()
      ..color = isLocalPlayer
          ? player.color.withValues(alpha: 0.05)
          : AppColors.cardSurface.withValues(alpha: 0.4);
    canvas.drawRect(rect, bgPaint);

    // Se o Fog of War estiver ativo (base inimiga oculta)
    if (isFogOfWarActive) {
      canvas.drawRect(rect, _fogPaint);
      canvas.drawRect(rect, _borderPaint);

      // Texto de Base Oculta / Fog of War
      final textPainter = TextPainter(
        text: TextSpan(
          text: '🔒 [BASE RIVAL CONFIDENCIAL]\nFOG OF WAR ATIVO',
          style: TextStyle(
            color: player.color.withValues(alpha: 0.6),
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x - 20);

      textPainter.paint(
        canvas,
        Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2),
      );
      return;
    }

    final cellWidth = size.x / columns;
    final cellHeight = size.y / rows;

    final isSpawnZoneAtTop =
        player.quadrant == BoardQuadrant.topLeft || player.quadrant == BoardQuadrant.topRight;

    // 2. Zona de Spawn (no topo para J1/J3, na região inferior após a grade para J2/J4)
    final spawnRect = isSpawnZoneAtTop
        ? Rect.fromLTWH(0, -22, size.x, 20)
        : Rect.fromLTWH(0, size.y + 2, size.x, 20);

    canvas.drawRRect(RRect.fromRectAndRadius(spawnRect, const Radius.circular(4)), _spawnZonePaint);
    final spawnBorder = Paint()
      ..color = AppColors.redTeam.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(spawnRect, const Radius.circular(4)), spawnBorder);

    final spawnText = TextPainter(
      text: TextSpan(
        text: isSpawnZoneAtTop ? '▼ SPAWN ZONE ▼' : '▲ SPAWN ZONE ▲',
        style: const TextStyle(color: AppColors.redTeam, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final spawnTextY = isSpawnZoneAtTop ? -18.0 : (size.y + 6.0);
    spawnText.paint(canvas, Offset((size.x - spawnText.width) / 2, spawnTextY));

    // 3. Linhas da Grade 7x10
    for (int c = 1; c < columns; c++) {
      final x = c * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _gridLinePaint);
    }
    for (int r = 1; r < rows; r++) {
      final y = r * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), _gridLinePaint);
    }

    // 4. Destaque da Célula Selecionada
    if (selectedCol != null && selectedRow != null) {
      final selRect = Rect.fromLTWH(
        selectedCol! * cellWidth,
        selectedRow! * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(selRect, _selectedCellPaint);
      final selBorder = Paint()
        ..color = player.color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawRect(selRect, selBorder);
    }

    // 5. Renderização dos Nós Defensivos alocados neste setor
    final nodes = getNodes();
    final isPrepPhase = getMatchPhase() == MatchPhase.preparation;

    nodes.forEach((key, node) {
      if (node.gridX < 0 || node.gridX >= columns || node.gridY < 0 || node.gridY >= rows) return;

      final nodeCenterX = (node.gridX * cellWidth) + (cellWidth / 2);
      final nodeCenterY = (node.gridY * cellHeight) + (cellHeight / 2);
      final center = Offset(nodeCenterX, nodeCenterY);

      // Raio de alcance na fase de preparação ou se a célula estiver em foco
      if (isPrepPhase || (selectedCol == node.gridX && selectedRow == node.gridY)) {
        final rangePaint = Paint()
          ..color = node.nodeColor.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;
        final rangeBorder = Paint()
          ..color = node.nodeColor.withValues(alpha: 0.35)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        canvas.drawCircle(center, node.attackRange, rangePaint);
        canvas.drawCircle(center, node.attackRange, rangeBorder);
      }

      // Base do Nó com a cor distintiva
      final nodePaint = Paint()
        ..color = node.nodeColor
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = node.nodeColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(center, 16, glowPaint);
      canvas.drawCircle(center, 14, nodePaint);

      // Núcleo interno com contraste
      final coreInner = Paint()..color = AppColors.background;
      canvas.drawCircle(center, 8, coreInner);

      // Ponto de status de defesa do Mainframe (se em guarda central)
      if (node.isDefendingMainframe) {
        final defPulse = Paint()
          ..color = const Color(0xFF00FF66)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, 18, defPulse);
      }

      // Barra de Integridade do Nó
      final integrityRatio = (node.currentIntegrity / node.maxIntegrity).clamp(0.0, 1.0);
      const barWidth = 24.0;
      const barHeight = 3.0;
      final barLeft = nodeCenterX - (barWidth / 2);
      final barTop = nodeCenterY - 18;

      final bgBarPaint = Paint()..color = AppColors.surface;
      final fillBarPaint = Paint()
        ..color = integrityRatio > 0.5
            ? AppColors.bandwidth
            : (integrityRatio > 0.25 ? AppColors.cpuClock : AppColors.redTeam);

      canvas.drawRect(Rect.fromLTWH(barLeft, barTop, barWidth, barHeight), bgBarPaint);
      canvas.drawRect(
        Rect.fromLTWH(barLeft, barTop, barWidth * integrityRatio, barHeight),
        fillBarPaint,
      );
    });

    // 6. Moldura Externa com a Cor Distintiva do Jogador
    canvas.drawRect(rect, _borderPaint);

    // 7. Rótulo de Identificação do Jogador
    final tagText = TextPainter(
      text: TextSpan(
        text: player.name.toUpperCase(),
        style: TextStyle(
          color: player.color,
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tagBg = Paint()..color = AppColors.background.withValues(alpha: 0.9);
    final tagY = isSpawnZoneAtTop ? (size.y - 22.0) : 4.0;
    final tagRect = Rect.fromLTWH(6, tagY, tagText.width + 18, 18);
    canvas.drawRRect(RRect.fromRectAndRadius(tagRect, const Radius.circular(3)), tagBg);

    // Indicador luminoso com a cor distintiva do jogador
    final statusDot = Paint()..color = player.color;
    canvas.drawCircle(Offset(12, tagY + 9), 3.5, statusDot);
    tagText.paint(canvas, Offset(20, tagY + 2));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isFogOfWarActive || !isLocalPlayer) return;

    final cellWidth = size.x / columns;
    final cellHeight = size.y / rows;

    final col = (event.localPosition.x / cellWidth).floor().clamp(0, columns - 1);
    final row = (event.localPosition.y / cellHeight).floor().clamp(0, rows - 1);

    selectedCol = col;
    selectedRow = row;
    onCellTapped?.call(col, row);
  }

  void clearSelection() {
    selectedCol = null;
    selectedRow = null;
  }
}
