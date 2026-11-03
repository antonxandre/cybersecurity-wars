import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/team_player_model.dart';
import 'package:promptsec_arena_front/game/components/data_packet_component.dart';

void main() {
  group('Sinuous Movement (Movimentação Sinuosa) Tests', () {
    test('Red Exploit packets have isSinuous true by default with calibrated parameters', () {
      final portScanner = DataPacketComponent(
        startPosition: Vector2(100, 200),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(0, 1),
      );
      expect(portScanner.isSinuous, isTrue);
      expect(portScanner.sinuousAmplitude, equals(14.0));
      expect(portScanner.sinuousFrequency, equals(4.5));

      final synFlood = DataPacketComponent(
        startPosition: Vector2(100, 200),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.synFlood,
        direction: Vector2(0, 1),
      );
      expect(synFlood.isSinuous, isTrue);
      expect(synFlood.sinuousAmplitude, equals(10.0));
      expect(synFlood.sinuousFrequency, equals(8.5));

      final zeroDay = DataPacketComponent(
        startPosition: Vector2(100, 200),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.zeroDayPayload,
        direction: Vector2(0, 1),
      );
      expect(zeroDay.isSinuous, isTrue);
      expect(zeroDay.sinuousAmplitude, equals(22.0));
      expect(zeroDay.sinuousFrequency, equals(2.5));
    });

    test('Blue Defense and Client Traffic have isSinuous false by default', () {
      final bluePacket = DataPacketComponent(
        startPosition: Vector2(100, 200),
        origin: PacketOrigin.blueDefense,
        subtype: PacketSubtype.bluePayload,
        direction: Vector2(0, -1),
      );
      expect(bluePacket.isSinuous, isFalse);

      final clientPacket = DataPacketComponent(
        startPosition: Vector2(100, 200),
        origin: PacketOrigin.clientTraffic,
        subtype: PacketSubtype.clientHttps,
        direction: Vector2(0, 1),
      );
      expect(clientPacket.isSinuous, isFalse);
    });

    test('Vertical downward movement: Y progresses linearly, X oscillates perpendicularly', () {
      const startX = 330.0;
      const startY = -400.0;
      const speed = 100.0;
      const amplitude = 15.0;
      const frequency = 2.0;

      final packet = DataPacketComponent(
        startPosition: Vector2(startX, startY),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(0, 1),
        speed: speed,
        sinuousAmplitude: amplitude,
        sinuousFrequency: frequency,
        sinuousPhase: 0.0, // Inicia em sin(0) = 0
      );

      expect(packet.position.x, equals(startX));
      expect(packet.position.y, equals(startY));
      expect(packet.basePosition.x, equals(startX));
      expect(packet.basePosition.y, equals(startY));

      // 1. Simula 1/4 de ciclo (t = pi / (2 * omega)) -> sin(pi/2) = 1.0 (pico máximo positivo)
      const quarterPeriod = math.pi / (2 * frequency); // pi / 4 ~ 0.785398s
      packet.update(quarterPeriod);

      // Y avança linearmente: startY + speed * t
      const expectedY = startY + (speed * quarterPeriod);
      expect(packet.basePosition.y, closeTo(expectedY, 0.001));
      expect(packet.position.y, closeTo(expectedY, 0.001));

      // Normal para direction (0, 1) é (-1, 0)
      // position.x = baseX + normal.x * amplitude * sin(pi/2) = 330 - 15.0 = 315.0
      expect(packet.basePosition.x, equals(startX));
      expect(packet.position.x, closeTo(startX - amplitude, 0.05));

      // 2. Simula mais 1/4 de ciclo para t = pi / omega -> sin(pi) = 0.0 (cruzamento pelo centro da pista)
      packet.update(quarterPeriod);
      const halfPeriod = quarterPeriod * 2;
      expect(packet.basePosition.y, closeTo(startY + (speed * halfPeriod), 0.001));
      expect(packet.position.y, closeTo(startY + (speed * halfPeriod), 0.001));
      expect(packet.position.x, closeTo(startX, 0.05));

      // 3. Simula mais 1/4 de ciclo para t = 3*pi / (2 * omega) -> sin(3pi/2) = -1.0 (pico oposto)
      packet.update(quarterPeriod);
      const threeQuarterPeriod = quarterPeriod * 3;
      expect(packet.basePosition.y, closeTo(startY + (speed * threeQuarterPeriod), 0.001));
      expect(packet.position.y, closeTo(startY + (speed * threeQuarterPeriod), 0.001));
      // normal.x * -amplitude = -1 * -15 = +15 -> 330 + 15 = 345.0
      expect(packet.position.x, closeTo(startX + amplitude, 0.05));
    });

    test('Horizontal movement towards Mainframe: X progresses linearly, Y oscillates vertically', () {
      const startX = -800.0;
      const startY = 0.0;
      const speed = 100.0;
      const amplitude = 12.0;
      const frequency = 4.0;

      final packet = DataPacketComponent(
        startPosition: Vector2(startX, startY),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(1, 0), // Movimento horizontal para a direita em direção ao Mainframe (-440, 0)
        speed: speed,
        sinuousAmplitude: amplitude,
        sinuousFrequency: frequency,
        sinuousPhase: 0.0,
      );

      // Simula 1/4 de ciclo
      const quarterPeriod = math.pi / (2 * frequency);
      packet.update(quarterPeriod);

      // X avança linearmente
      expect(packet.basePosition.x, closeTo(startX + (speed * quarterPeriod), 0.001));
      expect(packet.position.x, closeTo(startX + (speed * quarterPeriod), 0.001));

      // Normal para direction (1, 0) é (0, 1) -> oscilação vertical no eixo Y!
      // position.y = baseY + normal.y * amplitude * 1.0 = 0.0 + 12.0 = 12.0
      expect(packet.basePosition.y, equals(startY));
      expect(packet.position.y, closeTo(startY + amplitude, 0.05));
    });

    test('L-movement transition from lane to Mainframe rotates oscillation axis seamlessly', () {
      final packet = DataPacketComponent(
        startPosition: Vector2(-770, -320),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(0, 1),
        speed: 130.0,
        assignedQuadrant: BoardQuadrant.topLeft,
        sinuousAmplitude: 14.0,
      );

      // Fase 1: Quadrante -> descendo verticalmente
      packet.update(0.1);
      expect(packet.direction, equals(Vector2(0, 1)));

      // Fase 2: Leak para a parada intermediária (y = 0.0)
      final middlePoint = Vector2(packet.basePosition.x, 0.0);
      packet.startLeakToMiddle(middlePoint);
      expect(packet.movementState, equals(PacketMovementState.headingToMiddle));
      expect(packet.basePosition.x, equals(middlePoint.x));

      // Fase 3: Ao chegar na parada (y = 0.0), vira em direção ao Mainframe (-440, 0.0)
      final mainframePos = Vector2(-440, 0.0);
      packet.turnToMainframe(mainframePos);

      expect(packet.movementState, equals(PacketMovementState.headingToMainframe));
      expect(packet.basePosition.y, equals(0.0));
      expect(packet.position.y, equals(0.0));
      // Direção horizontal: vira para a direita (x > -770)
      expect(packet.direction.x, equals(1.0));
      expect(packet.direction.y, equals(0.0));

      // Fase 4: Avança em direção ao Mainframe e oscila verticalmente em Y
      packet.update(0.15);
      expect(packet.basePosition.y, equals(0.0));
      expect(packet.basePosition.x, greaterThan(-770));
    });

    test('Stop and attack mainframe halts speed, stabilizes position and resets trail', () {
      final packet = DataPacketComponent(
        startPosition: Vector2(-540, 0),
        origin: PacketOrigin.redExploit,
        subtype: PacketSubtype.portScanner,
        direction: Vector2(1, 0),
        speed: 130.0,
      );

      final mainframePos = Vector2(-440, 0);
      packet.stopAndAttackMainframe(mainframePos);

      expect(packet.speed, equals(0.0));
      expect(packet.movementState, equals(PacketMovementState.attackingMainframe));

      final frozenPos = packet.position.clone();
      packet.update(0.5);
      expect(packet.position, equals(frozenPos));
    });
  });
}
