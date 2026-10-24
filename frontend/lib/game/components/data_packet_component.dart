import 'dart:ui';
import 'package:flame/components.dart';
import '../../core/theme/app_colors.dart';

enum PacketOrigin { blueDefense, redExploit, clientTraffic }

enum PacketSubtype { portScanner, synFlood, zeroDayPayload, clientHttps, bluePayload }

/// Componente de Pacote de Dados com HP, dano, tipos e animação de impacto.
class DataPacketComponent extends PositionComponent {
  final PacketOrigin origin;
  final PacketSubtype subtype;
  final double speed;
  final Vector2 direction;
  final double damage;
  final double maxHealth;
  void Function(DataPacketComponent packet)? onReachedEnd;
  void Function(DataPacketComponent packet)? onDestroyed;

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
    this.onReachedEnd,
    this.onDestroyed,
  })  : currentHealth = maxHealth,
        super(
          position: startPosition,
          size: subtype == PacketSubtype.zeroDayPayload
              ? Vector2(24, 24)
              : (subtype == PacketSubtype.synFlood ? Vector2(10, 10) : Vector2(14, 14)),
          anchor: Anchor.center,
        );

  bool get isDead => currentHealth <= 0;

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
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    _flashPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;

    if (_flashTimer > 0) {
      _flashTimer -= dt;
    }

    // Se o pacote descer e atingir a base inferior (LLM Core)
    if (direction.y > 0 && position.y >= 540) {
      onReachedEnd?.call(this);
      removeFromParent();
    }
    // Se o pacote da defesa subir e atingir o topo da tela
    else if (direction.y < 0 && position.y <= 60) {
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

    // Brilho Neon Externo
    canvas.drawCircle(center, radius + 2, _glowPaint);

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
      final barHeight = 2.5;
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
