import 'dart:async';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/rules/game_rule_engine.dart';
import '../core/theme/app_colors.dart';
import '../features/battle/domain/models/bastion_node.dart';
import '../features/battle/domain/models/game_card.dart';
import '../features/battle/domain/models/match_state.dart';
import '../features/battle/domain/models/team_player_model.dart';
import '../features/battle/domain/models/tactical_unit_info.dart';
import '../features/battle/domain/services/wave_spawner_service.dart';
import '../features/battle/presentation/viewmodels/battle_view_model.dart';
import 'components/board_quadrant_sector_component.dart';
import 'components/data_packet_component.dart';
import 'components/laser_beam_effect.dart';
import 'components/mainframe_component.dart';
import 'components/middle_transit_zone_component.dart';
import 'components/panoramic_background_component.dart';

/// Instância do FlameGame responsável pelo canvas 2D do Tabuleiro Top-Down 4v4,
/// com 4 setores para cada time, Mainframe Central e simulação física de combate em tempo real.
class CyberArenaGame extends FlameGame with PanDetector, ScrollDetector {
  final BattleViewModel viewModel;

  /// Callback invocado quando o jogador toca em uma célula da grade tática local (J1)
  void Function(int gridX, int gridY)? onGridCellSelected;

  /// Callback invocado quando uma unidade tática (Mainframe, Bastião, Malware) é selecionada
  void Function(TacticalUnitInfo unitInfo, Vector2 worldPosition)? onTacticalUnitSelected;

  /// Callback invocado quando a câmera é movimentada
  VoidCallback? onCameraMoved;

  // Contagem de unidades que vazaram (leaks) da grade para a arena central
  int totalLeaks = 0;

  // 4 Setores do Time Aliado (Blue Team)
  late final BoardQuadrantSectorComponent _sectorAllyTL; // J1 - Jogador 1 (Local)
  late final BoardQuadrantSectorComponent _sectorAllyBL; // J2 - Jogador 2
  late final BoardQuadrantSectorComponent _sectorAllyTR; // J3 - Jogador 3
  late final BoardQuadrantSectorComponent _sectorAllyBR; // J4 - Jogador 4

  // 4 Setores do Time Adversário (Red Team - Ocultos por Fog of War)
  late final BoardQuadrantSectorComponent _sectorRivalTL;
  late final BoardQuadrantSectorComponent _sectorRivalBL;
  late final BoardQuadrantSectorComponent _sectorRivalTR;
  late final BoardQuadrantSectorComponent _sectorRivalBR;

  // Mainframes Centrais
  late final MainframeComponent _blueMainframe;
  late final MainframeComponent _redMainframe;

  final WaveSpawnerService _spawnerTL = WaveSpawnerService();
  final WaveSpawnerService _spawnerBL = WaveSpawnerService();
  final WaveSpawnerService _spawnerTR = WaveSpawnerService();
  final WaveSpawnerService _spawnerBR = WaveSpawnerService();
  final Map<String, double> _nodeAttackTimers = {};

  MatchPhase? _lastPhase;
  StreamSubscription? _dispatchSubscription;

  /// Quadrante controlado pelo jogador nesta instância da Arena (Top-Left para J1, Bottom-Left para J2)
  BoardQuadrant localQuadrant;

  CyberArenaGame({
    required this.viewModel,
    this.onGridCellSelected,
    this.localQuadrant = BoardQuadrant.topLeft,
  });

  /// Define o quadrante do jogador local dinamicamente e reposiciona a câmera
  void setLocalQuadrant(BoardQuadrant quadrant) {
    localQuadrant = quadrant;
    if (isLoaded) {
      _sectorAllyTL.setLocalPlayer(quadrant == BoardQuadrant.topLeft);
      _sectorAllyBL.setLocalPlayer(quadrant == BoardQuadrant.bottomLeft);
      _sectorAllyTR.setLocalPlayer(quadrant == BoardQuadrant.topRight);
      _sectorAllyBR.setLocalPlayer(quadrant == BoardQuadrant.bottomRight);
    }
    focusOnSector(quadrant);
  }

  /// Atualiza os jogadores vinculados aos setores de quadrante
  void updateSectorPlayers({List<TeamPlayerModel>? bluePlayers, List<TeamPlayerModel>? redPlayers}) {
    if (!isLoaded) return;
    if (bluePlayers != null && bluePlayers.isNotEmpty) {
      _sectorAllyTL.updatePlayer(bluePlayers[0]);
      if (bluePlayers.length > 1) {
        _sectorAllyBL.updatePlayer(bluePlayers[1]);
      }
    }
    if (redPlayers != null && redPlayers.isNotEmpty) {
      _sectorAllyTR.updatePlayer(redPlayers[0]);
      if (redPlayers.length > 1) {
        _sectorAllyBR.updatePlayer(redPlayers[1]);
      }
    }
  }

  /// Retorna o componente de setor associado ao jogador local
  BoardQuadrantSectorComponent getLocalSector() {
    switch (localQuadrant) {
      case BoardQuadrant.topLeft:
        return _sectorAllyTL;
      case BoardQuadrant.bottomLeft:
        return _sectorAllyBL;
      case BoardQuadrant.topRight:
        return _sectorAllyTR;
      case BoardQuadrant.bottomRight:
        return _sectorAllyBR;
    }
  }

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Fundo Panorâmico com os dois campos e túneis de fibra ótica
    world.add(PanoramicBackgroundComponent());

    final state = viewModel.state.value;
    final bluePlayers = state.allyPlayers.isNotEmpty ? state.allyPlayers : TeamPlayerModel.initialBlueTeam();
    final redPlayers = state.opponentPlayers.isNotEmpty ? state.opponentPlayers : TeamPlayerModel.initialRedTeam();

    const sectorWidth = 350.0;
    const sectorHeight = 500.0;
    final sectorSize = Vector2(sectorWidth, sectorHeight);

    // 2. Setores do Time Aliado (Blue Team - Esquerda, distanciados a 300px do Mainframe em X e Y)
    // Blue Mainframe em (-440, 0). Distância de 300px:
    // Eixo X: Coluna Esquerda termina em x = -740; Coluna Direita inicia em x = -140
    // Eixo Y: Top termina em y = -300; Bottom inicia em y = 300
    // J1: Top-Left (Jogador 1)
    _sectorAllyTL = BoardQuadrantSectorComponent(
      position: Vector2(-1090, -800),
      size: sectorSize,
      player: bluePlayers[0],
      isLocalPlayer: localQuadrant == BoardQuadrant.topLeft,
      getNodes: () => viewModel.getQuadrantNodes(BoardQuadrant.topLeft),
      getMatchPhase: () => viewModel.state.value.phase,
      onCellTapped: (col, row) {
        if (localQuadrant == BoardQuadrant.topLeft) {
          onGridCellSelected?.call(col, row);
        }
      },
    );
    world.add(_sectorAllyTL);

    // J2: Bottom-Left (Jogador 2)
    _sectorAllyBL = BoardQuadrantSectorComponent(
      position: Vector2(-1090, 300),
      size: sectorSize,
      player: bluePlayers.length > 1 ? bluePlayers[1] : bluePlayers[0],
      isLocalPlayer: localQuadrant == BoardQuadrant.bottomLeft,
      getNodes: () => viewModel.getQuadrantNodes(BoardQuadrant.bottomLeft),
      getMatchPhase: () => viewModel.state.value.phase,
      onCellTapped: (col, row) {
        if (localQuadrant == BoardQuadrant.bottomLeft) {
          onGridCellSelected?.call(col, row);
        }
      },
    );
    world.add(_sectorAllyBL);

    // J3: Top-Right (Jogador 3)
    _sectorAllyTR = BoardQuadrantSectorComponent(
      position: Vector2(-140, -800),
      size: sectorSize,
      player: bluePlayers.length > 2 ? bluePlayers[2] : bluePlayers[0],
      isLocalPlayer: localQuadrant == BoardQuadrant.topRight,
      getNodes: () => viewModel.getQuadrantNodes(BoardQuadrant.topRight),
      getMatchPhase: () => viewModel.state.value.phase,
      onCellTapped: (col, row) {
        if (localQuadrant == BoardQuadrant.topRight) {
          onGridCellSelected?.call(col, row);
        }
      },
    );
    world.add(_sectorAllyTR);

    // J4: Bottom-Right (Jogador 4)
    _sectorAllyBR = BoardQuadrantSectorComponent(
      position: Vector2(-140, 300),
      size: sectorSize,
      player: bluePlayers.length > 3 ? bluePlayers[3] : bluePlayers[0],
      isLocalPlayer: localQuadrant == BoardQuadrant.bottomRight,
      getNodes: () => viewModel.getQuadrantNodes(BoardQuadrant.bottomRight),
      getMatchPhase: () => viewModel.state.value.phase,
      onCellTapped: (col, row) {
        if (localQuadrant == BoardQuadrant.bottomRight) {
          onGridCellSelected?.call(col, row);
        }
      },
    );
    world.add(_sectorAllyBR);

    // Mainframe Central do Time Aliado (no centro dos 4 quadrantes aliados: x = -440, y = 0)
    _blueMainframe = MainframeComponent(
      teamId: 'team_blue',
      position: Vector2(-440, 0),
      size: Vector2(100, 70),
      getModel: () => viewModel.state.value.mainframeBlue,
      getEnemyPackets: () => world.children
          .whereType<DataPacketComponent>()
          .where((p) => p.origin == PacketOrigin.redExploit && !p.isDead)
          .toList(),
      onDamaged: (dmg) => viewModel.onMainframeDamaged('team_blue', dmg),
      onTapped: (comp) {
        final info = TacticalUnitInfo.fromMainframe(
          mainframe: comp.model,
          isBlue: true,
        );
        onTacticalUnitSelected?.call(info, comp.position);
      },
    );
    world.add(_blueMainframe);

    // 3. Setores do Time Adversário (Red Team - Direita, distanciados a 300px do Mainframe Rival)
    // Red Mainframe em (1240, 0). Distância de 300px:
    // Eixo X: Coluna Esquerda termina em x = 940; Coluna Direita inicia em x = 1540
    // Eixo Y: Top termina em y = -300; Bottom inicia em y = 300
    _sectorRivalTL = BoardQuadrantSectorComponent(
      position: Vector2(590, -800),
      size: sectorSize,
      player: redPlayers[0],
      isLocalPlayer: false,
      isFogOfWarActive: false,
      getNodes: () => viewModel.state.value.opponentNodes,
      getMatchPhase: () => viewModel.state.value.phase,
    );
    world.add(_sectorRivalTL);

    _sectorRivalBL = BoardQuadrantSectorComponent(
      position: Vector2(590, 300),
      size: sectorSize,
      player: redPlayers.length > 1 ? redPlayers[1] : redPlayers[0],
      isLocalPlayer: false,
      isFogOfWarActive: true,
      getNodes: () => const {},
      getMatchPhase: () => viewModel.state.value.phase,
    );
    world.add(_sectorRivalBL);

    _sectorRivalTR = BoardQuadrantSectorComponent(
      position: Vector2(1540, -800),
      size: sectorSize,
      player: redPlayers.length > 2 ? redPlayers[2] : redPlayers[0],
      isLocalPlayer: false,
      isFogOfWarActive: true,
      getNodes: () => const {},
      getMatchPhase: () => viewModel.state.value.phase,
    );
    world.add(_sectorRivalTR);

    _sectorRivalBR = BoardQuadrantSectorComponent(
      position: Vector2(1540, 300),
      size: sectorSize,
      player: redPlayers.length > 3 ? redPlayers[3] : redPlayers[0],
      isLocalPlayer: false,
      isFogOfWarActive: true,
      getNodes: () => const {},
      getMatchPhase: () => viewModel.state.value.phase,
    );
    world.add(_sectorRivalBR);

    // Mainframe Central do Time Adversário (Visível no centro do campo rival: x = 1240, y = 0)
    _redMainframe = MainframeComponent(
      teamId: 'team_red',
      position: Vector2(1240, 0),
      size: Vector2(100, 70),
      getModel: () => viewModel.state.value.mainframeRed,
      getEnemyPackets: () => world.children
          .whereType<DataPacketComponent>()
          .where((p) => p.origin == PacketOrigin.blueDefense && !p.isDead)
          .toList(),
      onDamaged: (dmg) => viewModel.onMainframeDamaged('team_red', dmg),
      onTapped: (comp) {
        final info = TacticalUnitInfo.fromMainframe(
          mainframe: comp.model,
          isBlue: false,
        );
        onTacticalUnitSelected?.call(info, comp.position);
      },
    );
    world.add(_redMainframe);

    // 4. Áreas Intermediárias (The Middle between players) com Waypoint e setas direcionais ao Mainframe
    // Meio exatamente entre Jogador 1 e Jogador 2 (Time Aliado, coluna esquerda)
    world.add(MiddleTransitZoneComponent(
      position: Vector2(-1090, -25),
      size: Vector2(sectorWidth, 50),
      arrowDirection: TransitZoneDirection.toRight,
      isBlueTeam: true,
    ));

    // Meio exatamente entre Jogador 3 e Jogador 4 (Time Aliado, coluna direita)
    world.add(MiddleTransitZoneComponent(
      position: Vector2(-140, -25),
      size: Vector2(sectorWidth, 50),
      arrowDirection: TransitZoneDirection.toLeft,
      isBlueTeam: true,
    ));

    // Meio entre Jogador 1 e Jogador 2 (Time Rival, coluna esquerda)
    world.add(MiddleTransitZoneComponent(
      position: Vector2(590, -25),
      size: Vector2(sectorWidth, 50),
      arrowDirection: TransitZoneDirection.toRight,
      isBlueTeam: false,
    ));

    // Meio entre Jogador 3 e Jogador 4 (Time Rival, coluna direita)
    world.add(MiddleTransitZoneComponent(
      position: Vector2(1540, -25),
      size: Vector2(sectorWidth, 50),
      arrowDirection: TransitZoneDirection.toLeft,
      isBlueTeam: false,
    ));

    // 5. Configuração Inicial da Câmera: Visão Geral Tática Padrão do Tabuleiro Aliado
    focusOnOverview();

    // Ouve despachos de cartas emitidos pelo ViewModel
    _dispatchSubscription = viewModel.flameDispatches.listen((event) {
      _spawnCardPackets(event.card, event.lane);
    });
  }

  // --- Controles de Navegação Panorâmica por Gestos (Pan e Zoom) ---

  @override
  void onPanUpdate(DragUpdateInfo info) {
    camera.viewfinder.position -= info.delta.global / camera.viewfinder.zoom;
    onCameraMoved?.call();
  }

  @override
  void onScroll(PointerScrollInfo info) {
    final zoomDelta = info.scrollDelta.global.y * 0.001;
    camera.viewfinder.zoom = (camera.viewfinder.zoom - zoomDelta).clamp(0.40, 1.8);
    onCameraMoved?.call();
  }

  // --- Âncoras Rápidas de Câmera Tática (RTS Style) ---

  /// Visão Tática Geral Padrão: exibe os 4 quadrantes aliados e o Mainframe central simultaneamente
  void focusOnOverview() {
    camera.viewfinder.position = Vector2(-440, 0);
    camera.viewfinder.zoom = 0.45;
    onCameraMoved?.call();
  }

  /// Foco direto no setor do jogador local (Top-Left ou Bottom-Left)
  void focusOnMyGrid() {
    focusOnSector(localQuadrant);
  }

  /// Foca a câmera em um quadrante específico com zoom para alocação/inspeção de unidades
  void focusOnSector(BoardQuadrant quadrant) {
    switch (quadrant) {
      case BoardQuadrant.topLeft:
        camera.viewfinder.position = Vector2(-915, -550);
        break;
      case BoardQuadrant.bottomLeft:
        camera.viewfinder.position = Vector2(-915, 550);
        break;
      case BoardQuadrant.topRight:
        camera.viewfinder.position = Vector2(35, -550);
        break;
      case BoardQuadrant.bottomRight:
        camera.viewfinder.position = Vector2(35, 550);
        break;
    }
    camera.viewfinder.zoom = 1.05;
    onCameraMoved?.call();
  }

  /// Visão Global Completa de ambos os campos (Aliado + Neutral Zone + Rival)
  void focusOnFullBattlefield() {
    camera.viewfinder.position = Vector2(400, 0);
    camera.viewfinder.zoom = 0.25;
    onCameraMoved?.call();
  }

  /// Foco no campo adversário (Mainframe central visível e bases sob Fog of War)
  void focusOnOpponent() {
    camera.viewfinder.position = Vector2(1240, 0);
    camera.viewfinder.zoom = 0.45;
    onCameraMoved?.call();
  }

  /// Foco centrado no Mainframe de uma das equipes
  void focusOnMainframe(bool isBlue) {
    camera.viewfinder.position = isBlue ? Vector2(-440, 0) : Vector2(1240, 0);
    camera.viewfinder.zoom = 1.35;
    onCameraMoved?.call();
  }

  void clearGridSelection() {
    _sectorAllyTL.clearSelection();
    _sectorAllyBL.clearSelection();
    _sectorAllyTR.clearSelection();
    _sectorAllyBR.clearSelection();
  }

  /// Retorna as coordenadas de projeção no canvas/tela do Flutter para qualquer posição de mundo
  Vector2 getWorldScreenPosition(Vector2 worldPos) {
    return camera.localToGlobal(worldPos);
  }

  /// Retorna a posição em tela do Mainframe
  Vector2 getMainframeScreenPosition(bool isBlue) {
    final pos = isBlue ? _blueMainframe.position : _redMainframe.position;
    return camera.localToGlobal(pos);
  }

  /// Retorna as coordenadas de mundo para uma célula do grid local ativo (J1 ou J2)
  Vector2 getCellWorldPosition(int gridX, int gridY) {
    final sector = getLocalSector();
    final cellWidth = sector.size.x / BoardQuadrantSectorComponent.columns;
    final cellHeight = sector.size.y / BoardQuadrantSectorComponent.rows;
    final localPos = Vector2(
      (gridX + 0.5) * cellWidth,
      (gridY + 0.5) * cellHeight,
    );
    return sector.position + localPos;
  }

  /// Retorna as coordenadas de projeção no canvas/tela do Flutter para uma célula do grid local ativo
  Vector2 getCellScreenPosition(int gridX, int gridY) {
    return camera.localToGlobal(getCellWorldPosition(gridX, gridY));
  }

  void _spawnCardPackets(GameCard card, int lane) {
    final sector = getLocalSector();
    final cellWidth = sector.size.x / BoardQuadrantSectorComponent.columns;
    final targetX = sector.position.x + (lane == 0 ? cellWidth * 1.5 : cellWidth * 5.5);
    final startY = sector.position.y + sector.size.y - 10;

    // Todas as cartas lançadas pelo jogador no tabuleiro aliado atuam como defesas do time azul
    const origin = PacketOrigin.blueDefense;

    for (int i = 0; i < 3; i++) {
      final packet = DataPacketComponent(
        startPosition: Vector2(targetX + (i * 4 - 4), startY + (i * 20)),
        origin: origin,
        subtype: PacketSubtype.bluePayload,
        direction: Vector2(0, -1),
        speed: 170.0,
        damage: card.basePower / 3,
        maxHealth: 100.0,
        assignedQuadrant: BoardQuadrant.topLeft,
        teamId: 'team_blue',
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

    packet.onTapped = (p) {
      final info = TacticalUnitInfo.fromDataPacket(
        id: 'packet_${p.hashCode}',
        subtypeName: p.subtypeDisplayName,
        originName: p.origin.name,
        currentHealth: p.currentHealth,
        maxHealth: p.maxHealth,
        damage: p.damage,
        speed: p.speed,
        isLeaked: p.isLeaked,
        isAlly: p.origin == PacketOrigin.blueDefense,
        movementStateDesc: p.movementStateDescription,
      );
      onTacticalUnitSelected?.call(info, p.position);
    };
  }

  void resetGame() {
    _spawnerTL.reset();
    _spawnerBL.reset();
    _spawnerTR.reset();
    _spawnerBR.reset();
    totalLeaks = 0;
    world.children.whereType<DataPacketComponent>().forEach((p) => p.removeFromParent());
    _nodeAttackTimers.clear();
    clearGridSelection();
    focusOnOverview();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final state = viewModel.state.value;

    if (_lastPhase != state.phase) {
      if (state.phase == MatchPhase.battle) {
        _spawnerTL.startWave(state.currentWave);
        _spawnerBL.startWave(state.currentWave);
        _spawnerTR.startWave(state.currentWave);
        _spawnerBR.startWave(state.currentWave);
      } else if (state.phase == MatchPhase.preparation) {
        world.children.whereType<DataPacketComponent>().forEach((p) => p.removeFromParent());
      }
      _lastPhase = state.phase;
    }

    if (state.phase != MatchPhase.battle) return;

    final cellWidth = _sectorAllyTL.size.x / BoardQuadrantSectorComponent.columns;
    final lane1Offset = cellWidth * 1.5;
    final lane2Offset = cellWidth * 5.5;

    // 1. Spawner de Ondas Inimigas para os 4 Jogadores Aliados
    // J1 (Top-Left): Zona de spawn no topo (y < -800), move-se para BAIXO (0, 1)
    _spawnerTL.update(
      dt: dt,
      lane1X: _sectorAllyTL.position.x + lane1Offset,
      lane2X: _sectorAllyTL.position.x + lane2Offset,
      startY: _sectorAllyTL.position.y - 14,
      direction: Vector2(0, 1),
      onSpawnPacket: (packet) {
        packet.assignedQuadrant = BoardQuadrant.topLeft;
        packet.teamId = 'team_blue';
        _attachPacketCallbacks(packet);
        world.add(packet);
      },
      onWaveCompleted: (completedWave) {
        viewModel.onWaveVictory(completedWave);
      },
    );

    // J2 (Bottom-Left): Zona de spawn na região inferior após a grade (bottom), move-se para CIMA (0, -1)
    _spawnerBL.update(
      dt: dt,
      lane1X: _sectorAllyBL.position.x + lane1Offset,
      lane2X: _sectorAllyBL.position.x + lane2Offset,
      startY: _sectorAllyBL.position.y + _sectorAllyBL.size.y + 14,
      direction: Vector2(0, -1),
      onSpawnPacket: (packet) {
        packet.assignedQuadrant = BoardQuadrant.bottomLeft;
        packet.teamId = 'team_blue';
        _attachPacketCallbacks(packet);
        world.add(packet);
      },
      onWaveCompleted: (_) {},
    );

    // J3 (Top-Right): Zona como o player 1 no topo, move-se para BAIXO (0, 1)
    _spawnerTR.update(
      dt: dt,
      lane1X: _sectorAllyTR.position.x + lane1Offset,
      lane2X: _sectorAllyTR.position.x + lane2Offset,
      startY: _sectorAllyTR.position.y - 14,
      direction: Vector2(0, 1),
      onSpawnPacket: (packet) {
        packet.assignedQuadrant = BoardQuadrant.topRight;
        packet.teamId = 'team_blue';
        _attachPacketCallbacks(packet);
        world.add(packet);
      },
      onWaveCompleted: (_) {},
    );

    // J4 (Bottom-Right): Zona como o player 2 na região inferior (bottom), move-se para CIMA (0, -1)
    _spawnerBR.update(
      dt: dt,
      lane1X: _sectorAllyBR.position.x + lane1Offset,
      lane2X: _sectorAllyBR.position.x + lane2Offset,
      startY: _sectorAllyBR.position.y + _sectorAllyBR.size.y + 14,
      direction: Vector2(0, -1),
      onSpawnPacket: (packet) {
        packet.assignedQuadrant = BoardQuadrant.bottomRight;
        packet.teamId = 'team_blue';
        _attachPacketCallbacks(packet);
        world.add(packet);
      },
      onWaveCompleted: (_) {},
    );

    // 2. Trajetória de Leaks: Malwares que ultrapassam o grid avançam pelo meio até o Mainframe (Movimento em L)
    _updateLeakedPackets();

    // 3. Loop de Combate dos Bastiões Aliados (em todos os setores)
    _updateBastionCombat(dt);

    // 4. Colisão Frontal entre Pacotes
    _updatePacketCollisions();
  }

  BoardQuadrantSectorComponent _getSectorForQuadrant(BoardQuadrant quadrant, {bool isBlue = true}) {
    if (isBlue) {
      switch (quadrant) {
        case BoardQuadrant.topLeft:
          return _sectorAllyTL;
        case BoardQuadrant.bottomLeft:
          return _sectorAllyBL;
        case BoardQuadrant.topRight:
          return _sectorAllyTR;
        case BoardQuadrant.bottomRight:
          return _sectorAllyBR;
      }
    } else {
      switch (quadrant) {
        case BoardQuadrant.topLeft:
          return _sectorRivalTL;
        case BoardQuadrant.bottomLeft:
          return _sectorRivalBL;
        case BoardQuadrant.topRight:
          return _sectorRivalTR;
        case BoardQuadrant.bottomRight:
          return _sectorRivalBR;
      }
    }
  }

  /// Ponto de interseção entre a rota de fuga do jogador e o jogador adjacente na direção do Mainframe
  Vector2 getIntersectionWithPlayer(BoardQuadrant playerQuad, BoardQuadrant adjacentQuad, {bool isBlue = true}) {
    if (isBlue) {
      // Jogadores da coluna esquerda (J1 e J2) convergem para a interseção (-590, 0)
      if ((playerQuad == BoardQuadrant.topLeft && adjacentQuad == BoardQuadrant.bottomLeft) ||
          (playerQuad == BoardQuadrant.bottomLeft && adjacentQuad == BoardQuadrant.topLeft)) {
        return Vector2(-590, 0);
      }
      // Jogadores da coluna direita (J3 e J4) convergem para a interseção (-290, 0)
      else if ((playerQuad == BoardQuadrant.topRight && adjacentQuad == BoardQuadrant.bottomRight) ||
               (playerQuad == BoardQuadrant.bottomRight && adjacentQuad == BoardQuadrant.topRight)) {
        return Vector2(-290, 0);
      } else {
        return Vector2(-440, 0);
      }
    } else {
      if ((playerQuad == BoardQuadrant.topLeft && adjacentQuad == BoardQuadrant.bottomLeft) ||
          (playerQuad == BoardQuadrant.bottomLeft && adjacentQuad == BoardQuadrant.topLeft)) {
        return Vector2(1090, 0);
      } else if ((playerQuad == BoardQuadrant.topRight && adjacentQuad == BoardQuadrant.bottomRight) ||
                 (playerQuad == BoardQuadrant.bottomRight && adjacentQuad == BoardQuadrant.topRight)) {
        return Vector2(1390, 0);
      } else {
        return Vector2(1240, 0);
      }
    }
  }

  void _updateLeakedPackets() {
    final mainframePos = _blueMainframe.position;

    final redPackets = world.children
        .whereType<DataPacketComponent>()
        .where((p) => p.origin == PacketOrigin.redExploit && !p.isDead)
        .toList();

    for (final packet in redPackets) {
      packet.assignedQuadrant ??= _resolveQuadrantForPosition(packet.position);
      final quad = packet.assignedQuadrant!;
      final sector = _getSectorForQuadrant(quad, isBlue: true);
      final isTopSector = quad == BoardQuadrant.topLeft || quad == BoardQuadrant.topRight;

      // Limite de saída do quadrante do jogador
      final zoneExitY = isTopSector ? (sector.position.y + sector.size.y) : sector.position.y;
      final bool isOutPlayerZone = isTopSector
          ? packet.position.y >= zoneExitY
          : packet.position.y <= zoneExitY;

      // leak = hp > 0 && isOutPlayerZone
      final isLeak = GameRuleEngine.isUnitLeak(
        currentHealth: packet.currentHealth,
        isOutPlayerZone: isOutPlayerZone,
      );

      // PASSO 1: Unidade saiu da zona -> inicia leak e move-se pela linha tracejada até a parada (y = 0.0)
      if (isLeak && packet.movementState == PacketMovementState.inPlayerLane) {
        packet.isLeaked = true;
        totalLeaks++;
        viewModel.recordLeak(teamId: 'team_blue', quadrant: quad);

        final middlePoint = Vector2(packet.basePosition.x, 0.0);
        packet.startLeakToMiddle(middlePoint);
        packet.direction = isTopSector ? Vector2(0, 1) : Vector2(0, -1);
      }

      // PASSO 2: Movendo-se pela linha tracejada até a parada (the middle between them em y = 0.0)
      if (packet.movementState == PacketMovementState.headingToMiddle ||
          packet.movementState == PacketMovementState.headingToIntersection) {
        // Trava a direção estritamente vertical ao longo da linha tracejada da coluna
        packet.direction = isTopSector ? Vector2(0, 1) : Vector2(0, -1);

        // Verifica se alcançou a parada intermediária (y = 0.0)
        final bool hasReachedParada = isTopSector
            ? packet.basePosition.y >= 0.0
            : packet.basePosition.y <= 0.0;

        if (hasReachedParada) {
          // Trava exatamente na parada (y = 0.0) e inicia rota ao Mainframe
          packet.basePosition.y = 0.0;
          packet.turnToMainframe(mainframePos);
        }
      }
      // PASSO 3: Após chegar na parada -> move para o Mainframe ao longo da linha horizontal (y = 0.0)
      else if (packet.movementState == PacketMovementState.headingToMainframe) {
        // Trava no eixo y da espinha dorsal do barramento (y = 0.0) mantendo a oscilação vertical
        packet.basePosition.y = mainframePos.y;

        final distToMainframe = packet.position.distanceTo(mainframePos);

        // Ao chegar a cerca de 100px de distância do mainframe, para e ataca
        if (distToMainframe <= 100.0) {
          packet.stopAndAttackMainframe(mainframePos);
          packet.onAttackMainframe = (p) {
            if (p.isDead) return;
            viewModel.onMainframeDamaged('team_blue', p.damage * 0.4);
            world.add(
              LaserBeamEffect(
                start: p.position.clone(),
                end: mainframePos.clone(),
                beamColor: AppColors.redTeam,
                duration: 0.16,
              ),
            );
          };
        } else {
          // Movimento horizontal estrito em direção ao Mainframe (-440, 0)
          final toMainframeX = mainframePos.x - packet.basePosition.x;
          packet.direction = Vector2(toMainframeX > 0 ? 1.0 : -1.0, 0.0);
        }
      }
      // PASSO 4: Parado a ~100px atacando o Mainframe
      else if (packet.movementState == PacketMovementState.attackingMainframe) {
        packet.speed = 0.0;
        final diff = mainframePos - packet.position;
        if (diff.length > 0) {
          packet.direction = diff.normalized();
        }
      }

      // REDE DE SEGURANÇA (Anti-Bug "passando direto"):
      // Nenhuma unidade que alcançou ou ultrapassou a parada (y = 0.0) pode continuar se movendo verticalmente
      if (!packet.isDead && packet.movementState != PacketMovementState.attackingMainframe) {
        if (isTopSector && packet.basePosition.y >= 0.0 && packet.movementState != PacketMovementState.headingToMainframe) {
          packet.basePosition.y = 0.0;
          packet.turnToMainframe(mainframePos);
        } else if (!isTopSector && packet.basePosition.y <= 0.0 && packet.movementState != PacketMovementState.headingToMainframe) {
          packet.basePosition.y = 0.0;
          packet.turnToMainframe(mainframePos);
        }
      }
    }
  }

  BoardQuadrant _resolveQuadrantForPosition(Vector2 pos) {
    if (pos.x < -500) {
      return pos.y < 0 ? BoardQuadrant.topLeft : BoardQuadrant.bottomLeft;
    } else {
      return pos.y < 0 ? BoardQuadrant.topRight : BoardQuadrant.bottomRight;
    }
  }

  void _updateBastionCombat(double dt) {
    final cellWidth = _sectorAllyTL.size.x / BoardQuadrantSectorComponent.columns;
    final cellHeight = _sectorAllyTL.size.y / BoardQuadrantSectorComponent.rows;

    final activeEnemyPackets = world.children
        .whereType<DataPacketComponent>()
        .where((p) => p.origin == PacketOrigin.redExploit && !p.isDead)
        .toList();

    if (activeEnemyPackets.isEmpty) return;

    final state = viewModel.state.value;
    final players = state.allyPlayers.isNotEmpty ? state.allyPlayers : TeamPlayerModel.initialBlueTeam();

    // Reúne todos os nós de cada quadrante com a posição do respectivo setor
    final playerSectors = [
      (player: players[0], sector: _sectorAllyTL, nodes: viewModel.getQuadrantNodes(BoardQuadrant.topLeft)),
      if (players.length > 1) (player: players[1], sector: _sectorAllyBL, nodes: viewModel.getQuadrantNodes(BoardQuadrant.bottomLeft)),
      if (players.length > 2) (player: players[2], sector: _sectorAllyTR, nodes: viewModel.getQuadrantNodes(BoardQuadrant.topRight)),
      if (players.length > 3) (player: players[3], sector: _sectorAllyBR, nodes: viewModel.getQuadrantNodes(BoardQuadrant.bottomRight)),
    ];

    for (final ps in playerSectors) {
      for (final node in ps.nodes.values) {
        _nodeAttackTimers[node.id] = (_nodeAttackTimers[node.id] ?? 0.0) + dt;

        final cadence = node.type == BastionNodeType.proxy
            ? 0.5
            : (node.type == BastionNodeType.ids ? 0.85 : 0.7);

        if (_nodeAttackTimers[node.id]! < cadence) continue;

        final nodeCenterX = ps.sector.position.x + (node.gridX * cellWidth) + (cellWidth / 2);
        final nodeCenterY = ps.sector.position.y + (node.gridY * cellHeight) + (cellHeight / 2);
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

          final boostedDamage = node.attackDamage * state.damageMultiplier;
          closestTarget.takeDamage(boostedDamage);
          _nodeAttackTimers[node.id] = 0.0;
        }
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
        // Apenas pacotes de lados/origens opostas colidem (ex: Blue Defense vs Red Exploit)
        // Pacotes da mesma equipe (ex: dois Red Exploits de J1 e J2) não colidem nem se destroem
        if (up.origin != down.origin && up.position.distanceTo(down.position) < 20.0) {
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
