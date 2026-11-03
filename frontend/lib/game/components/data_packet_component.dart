import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../../core/theme/app_colors.dart';
import '../../features/battle/domain/models/team_player_model.dart';

enum PacketOrigin { blueDefense, redExploit, clientTraffic }

enum PacketSubtype { portScanner, synFlood, zeroDayPayload, clientHttps, bluePayload }

/// Estados da trajetória de deslocamento do pacote (rota normal, área intermediária, mainframe ou atacando)
enum PacketMovementState {
  inPlayerLane,          // Deslocando-se dentro do quadrante/rota do jogador
  headingToMiddle,       // Sofreu leak! Movendo-se verticalmente até a área intermediária (y = 0)
  headingToIntersection, // Alias para headingToMiddle
  headingToMainframe,    // Ultrapassou o meio! Movendo-se horizontalmente em direção ao Mainframe (movimento em L)
  attackingMainframe,    // Parado a ~100px atacando o Mainframe
}

/// Componente de Pacote de Dados com HP, dano, tipos e animação de impacto.
class DataPacketComponent extends PositionComponent with TapCallbacks {
  final PacketOrigin origin;
  final PacketSubtype subtype;
  double speed;
  Vector2 direction;
  final double damage;
  final double maxHealth;
  void Function(DataPacketComponent packet)? onReachedEnd;
  void Function(DataPacketComponent packet)? onDestroyed;
  void Function(DataPacketComponent packet)? onAttackMainframe;
  void Function(DataPacketComponent packet)? onTapped;

  // Gerenciamento de Trajetória e Leaks (Legion TD / CyberWars)
  PacketMovementState movementState = PacketMovementState.inPlayerLane;
  bool isLeaked = false;
  bool hasReachedIntersection = false;
  Vector2? targetIntersection;
  Vector2? targetMainframe;
  BoardQuadrant? assignedQuadrant;
  String? teamId;

  // Trajetória vertebral (backbone linear) e movimentação sinuosa
  Vector2? _basePosition;
  Vector2 get basePosition => _basePosition ?? position;
  set basePosition(Vector2 val) {
    _basePosition = val;
  }

  final bool isSinuous;
  final double sinuousAmplitude;
  final double sinuousFrequency;
  final double sinuousPhase;
  double _sinuousTimer = 0.0;

  // Efeito de Rastro Neon Cyberpunk
  final List<Vector2> _trailPositions = [];
  double _trailTimer = 0.0;
  static const int _maxTrailPoints = 4;

  double attackCooldown = 0.0;
  double attackCadence = 0.85;

  double currentHealth;
  double _flashTimer = 0.0;

  late final Paint _packetPaint;
  late final Paint _glowPaint;
  late final Paint _flashPaint;

  DataPacketComponent({
    required Vector2 startPosition,
    required this.origin,
    required this.subtype,
    required this.direction,
    this.speed = 130.0,
    this.damage = 25.0,
    this.maxHealth = 60.0,
    this.assignedQuadrant,
    this.teamId,
    bool? isSinuous,
    double? sinuousAmplitude,
    double? sinuousFrequency,
    double? sinuousPhase,
    this.onReachedEnd,
    this.onDestroyed,
    this.onAttackMainframe,
    this.onTapped,
  })  : currentHealth = maxHealth,
        isSinuous = isSinuous ?? (origin == PacketOrigin.redExploit),
        sinuousAmplitude = sinuousAmplitude ?? _defaultAmplitudeForSubtype(subtype),
        sinuousFrequency = sinuousFrequency ?? _defaultFrequencyForSubtype(subtype),
        sinuousPhase = sinuousPhase ?? (math.Random().nextDouble() * math.pi * 2),
        super(
          position: startPosition.clone(),
          size: subtype == PacketSubtype.zeroDayPayload
              ? Vector2(24, 24)
              : (subtype == PacketSubtype.synFlood ? Vector2(10, 10) : Vector2(14, 14)),
          anchor: Anchor.center,
        ) {
    _basePosition = startPosition.clone();
  }

  @override
  set position(Vector2 val) {
    super.position = val;
    _basePosition?.setFrom(val);
  }

  static double _defaultAmplitudeForSubtype(PacketSubtype subtype) {
    switch (subtype) {
      case PacketSubtype.portScanner:
        return 14.0;
      case PacketSubtype.synFlood:
        return 10.0;
      case PacketSubtype.zeroDayPayload:
        return 22.0;
      case PacketSubtype.clientHttps:
      case PacketSubtype.bluePayload:
        return 12.0;
    }
  }

  static double _defaultFrequencyForSubtype(PacketSubtype subtype) {
    switch (subtype) {
      case PacketSubtype.portScanner:
        return 4.5;
      case PacketSubtype.synFlood:
        return 8.5;
      case PacketSubtype.zeroDayPayload:
        return 2.5;
      case PacketSubtype.clientHttps:
      case PacketSubtype.bluePayload:
        return 4.0;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapped?.call(this);
    event.handled = true;
  }

  bool get isDead => currentHealth <= 0;

  String get subtypeDisplayName {
    switch (subtype) {
      case PacketSubtype.portScanner:
        return 'Port Scanner';
      case PacketSubtype.synFlood:
        return 'SYN Flood Payload';
      case PacketSubtype.zeroDayPayload:
        return 'Zero-Day Exploit';
      case PacketSubtype.clientHttps:
        return 'Tráfego HTTPS';
      case PacketSubtype.bluePayload:
        return 'Payload Defensivo';
    }
  }

  String get movementStateDescription {
    switch (movementState) {
      case PacketMovementState.inPlayerLane:
        return 'Rota de Quadrante';
      case PacketMovementState.headingToMiddle:
      case PacketMovementState.headingToIntersection:
        return 'Zona Intermediária';
      case PacketMovementState.headingToMainframe:
        return 'Em Rota ao Mainframe';
      case PacketMovementState.attackingMainframe:
        return 'Atacando Mainframe';
    }
  }

  /// Inicia o deslocamento de leak em linha reta vertical até a área intermediária (y = 0)
  void startLeakToMiddle(Vector2 middlePoint) {
    movementState = PacketMovementState.headingToMiddle;
    targetIntersection = middlePoint;
    isLeaked = true;
    final isTopSector = assignedQuadrant != null
        ? (assignedQuadrant == BoardQuadrant.topLeft ||
            assignedQuadrant == BoardQuadrant.topRight)
        : (position.y < 0.0);
    // Movimento estritamente vertical pelo corredor da coluna (sem desvio horizontal)
    direction = isTopSector ? Vector2(0, 1) : Vector2(0, -1);
    speed = 130.0;
    // Sincroniza a posição base para o centro da pista
    basePosition.x = middlePoint.x;
    basePosition.y = position.y;
  }

  /// Alias de compatibilidade
  void gotoIntersectionWithPlayer(Vector2 intersectionPoint) {
    startLeakToMiddle(intersectionPoint);
  }

  /// Após ultrapassar o meio entre os jogadores, vira em direção ao Mainframe (movimento em L)
  void turnToMainframe(Vector2 mainframePosition) {
    movementState = PacketMovementState.headingToMainframe;
    hasReachedIntersection = true;
    targetMainframe = mainframePosition;
    // Alinha no eixo Y da rota intermediária ao Mainframe
    basePosition.y = mainframePosition.y;
    position.y = mainframePosition.y;
    // Vira 90 graus estritamente no eixo horizontal em direção ao Mainframe (movimento em L)
    final toMainframeX = mainframePosition.x - basePosition.x;
    direction = Vector2(toMainframeX > 0 ? 1.0 : -1.0, 0.0);
    speed = 135.0;
  }

  /// Alias de compatibilidade
  void moveToMainframe(Vector2 mainframePosition) {
    turnToMainframe(mainframePosition);
  }

  /// Para a unidade a ~100px de distância do Mainframe para bombardeio contínuo
  void stopAndAttackMainframe(Vector2 mainframePosition) {
    movementState = PacketMovementState.attackingMainframe;
    speed = 0.0;
    targetMainframe = mainframePosition;
    basePosition.setFrom(position);
    _trailPositions.clear();
    final diff = mainframePosition - position;
    if (diff.length > 0) {
      direction = diff.normalized();
    }
  }

  /// Aplica dano ao pacote e ativa o flash branco de impacto
  void takeDamage(double amount) {
    if (isDead) return;
    currentHealth -= amount;
    _flashTimer = 0.08;

    if (currentHealth <= 0) {
      onDestroyed?.call(this);
      removeFromParent();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final Color color;
    switch (origin) {
      case PacketOrigin.blueDefense:
        color = AppColors.blueTeam;
        break;
      case PacketOrigin.redExploit:
        color = subtype == PacketSubtype.zeroDayPayload ? AppColors.coreAi : AppColors.redTeam;
        break;
      case PacketOrigin.clientTraffic:
        color = AppColors.bandwidth;
        break;
    }

    _packetPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    _flashPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (speed > 0) {
      _sinuousTimer += dt;
      basePosition += direction * speed * dt;

      if (isSinuous) {
        // Vetor ortogonal perpendicular: se direção é (dx, dy), normal é (-dy, dx)
        final normal = Vector2(-direction.y, direction.x);
        if (normal.length2 > 0) {
          normal.normalize();
        }
        final waveOffset = math.sin(_sinuousTimer * sinuousFrequency + sinuousPhase) * sinuousAmplitude;
        position.setFrom(basePosition + (normal * waveOffset));

        // Atualização periódica do rastro neon cyberpunk
        _trailTimer += dt;
        if (_trailTimer >= 0.035) {
          _trailTimer = 0.0;
          _trailPositions.insert(0, position.clone());
          if (_trailPositions.length > _maxTrailPoints) {
            _trailPositions.removeLast();
          }
        }
      } else {
        position.setFrom(basePosition);
      }
    } else {
      _trailPositions.clear();
    }

    if (_flashTimer > 0) {
      _flashTimer -= dt;
    }

    // Ataque contínuo ao Mainframe enquanto estiver em posição de cerco (~100px)
    if (movementState == PacketMovementState.attackingMainframe && !isDead) {
      attackCooldown -= dt;
      if (attackCooldown <= 0.0) {
        attackCooldown = attackCadence;
        onAttackMainframe?.call(this);
      }
    }

    // Tráfego legítimo de clientes atinge a borda inferior do campo e é entregue
    if (origin == PacketOrigin.clientTraffic && direction.y > 0 && position.y >= 500) {
      onReachedEnd?.call(this);
      removeFromParent();
    }
    // Tráfego ofensivo aliado subindo pelo túnel até a base oponente
    else if (origin == PacketOrigin.blueDefense && direction.y < 0 && position.y <= -500) {
      onReachedEnd?.call(this);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    final center = Offset(radius, radius);

    // Se estiver em flash de dano, desenha círculo branco quente
    if (_flashTimer > 0) {
      canvas.drawCircle(center, radius + 2, _flashPaint);
      return;
    }

    // Rastro Neon Cyberpunk para movimentação sinuosa
    if (isSinuous && _trailPositions.isNotEmpty) {
      for (int i = 0; i < _trailPositions.length; i++) {
        final tp = _trailPositions[i];
        final trailCenter = Offset(
          tp.x - position.x + radius,
          tp.y - position.y + radius,
        );
        final ratio = 1.0 - ((i + 1) / (_trailPositions.length + 1));
        final trailPaint = Paint()
          ..color = _packetPaint.color.withValues(alpha: 0.35 * ratio)
          ..style = PaintingStyle.fill;
        final trailRadius = (radius * 0.7) * ratio;
        canvas.drawCircle(trailCenter, trailRadius, trailPaint);
      }
    }

    // Brilho Neon Externo
    canvas.drawCircle(center, radius + 2, _glowPaint);

    // Indicador visual de ataque contínuo ao Mainframe (~100px)
    if (movementState == PacketMovementState.attackingMainframe) {
      final siegePaint = Paint()
        ..color = AppColors.redTeam.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius + 5, siegePaint);

      // Traço de mira apontando diretamente ao Mainframe
      final aimEnd = center + Offset(direction.x * (radius + 8), direction.y * (radius + 8));
      final aimPaint = Paint()
        ..color = AppColors.redTeam.withValues(alpha: 0.9)
        ..strokeWidth = 2.0;
      canvas.drawLine(center, aimEnd, aimPaint);
    }

    // Núcleo do Pacote
    canvas.drawCircle(center, radius, _packetPaint);

    // Anel característico para o Boss Zero-Day
    if (subtype == PacketSubtype.zeroDayPayload) {
      final ringPaint = Paint()
        ..color = AppColors.redTeam
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius - 2, ringPaint);
    }

    // Mini barra de vida caso tenha sofrido dano e ainda esteja vivo
    if (currentHealth < maxHealth && !isDead) {
      final barWidth = size.x * 1.5;
      const barHeight = 2.5;
      final barLeft = center.dx - (barWidth / 2);
      final barTop = center.dy - radius - 5;

      final ratio = (currentHealth / maxHealth).clamp(0.0, 1.0);
      final bg = Paint()..color = AppColors.surface;
      final fill = Paint()..color = origin == PacketOrigin.redExploit ? AppColors.redTeam : AppColors.bandwidth;

      canvas.drawRect(Rect.fromLTWH(barLeft, barTop, barWidth, barHeight), bg);
      canvas.drawRect(Rect.fromLTWH(barLeft, barTop, barWidth * ratio, barHeight), fill);
    }
  }
}
