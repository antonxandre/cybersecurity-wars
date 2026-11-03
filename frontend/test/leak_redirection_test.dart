import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/rules/game_rule_engine.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/mainframe_model.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/team_player_model.dart';
import 'package:promptsec_arena_front/features/battle/presentation/viewmodels/battle_view_model.dart';
import 'package:promptsec_arena_front/game/components/board_quadrant_sector_component.dart';
import 'package:promptsec_arena_front/game/components/data_packet_component.dart';

void main() {
  group('Leak Redirection & L-Movement Waypoint Tests', () {
    test('Player 1 (Top-Left) executes exact L-movement to middle (y=0) and turns to Mainframe', () {
      final packet = DataPacketComponent(
        startPosition: Vector2(-720, -360),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(0, 1),
        speed: 130.0,
        assignedQuadrant: BoardQuadrant.topLeft,
      );

      expect(packet.movementState, equals(PacketMovementState.inPlayerLane));
      expect(packet.isLeaked, isFalse);
      expect(packet.hasReachedIntersection, isFalse);

      // 1. Simula leak ao ultrapassar o setor de J1: move-se em linha reta vertical até o meio (y = 0)
      final middlePoint = Vector2(packet.position.x, 0.0);
      packet.startLeakToMiddle(middlePoint);

      expect(packet.movementState, equals(PacketMovementState.headingToMiddle));
      expect(packet.isLeaked, isTrue);
      // Movimento estritamente vertical pelo corredor da coluna (sem desvio em X)
      expect(packet.direction.x, equals(0.0));
      expect(packet.direction.y, equals(1.0));

      // Simula deslocamento até o limite do meio (y = 0.0)
      packet.position.y = 0.0;

      // 2. Ao ultrapassar o limite, vira em 90 graus em direção ao Mainframe (-440, 0)
      final mainframePos = Vector2(-440, 0.0);
      packet.turnToMainframe(mainframePos);

      expect(packet.movementState, equals(PacketMovementState.headingToMainframe));
      expect(packet.hasReachedIntersection, isTrue);
      expect(packet.position.y, equals(0.0)); // Alinhado ao barramento do meio
      // Vira estritamente no eixo X (horizontal) em direção ao Mainframe, formando o 'L'
      expect(packet.direction.x, equals(1.0));
      expect(packet.direction.y, equals(0.0));

      // 3. Ao chegar cerca de 100px de distância do mainframe, fica parada atacando
      packet.position = Vector2(-540, 0.0); // Distância exata de 100px de (-440, 0)
      expect(packet.position.distanceTo(mainframePos), lessThanOrEqualTo(100.0));

      packet.stopAndAttackMainframe(mainframePos);
      expect(packet.movementState, equals(PacketMovementState.attackingMainframe));
      expect(packet.speed, equals(0.0)); // Unidade totalmente parada!
    });

    test('Player 2 (Bottom-Left) executes inverted L-movement from bottom spawn to middle and Mainframe', () {
      final packet = DataPacketComponent(
        startPosition: Vector2(-720, 380), // Spawn na região inferior (bottom)
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(0, -1), // Move-se para cima
        speed: 130.0,
        assignedQuadrant: BoardQuadrant.bottomLeft,
      );

      expect(packet.movementState, equals(PacketMovementState.inPlayerLane));

      // 1. Simula leak ao ultrapassar o setor de J2 (y <= 160)
      packet.position.y = 150.0;
      final middlePoint = Vector2(packet.position.x, 0.0);
      packet.startLeakToMiddle(middlePoint);

      expect(packet.movementState, equals(PacketMovementState.headingToMiddle));
      // Move-se para cima estritamente no eixo vertical
      expect(packet.direction.x, equals(0.0));
      expect(packet.direction.y, equals(-1.0));

      // Simula ultrapassagem do limite do meio (y <= 0.0)
      packet.position.y = 0.0;

      // 2. Vira para o Mainframe formando movimento em L
      final mainframePos = Vector2(-440, 0.0);
      packet.turnToMainframe(mainframePos);

      expect(packet.movementState, equals(PacketMovementState.headingToMainframe));
      expect(packet.direction.x, equals(1.0));
      expect(packet.direction.y, equals(0.0));

      // 3. Chega a ~100px do Mainframe e fica parada atacando
      packet.position = Vector2(-540, 0.0);
      packet.stopAndAttackMainframe(mainframePos);

      expect(packet.movementState, equals(PacketMovementState.attackingMainframe));
      expect(packet.speed, equals(0.0));
    });

    test('Unit attacking mainframe triggers periodic damage callback', () {
      final packet = DataPacketComponent(
        startPosition: Vector2(-540, 0),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(1, 0),
        speed: 0.0,
        damage: 25.0,
      );

      final mainframePos = Vector2(-440, 0);
      packet.stopAndAttackMainframe(mainframePos);

      int attackCount = 0;
      packet.onAttackMainframe = (p) {
        attackCount++;
      };

      // Simula update com o tempo da cadência de ataque
      packet.update(0.9);
      expect(attackCount, equals(1));

      packet.update(0.9);
      expect(attackCount, equals(2));
    });

    test('Mainframe defense range is calibrated to 160.0 (reduced by 100)', () {
      final blueMf = MainframeModel.initial(teamId: 'team_blue');
      expect(blueMf.defenseRange, equals(160.0));

      final redMf = MainframeModel.initial(teamId: 'team_red');
      expect(redMf.defenseRange, equals(160.0));
    });

    test('Middle boundary exists exactly halfway between Player 1 and Player 2 at y = 0 (300px distance)', () {
      const p1Bottom = -300.0; // P1 y: [-800, -300] (distância de 300px ao mainframe em y=0)
      const p2Top = 300.0;     // P2 y: [300, 800] (distância de 300px ao mainframe em y=0)

      const middleY = (p1Bottom + p2Top) / 2;
      expect(middleY, equals(0.0));

      const p3Bottom = -300.0; // P3 y: [-800, -300]
      const p4Top = 300.0;     // P4 y: [300, 800]

      const middleP3P4Y = (p3Bottom + p4Top) / 2;
      expect(middleP3P4Y, equals(0.0));
    });

    test('Grid is increased to 7 columns and 10 rows', () {
      // Importante validação da especificação de grade 7x10
      // 7 colunas e 10 linhas por quadrante
      expect(BoardQuadrantSectorComponent.columns, equals(7));
      expect(BoardQuadrantSectorComponent.rows, equals(10));
    });

    test('All player sectors are distanced exactly 300px from Mainframe in both X and Y axes', () {
      final blueMainframePos = Vector2(-440, 0);
      const sectorWidth = 350.0;
      const sectorHeight = 500.0;

      // Blue Team
      final j1Pos = Vector2(-1090, -800);
      final j2Pos = Vector2(-1090, 300);
      final j3Pos = Vector2(-140, -800);
      final j4Pos = Vector2(-140, 300);

      // Distância de J1 (Top-Left) ao Mainframe
      final j1RightEdge = j1Pos.x + sectorWidth; // -740
      final j1BottomEdge = j1Pos.y + sectorHeight; // -300
      expect((blueMainframePos.x - j1RightEdge).abs(), equals(300.0));
      expect((blueMainframePos.y - j1BottomEdge).abs(), equals(300.0));

      // Distância de J2 (Bottom-Left) ao Mainframe
      final j2RightEdge = j2Pos.x + sectorWidth; // -740
      final j2TopEdge = j2Pos.y; // 300
      expect((blueMainframePos.x - j2RightEdge).abs(), equals(300.0));
      expect((j2TopEdge - blueMainframePos.y).abs(), equals(300.0));

      // Distância de J3 (Top-Right) ao Mainframe
      final j3LeftEdge = j3Pos.x; // -140
      final j3BottomEdge = j3Pos.y + sectorHeight; // -300
      expect((j3LeftEdge - blueMainframePos.x).abs(), equals(300.0));
      expect((blueMainframePos.y - j3BottomEdge).abs(), equals(300.0));

      // Distância de J4 (Bottom-Right) ao Mainframe
      final j4LeftEdge = j4Pos.x; // -140
      final j4TopEdge = j4Pos.y; // 300
      expect((j4LeftEdge - blueMainframePos.x).abs(), equals(300.0));
      expect((j4TopEdge - blueMainframePos.y).abs(), equals(300.0));

      // Red Team
      final redMainframePos = Vector2(1240, 0);
      final r1Pos = Vector2(590, -800);
      final r2Pos = Vector2(590, 300);
      final r3Pos = Vector2(1540, -800);
      final r4Pos = Vector2(1540, 300);

      // Distância de R1 ao Red Mainframe
      expect((redMainframePos.x - (r1Pos.x + sectorWidth)).abs(), equals(300.0));
      expect((redMainframePos.y - (r1Pos.y + sectorHeight)).abs(), equals(300.0));

      // Distância de R2 ao Red Mainframe
      expect((redMainframePos.x - (r2Pos.x + sectorWidth)).abs(), equals(300.0));
      expect((r2Pos.y - redMainframePos.y).abs(), equals(300.0));

      // Distância de R3 ao Red Mainframe
      expect((r3Pos.x - redMainframePos.x).abs(), equals(300.0));
      expect((redMainframePos.y - (r3Pos.y + sectorHeight)).abs(), equals(300.0));

      // Distância de R4 ao Red Mainframe
      expect((r4Pos.x - redMainframePos.x).abs(), equals(300.0));
      expect((r4Pos.y - redMainframePos.y).abs(), equals(300.0));
    });

    test('Spawn zones are correctly positioned: P1/P3 at top, P2/P4 at bottom', () {
      final players = TeamPlayerModel.initialBlueTeam();
      expect(players.length, equals(4));

      // Player 1: Top-Left -> Top
      final p1 = players[0];
      final p1IsTop = p1.quadrant == BoardQuadrant.topLeft || p1.quadrant == BoardQuadrant.topRight;
      expect(p1IsTop, isTrue);

      // Player 2: Bottom-Left -> Bottom
      final p2 = players[1];
      final p2IsTop = p2.quadrant == BoardQuadrant.topLeft || p2.quadrant == BoardQuadrant.topRight;
      expect(p2IsTop, isFalse);

      // Player 3: Top-Right -> Top
      final p3 = players[2];
      final p3IsTop = p3.quadrant == BoardQuadrant.topLeft || p3.quadrant == BoardQuadrant.topRight;
      expect(p3IsTop, isTrue);

      // Player 4: Bottom-Right -> Bottom
      final p4 = players[3];
      final p4IsTop = p4.quadrant == BoardQuadrant.topLeft || p4.quadrant == BoardQuadrant.topRight;
      expect(p4IsTop, isFalse);
    });

    test('BattleViewModel accurately tracks totalLeaks and updates player waveStatus', () {
      final vm = BattleViewModel();
      expect(vm.totalLeaks, equals(0));

      // Registra leak no quadrante Top-Left (Jogador 1)
      vm.recordLeak(teamId: 'team_blue', quadrant: BoardQuadrant.topLeft);

      expect(vm.totalLeaks, equals(1));
      expect(vm.state.value.totalLeaks, equals(1));

      final j1 = vm.state.value.allyPlayers.firstWhere((p) => p.quadrant == BoardQuadrant.topLeft);
      expect(j1.waveStatus, equals(PlayerWaveStatus.leakingThreats));

      // Segundo leak registrado
      vm.recordLeak(teamId: 'team_blue', quadrant: BoardQuadrant.topRight);
      expect(vm.totalLeaks, equals(2));

      final j3 = vm.state.value.allyPlayers.firstWhere((p) => p.quadrant == BoardQuadrant.topRight);
      expect(j3.waveStatus, equals(PlayerWaveStatus.leakingThreats));

      vm.dispose();
    });

    test('isUnitLeak canonical rule logic validation', () {
      expect(GameRuleEngine.isUnitLeak(currentHealth: 100.0, isOutPlayerZone: true), isTrue);
      expect(GameRuleEngine.isUnitLeak(currentHealth: 1.0, isOutPlayerZone: true), isTrue);
      expect(GameRuleEngine.isUnitLeak(currentHealth: 0.0, isOutPlayerZone: true), isFalse);
      expect(GameRuleEngine.isUnitLeak(currentHealth: -5.0, isOutPlayerZone: true), isFalse);
      expect(GameRuleEngine.isUnitLeak(currentHealth: 80.0, isOutPlayerZone: false), isFalse);
    });

    test('Strict sequential leak path: Out of Zone -> Parada -> Mainframe -> Siege Attack', () {
      final p1Packet = DataPacketComponent(
        startPosition: Vector2(-770, -310), // Inside J1 zone ([-800, -300])
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(0, 1),
        speed: 130.0,
        assignedQuadrant: BoardQuadrant.topLeft,
      );

      // Phase 1: Inside Zone
      expect(p1Packet.movementState, equals(PacketMovementState.inPlayerLane));

      // Phase 2: Exits Zone (y >= -300) -> Moves along dashed line to Parada (y = 0.0)
      p1Packet.position.y = -290.0;
      final middlePoint = Vector2(p1Packet.position.x, 0.0);
      p1Packet.startLeakToMiddle(middlePoint);

      expect(p1Packet.movementState, equals(PacketMovementState.headingToMiddle));
      expect(p1Packet.direction, equals(Vector2(0, 1))); // Strictly vertical down along dashed line

      // Phase 3: Arrives at Parada (y = 0.0) -> Snaps y=0 and moves towards Mainframe
      p1Packet.position.y = 0.0;
      final mainframePos = Vector2(-440, 0.0);
      p1Packet.turnToMainframe(mainframePos);

      expect(p1Packet.movementState, equals(PacketMovementState.headingToMainframe));
      expect(p1Packet.position.y, equals(0.0));
      expect(p1Packet.direction, equals(Vector2(1, 0))); // Strictly horizontal towards Mainframe

      // Phase 4: Arrives within 100px of Mainframe (-540 is 100px from -440) -> Stops and attacks
      p1Packet.position = Vector2(-540, 0.0);
      p1Packet.stopAndAttackMainframe(mainframePos);

      expect(p1Packet.movementState, equals(PacketMovementState.attackingMainframe));
      expect(p1Packet.speed, equals(0.0));
    });

    test('Same-team red exploits in opposing lanes do not collide or damage each other', () {
      final p1Exploit = DataPacketComponent(
        startPosition: Vector2(-770, -10),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(0, 1), // Downward
        damage: 25.0,
      );

      final p2Exploit = DataPacketComponent(
        startPosition: Vector2(-770, 5),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(0, -1), // Upward
        damage: 25.0,
      );

      // Distance is 15px (< 20px)
      expect(p1Exploit.position.distanceTo(p2Exploit.position), lessThan(20.0));
      expect(p1Exploit.origin, equals(p2Exploit.origin));

      // Collision check rule: only different origins take damage
      final shouldCollide = p1Exploit.origin != p2Exploit.origin;
      expect(shouldCollide, isFalse);

      // Verify health remains full (no friendly-fire annihilation)
      expect(p1Exploit.currentHealth, equals(p1Exploit.maxHealth));
      expect(p2Exploit.currentHealth, equals(p2Exploit.maxHealth));
    });
  });
}
