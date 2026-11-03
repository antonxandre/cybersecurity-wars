import 'dart:math' as math;
import 'package:flame/components.dart';

enum TransitZoneDirection { toRight, toLeft }

/// Componente visual que demarca a Área Intermediária (The Middle) entre dois jogadores
/// adjacentes (ex: Jogador 1 e Jogador 2, ou Jogador 3 e Jogador 4), servindo como zona
/// de transição de Waypoint onde os malwares que sofreram leak realizam o movimento em L
/// em direção ao Mainframe Central.
class MiddleTransitZoneComponent extends PositionComponent {
  final String label;
  final TransitZoneDirection arrowDirection;
  final bool isBlueTeam;

  double _pulseTimer = 0.0;

  MiddleTransitZoneComponent({
    required Vector2 position,
    required Vector2 size,
    this.label = '',
    required this.arrowDirection,
    this.isBlueTeam = true,
  }) : super(position: position, size: size, priority: -2);

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer = (_pulseTimer + dt * 2.8) % (math.pi * 2);
  }
}
