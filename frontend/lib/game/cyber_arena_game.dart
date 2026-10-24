import 'dart:async';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../features/battle/domain/models/bastion_node.dart';
import '../features/battle/domain/models/game_card.dart';
import '../features/battle/domain/models/match_state.dart';
import '../features/battle/domain/services/wave_spawner_service.dart';
import '../features/battle/presentation/viewmodels/battle_view_model.dart';
import 'components/data_packet_component.dart';
import 'components/laser_beam_effect.dart';
import 'components/mainframe_component.dart';
import 'components/network_grid_component.dart';
import 'components/panoramic_background_component.dart';

/// Instância do FlameGame responsável pelo canvas 2D panorâmico (2 campos + túneis centrais),
/// simulação física e combate em tempo real estilo Legion TD.
class CyberArenaGame extends FlameGame with PanDetector, ScrollDetector {
  final BattleViewModel viewModel;

  /// Callback invocado quando o jogador toca em uma célula da grade tática
  void Function(int gridX, int gridY)? onGridCellSelected;

  late final NetworkGridComponent _blueGrid;
  late final NetworkGridComponent _redGrid;
  late final MainframeComponent _blueMainframe;
  late final MainframeComponent _redMainframe;

  final WaveSpawnerService _spawner = WaveSpawnerService();
  final Map<String, double> _nodeAttackTimers = {};

  MatchPhase? _lastPhase;
  StreamSubscription? _dispatchSubscription;

  CyberArenaGame({required this.viewModel, this.onGridCellSelected});

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Fundo Panorâmico com os dois campos e túneis de fibra ótica
    world.add(PanoramicBackgroundComponent());

    // 2. Campo do Time Aliado (Blue Team - Esquerda)
    const gridWidth = 360.0;
    const gridHeight = 420.0;
    final blueCenter = Vector2(-440, 0);

    _blueGrid = NetworkGridComponent(
      position: Vector2(blueCenter.x - (gridWidth / 2), blueCenter.y - (gridHeight / 2) - 30),
      size: Vector2(gridWidth, gridHeight),
      getNodes: () => viewModel.state.value.nodes,
      getMatchPhase: () => viewModel.state.value.phase,
      onCellTapped: (col, row) {
        onGridCellSelected?.call(col, row);
      },
    );
    world.add(_blueGrid);

    // Mainframe Central do Time Aliado (posicionado atrás do grid de defesa)
    _blueMainframe = MainframeComponent(
      teamId: 'team_blue',
      position: Vector2(blueCenter.x, blueCenter.y + (gridHeight / 2) + 40),
      getModel: () => viewModel.state.value.mainframeBlue,
      getEnemyPackets: () => world.children
          .whereType<DataPacketComponent>()
          .where((p) => p.origin == PacketOrigin.redExploit && !p.isDead)
          .toList(),
      onDamaged: (dmg) => viewModel.onMainframeDamaged('team_blue', dmg),
    );
    world.add(_blueMainframe);

    // 3. Campo do Time Adversário (Red Team - Direita)
    final redCenter = Vector2(440, 0);

    _redGrid = NetworkGridComponent(
      position: Vector2(redCenter.x - (gridWidth / 2), redCenter.y - (gridHeight / 2) - 30),
      size: Vector2(gridWidth, gridHeight),
      getNodes: () => viewModel.state.value.opponentNodes,
      getMatchPhase: () => viewModel.state.value.phase,
      onCellTapped: (col, row) {},
    );
    world.add(_redGrid);

    // Mainframe Central do Time Adversário
    _redMainframe = MainframeComponent(
      teamId: 'team_red',
      position: Vector2(redCenter.x, redCenter.y + (gridHeight / 2) + 40),
      getModel: () => viewModel.state.value.mainframeRed,
      getEnemyPackets: () => world.children
          .whereType<DataPacketComponent>()
          .where((p) => p.origin == PacketOrigin.blueDefense && !p.isDead)
          .toList(),
      onDamaged: (dmg) => viewModel.onMainframeDamaged('team_red', dmg),
    );
    world.add(_redMainframe);

    // 4. Configuração Inicial da Câmera Panorâmica (focada no grid aliado)
    camera.viewfinder.position = Vector2(blueCenter.x, 20);
    camera.viewfinder.zoom = 0.95;

    // Ouve despachos de cartas emitidos pelo ViewModel
    _dispatchSubscription = viewModel.flameDispatches.listen((event) {
      _spawnCardPackets(event.card, event.lane);
    });
  }

  // --- Controles de Navegação Panorâmica por Gestos (Pan e Zoom) ---

  @override
  void onPanUpdate(DragUpdateInfo info) {
    camera.viewfinder.position -= info.delta.global / camera.viewfinder.zoom;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    final zoomDelta = info.scrollDelta.global.y * 0.001;
    camera.viewfinder.zoom = (camera.viewfinder.zoom - zoomDelta).clamp(0.45, 1.6);
  }

  // --- Âncoras Rápidas de Câmera para o HUD ---

  void focusOnMyGrid() {
    camera.viewfinder.position = Vector2(-440, 20);
    camera.viewfinder.zoom = 0.95;
  }

  void focusOnOpponent() {
    camera.viewfinder.position = Vector2(440, 20);
    camera.viewfinder.zoom = 0.95;
  }

  void focusOnMainframe(bool isBlue) {
    camera.viewfinder.position = isBlue ? Vector2(-440, 250) : Vector2(440, 250);
    camera.viewfinder.zoom = 1.2;
  }

  void focusOnOverview() {
    camera.viewfinder.position = Vector2(0, 30);
    camera.viewfinder.zoom = 0.52;
  }

  void clearGridSelection() {
    _blueGrid.clearSelection();
  }

  void _spawnCardPackets(GameCard card, int lane) {
    final cellWidth = _blueGrid.size.x / _blueGrid.columns;
    final targetX = _blueGrid.position.x + (lane == 0 ? cellWidth * 1.0 : cellWidth * 3.0);
    final startY = _blueGrid.position.y + _blueGrid.size.y - 20;

    final origin = card.type == CardType.exploit || card.type == CardType.payload
        ? PacketOrigin.redExploit
        : PacketOrigin.blueDefense;

    for (int i = 0; i < 3; i++) {
      final packet = DataPacketComponent(
        startPosition: Vector2(targetX + (i * 4 - 4), startY + (i * 20)),
        origin: origin,
        subtype: PacketSubtype.bluePayload,
        direction: Vector2(0, -1),
        speed: 170.0,
        damage: card.basePower / 3,
        maxHealth: 100.0,
      );
      _attachPacketCallbacks(packet);
      world.add(packet);
    }
  }

  void _attachPacketCallbacks(DataPacketComponent packet) {
    final existingCallback = packet.onReachedEnd;
    packet.onReachedEnd = (p) {
      existingCallback?.call(p);
      if (p.origin == PacketOrigin.redExploit) {
        // Pacote inimigo vazou (leak) e atingiu o Mainframe Aliado!
        viewModel.onMainframeDamaged('team_blue', p.damage);
        viewModel.onCoreDamaged(p.damage);
      } else if (p.origin == PacketOrigin.clientTraffic) {
        viewModel.onClientDelivered();
      }
    };

    final existingDestroyed = packet.onDestroyed;
    packet.onDestroyed = (p) {
      existingDestroyed?.call(p);
      if (p.origin == PacketOrigin.redExploit) {
        viewModel.onPacketNeutralized();
      }
    };
  }

  void resetGame() {
    _spawner.reset();
    world.children.whereType<DataPacketComponent>().forEach((p) => p.removeFromParent());
    _nodeAttackTimers.clear();
    clearGridSelection();
    focusOnMyGrid();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final state = viewModel.state.value;

    if (_lastPhase != state.phase) {
      if (state.phase == MatchPhase.battle) {
        _spawner.startWave(state.currentWave);
      } else if (state.phase == MatchPhase.preparation) {
        world.children.whereType<DataPacketComponent>().forEach((p) => p.removeFromParent());
      }
      _lastPhase = state.phase;
    }

    if (state.phase != MatchPhase.battle) return;

    final cellWidth = _blueGrid.size.x / _blueGrid.columns;
    final lane1X = _blueGrid.position.x + (cellWidth * 1.0);
    final lane2X = _blueGrid.position.x + (cellWidth * 3.0);
    final spawnY = _blueGrid.position.y + 10;

    // 1. Spawner de Ondas Inimigas na Rota
    _spawner.update(
      dt: dt,
      lane1X: lane1X,
      lane2X: lane2X,
      startY: spawnY,
      onSpawnPacket: (packet) {
        _attachPacketCallbacks(packet);
        world.add(packet);
      },
      onWaveCompleted: (completedWave) {
        viewModel.onWaveVictory(completedWave);
      },
    );

    // 2. Loop de Combate dos Bastiões Aliados
    _updateBastionCombat(dt, _blueGrid, state.nodes);

    // 3. Colisão Frontal entre Pacotes
    _updatePacketCollisions();
  }

  void _updateBastionCombat(double dt, NetworkGridComponent grid, Map<String, BastionNode> nodes) {
    final cellWidth = grid.size.x / grid.columns;
    final cellHeight = grid.size.y / grid.rows;

    final activeEnemyPackets = world.children
        .whereType<DataPacketComponent>()
        .where((p) => p.origin == PacketOrigin.redExploit && !p.isDead)
        .toList();

    for (final node in nodes.values) {
      _nodeAttackTimers[node.id] = (_nodeAttackTimers[node.id] ?? 0.0) + dt;

      final cadence = node.type == BastionNodeType.idsSentinel
          ? 0.45
          : (node.type == BastionNodeType.firewall ? 0.8 : 0.65);

      if (_nodeAttackTimers[node.id]! < cadence) continue;

      final nodeCenterX = grid.position.x + (node.gridX * cellWidth) + (cellWidth / 2);
      final nodeCenterY = grid.position.y + (node.gridY * cellHeight) + (cellHeight / 2);
      final nodePos = Vector2(nodeCenterX, nodeCenterY);

      DataPacketComponent? closestTarget;
      double closestDistance = double.infinity;

      for (final packet in activeEnemyPackets) {
        final dist = nodePos.distanceTo(packet.position);
        if (dist <= node.attackRange && dist < closestDistance) {
          closestDistance = dist;
          closestTarget = packet;
        }
      }

      if (closestTarget != null) {
        world.add(
          LaserBeamEffect(
            start: nodePos,
            end: closestTarget.position.clone(),
            beamColor: node.nodeColor,
          ),
        );

        final boostedDamage = node.attackDamage * viewModel.state.value.damageMultiplier;
        closestTarget.takeDamage(boostedDamage);
        _nodeAttackTimers[node.id] = 0.0;
      }
    }
  }

  void _updatePacketCollisions() {
    final upwardPackets = world.children
        .whereType<DataPacketComponent>()
        .where((p) => p.direction.y < 0 && !p.isDead)
        .toList();

    final downwardPackets = world.children
        .whereType<DataPacketComponent>()
        .where((p) => p.direction.y > 0 && !p.isDead)
        .toList();

    for (final up in upwardPackets) {
      for (final down in downwardPackets) {
        if (up.position.distanceTo(down.position) < 20.0) {
          up.takeDamage(down.damage);
          down.takeDamage(up.damage);
        }
      }
    }
  }

  @override
  void onRemove() {
    _dispatchSubscription?.cancel();
    super.onRemove();
  }
}
