import 'dart:async';
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
import 'components/network_grid_component.dart';

/// Instância do FlameGame responsável pelo canvas 2D, simulação física e combate em tempo real.
class CyberArenaGame extends FlameGame {
  final BattleViewModel viewModel;

  /// Callback invocado quando o jogador toca em uma célula da grade tática
  void Function(int gridX, int gridY)? onGridCellSelected;

  late final NetworkGridComponent _gridComponent;
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

    // Adiciona o Grid de Rede tático ocupando a área central de combate
    final gridWidth = size.x.clamp(320.0, 480.0);
    final gridHeight = size.y * 0.72;
    final gridX = (size.x - gridWidth) / 2;
    const gridY = 70.0;

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

    // Ouve despachos de cartas emitidos pelo ViewModel (mão do jogador)
    _dispatchSubscription = viewModel.flameDispatches.listen((event) {
      _spawnCardPackets(event.card, event.lane);
    });
  }

  void clearGridSelection() {
    _gridComponent.clearSelection();
  }

  void _spawnCardPackets(GameCard card, int lane) {
    final cellWidth = _gridComponent.size.x / _gridComponent.columns;
    final targetX = _gridComponent.position.x +
        (lane == 0 ? cellWidth * 1.0 : cellWidth * 3.0);
    final startY = _gridComponent.position.y + _gridComponent.size.y - 20;

    final origin =
        card.type == CardType.exploit || card.type == CardType.payload
            ? PacketOrigin.redExploit
            : PacketOrigin.blueDefense;

    // Dispara rajada de pacotes táticos subindo na rota selecionada
    for (int i = 0; i < 3; i++) {
      final packet = DataPacketComponent(
        startPosition: Vector2(targetX + (i * 4 - 4), startY + (i * 20)),
        origin: origin,
        subtype: PacketSubtype.bluePayload,
        direction: Vector2(0, -1), // Move-se para cima
        speed: 170.0,
        damage: card.basePower / 3,
        maxHealth: 100.0,
      );
      _attachPacketCallbacks(packet);
      add(packet);
    }
  }

  void _attachPacketCallbacks(DataPacketComponent packet) {
    // Quando o pacote alcança o fim de sua trajetória
    final existingCallback = packet.onReachedEnd;
    packet.onReachedEnd = (p) {
      existingCallback?.call(p);
      if (p.origin == PacketOrigin.redExploit) {
        // Pacote inimigo atingiu o Core da base!
        viewModel.onCoreDamaged(p.damage);
      } else if (p.origin == PacketOrigin.clientTraffic) {
        // Tráfego legítimo HTTPS alcançou o servidor com sucesso!
        viewModel.onClientDelivered();
      }
    };

    // Quando um pacote inimigo é destruído por lasers ou colisões
    final existingDestroyed = packet.onDestroyed;
    packet.onDestroyed = (p) {
      existingDestroyed?.call(p);
      if (p.origin == PacketOrigin.redExploit) {
        viewModel.onPacketNeutralized();
      }
    };
  }

  /// Limpa todos os componentes e reinicia a simulação para nova partida
  void resetGame() {
    _spawner.reset();
    children.whereType<DataPacketComponent>().forEach((p) => p.removeFromParent());
    _nodeAttackTimers.clear();
    clearGridSelection();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final state = viewModel.state.value;

    // Detecta transição de fases
    if (_lastPhase != state.phase) {
      if (state.phase == MatchPhase.battle) {
        _spawner.startWave(state.currentWave);
      } else if (state.phase == MatchPhase.preparation) {
        // Limpa pacotes remanescentes na transição de volta para o Turno Zero
        children
            .whereType<DataPacketComponent>()
            .forEach((p) => p.removeFromParent());
      }
      _lastPhase = state.phase;
    }

    if (state.phase != MatchPhase.battle) return;

    final cellWidth = _gridComponent.size.x / _gridComponent.columns;
    final lane1X = _gridComponent.position.x + (cellWidth * 1.0);
    final lane2X = _gridComponent.position.x + (cellWidth * 3.0);
    final spawnY = _gridComponent.position.y + 10;

    // 1. Atualiza o Spawner de Ondas Inimigas e Tráfego de Clientes
    _spawner.update(
      dt: dt,
      lane1X: lane1X,
      lane2X: lane2X,
      startY: spawnY,
      onSpawnPacket: (packet) {
        _attachPacketCallbacks(packet);
        add(packet);
      },
      onWaveCompleted: (completedWave) {
        viewModel.onWaveVictory(completedWave);
      },
    );

    // 2. Loop de Combate dos Bastiões (Detecção por Distância e Disparo de Laser)
    _updateBastionCombat(dt, state.nodes);

    // 3. Colisão entre Pacotes Defensivos (subindo) e Invasores (descendo)
    _updatePacketCollisions();
  }

  void _updateBastionCombat(double dt, Map<String, BastionNode> nodes) {
    final cellWidth = _gridComponent.size.x / _gridComponent.columns;
    final cellHeight = _gridComponent.size.y / _gridComponent.rows;

    final activeEnemyPackets = children
        .whereType<DataPacketComponent>()
        .where((p) => p.origin == PacketOrigin.redExploit && !p.isDead)
        .toList();

    for (final node in nodes.values) {
      // Cooldown individual por nó
      _nodeAttackTimers[node.id] = (_nodeAttackTimers[node.id] ?? 0.0) + dt;

      final cadence = node.type == BastionNodeType.idsSentinel
          ? 0.45
          : (node.type == BastionNodeType.firewall ? 0.8 : 0.65);

      if (_nodeAttackTimers[node.id]! < cadence) continue;

      // Posição no mundo do nó
      final nodeCenterX = _gridComponent.position.x +
          (node.gridX * cellWidth) +
          (cellWidth / 2);
      final nodeCenterY = _gridComponent.position.y +
          (node.gridY * cellHeight) +
          (cellHeight / 2);
      final nodePos = Vector2(nodeCenterX, nodeCenterY);

      // Encontra o pacote mais próximo dentro do attackRange
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
        // Dispara o laser conectando o nó ao pacote alvo
        add(
          LaserBeamEffect(
            start: nodePos,
            end: closestTarget.position.clone(),
            beamColor: node.nodeColor,
          ),
        );

        // Aplica o dano no pacote potencializado por modificadores de perks
        final boostedDamage = node.attackDamage * viewModel.state.value.damageMultiplier;
        closestTarget.takeDamage(boostedDamage);
        _nodeAttackTimers[node.id] = 0.0;
      }
    }
  }

  void _updatePacketCollisions() {
    final upwardPackets = children
        .whereType<DataPacketComponent>()
        .where((p) => p.direction.y < 0 && !p.isDead)
        .toList();

    final downwardPackets = children
        .whereType<DataPacketComponent>()
        .where((p) => p.direction.y > 0 && !p.isDead)
        .toList();

    for (final up in upwardPackets) {
      for (final down in downwardPackets) {
        if (up.position.distanceTo(down.position) < 20.0) {
          // Colisão frontal nas rotas
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
