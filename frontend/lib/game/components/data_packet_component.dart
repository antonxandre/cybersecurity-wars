import 'dart:ui';
import 'package:flame/components.dart';
import '../../core/theme/app_colors.dart';

enum PacketOrigin { blueDefense, redExploit, clientTraffic }

/// Componente de Pacote de Dados transitando nas rotas de rede da arena.
class DataPacketComponent extends PositionComponent {
  final PacketOrigin origin;
  final double speed;
  final Vector2 direction;
  final double damage;

  late final Paint _packetPaint;
  late final Paint _glowPaint;

  DataPacketComponent({
    required Vector2 startPosition,
    required this.origin,
    required this.direction,
    this.speed = 140.0,
    this.damage = 50.0,
  }) : super(
          position: startPosition,
          size: Vector2(14, 14),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final Color color;
    switch (origin) {
      case PacketOrigin.blueDefense:
        color = AppColors.blueTeam;
        break;
      case PacketOrigin.redExploit:
        color = AppColors.redTeam;
        break;
      case PacketOrigin.clientTraffic:
        color = AppColors.bandwidth;
        break;
    }

    _packetPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;

    // Remove o pacote caso saia dos limites verticais da tela
    if (position.y < -50 || position.y > 1200) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    final center = Offset(radius, radius);

    // Brilho Neon
    canvas.drawCircle(center, radius + 2, _glowPaint);
    // Núcleo do Pacote
    canvas.drawCircle(center, radius, _packetPaint);
  }
}
