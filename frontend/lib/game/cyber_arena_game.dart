import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../features/battle/domain/models/game_card.dart';
import '../features/battle/domain/models/match_state.dart';
import '../features/battle/presentation/viewmodels/battle_view_model.dart';
import 'components/data_packet_component.dart';
import 'components/network_grid_component.dart';

/// Instância do FlameGame responsável pelo canvas 2D, simulação física e efeitos visuais da Arena.
class CyberArenaGame extends FlameGame {
  final BattleViewModel viewModel;

  /// Callback invocado quando o jogador toca em uma célula da grade tática
  void Function(int gridX, int gridY)? onGridCellSelected;

  late final NetworkGridComponent _gridComponent;
  StreamSubscription? _dispatchSubscription;
  double _enemySpawnTimer = 0.0;

  CyberArenaGame({required this.viewModel, this.onGridCellSelected});

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Adiciona o Grid de Rede tático ocupando a área central de combate
    final gridWidth = size.x.clamp(320.0, 480.0);
    final gridHeight = size.y * 0.72;
    final gridX = (size.x - gridWidth) / 2;
    final gridY = 70.0;

    _gridComponent = NetworkGridComponent(
      position: Vector2(gridX, gridY),
      size: Vector2(gridWidth, gridHeight),
      getNodes: () => viewModel.state.value.nodes,
      getMatchPhase: () => viewModel.state.value.phase,
      onCellTapped: (col, row) {
        onGridCellSelected?.call(col, row);
      },
    );
    add(_gridComponent);

    // Ouve despachos de cartas emitidos pelo ViewModel
    _dispatchSubscription = viewModel.flameDispatches.listen((event) {
      _spawnCardPackets(event.card, event.lane);
    });
  }

  void clearGridSelection() {
    _gridComponent.clearSelection();
  }

  void _spawnCardPackets(GameCard card, int lane) {
    final cellWidth = _gridComponent.size.x / _gridComponent.columns;
    final targetX = _gridComponent.position.x + (lane == 0 ? cellWidth * 1.0 : cellWidth * 3.0);
    final startY = _gridComponent.position.y + _gridComponent.size.y - 20;

    final origin = card.type == CardType.exploit || card.type == CardType.payload
        ? PacketOrigin.redExploit
        : PacketOrigin.blueDefense;

    // Dispara rajada de pacotes visuais subindo na rota selecionada
    for (int i = 0; i < 3; i++) {
      add(
        DataPacketComponent(
          startPosition: Vector2(targetX + (i * 4 - 4), startY + (i * 20)),
          origin: origin,
          direction: Vector2(0, -1), // Move-se para cima em direção à base inimiga
          speed: 160.0,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Na fase de combate, gera pacotes inimigos simulados descendo pelas rotas
    final state = viewModel.state.value;
    if (state.phase == MatchPhase.battle) {
      _enemySpawnTimer += dt;
      if (_enemySpawnTimer >= 2.5) {
        _enemySpawnTimer = 0.0;
        _spawnEnemyPacket();
      }
    }
  }

  void _spawnEnemyPacket() {
    final cellWidth = _gridComponent.size.x / _gridComponent.columns;
    final lane = DateTime.now().millisecond % 2;
    final targetX = _gridComponent.position.x + (lane == 0 ? cellWidth * 1.0 : cellWidth * 3.0);
    final startY = _gridComponent.position.y + 10;

    add(
      DataPacketComponent(
        startPosition: Vector2(targetX, startY),
        origin: PacketOrigin.redExploit,
        direction: Vector2(0, 1), // Move-se para baixo em direção ao LLM Core
        speed: 110.0,
      ),
    );
  }

  @override
  void onRemove() {
    _dispatchSubscription?.cancel();
    super.onRemove();
  }
}
