import 'dart:ui';
import 'package:flame/components.dart';

/// Efeito visual de feixe de laser disparado por um bastião contra um pacote inimigo.
class LaserBeamEffect extends PositionComponent {
  final Vector2 start;
  final Vector2 end;
  final Color beamColor;
  final double duration;

  double _elapsed = 0.0;
  late final Paint _corePaint;
  late final Paint _glowPaint;

  LaserBeamEffect({
    required this.start,
    required this.end,
    required this.beamColor,
    this.duration = 0.16,
  }) : super(priority: 10);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _corePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _glowPaint = Paint()
      ..color = beamColor.withOpacity(0.8)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    final glow = Paint()
      ..color = beamColor.withOpacity(0.8 * alpha)
      ..strokeWidth = 6.0 * (1.0 - (progress * 0.3))
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke;

    final core = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(alpha)
      ..strokeWidth = 2.0 * (1.0 - (progress * 0.3))
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final p1 = Offset(start.x, start.y);
    final p2 = Offset(end.x, end.y);

    // Desenha brilho externo e núcleo branco quente
    canvas.drawLine(p1, p2, glow);
    canvas.drawLine(p1, p2, core);
  }
}
