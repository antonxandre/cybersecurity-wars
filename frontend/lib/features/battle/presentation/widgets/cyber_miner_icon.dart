import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Ícone vetorial estilizado de Minerador Cyberpunk (Picareta de Alta Tecnologia com Núcleo Neon).
/// Desenhado via CustomPainter para garantir nitidez cristalina em qualquer escala e resolução.
class CyberMinerIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? glowColor;
  final bool isMining;

  const CyberMinerIcon({
    super.key,
    this.size = 20.0,
    this.color,
    this.glowColor,
    this.isMining = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.bandwidth;
    final activeGlow = glowColor ?? activeColor.withValues(alpha: 0.5);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CyberMinerPainter(
          color: activeColor,
          glowColor: activeGlow,
        ),
      ),
    );
  }
}

class _CyberMinerPainter extends CustomPainter {
  final Color color;
  final Color glowColor;

  _CyberMinerPainter({
    required this.color,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shaftPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = math.max(1.8, w * 0.1)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final pickHeadPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.5, w * 0.1));

    final shaftGlowPaint = Paint()
      ..color = glowColor
      ..strokeWidth = math.max(2.5, w * 0.14)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.0, w * 0.08));

    // Ponto de início (canto inferior esquerdo) até o cabeçote (canto superior direito)
    final startPoint = Offset(w * 0.22, h * 0.82);
    final junctionPoint = Offset(w * 0.70, h * 0.30);

    // 1. Cabo / Haste de Fibra de Carbono / Laser
    canvas.drawLine(startPoint, junctionPoint, shaftGlowPaint);
    canvas.drawLine(startPoint, junctionPoint, shaftPaint);

    // 2. Cabeçote Curvo Chanfrado da Picareta Cibernética
    // Ponta esquerda (superior/espinho)
    final pickPath = Path();
    final pTop = Offset(w * 0.54, h * 0.08);      // Ponta superior afiada
    final pOuter = Offset(w * 0.76, h * 0.22);    // Dorso superior
    final pRight = Offset(w * 0.94, h * 0.46);    // Ponta direita afiada
    final pInner = Offset(w * 0.64, h * 0.38);    // Centro côncavo inferior

    pickPath.moveTo(pTop.dx, pTop.dy);
    pickPath.quadraticBezierTo(pOuter.dx, pOuter.dy * 0.8, pRight.dx, pRight.dy);
    pickPath.lineTo(pRight.dx - (w * 0.08), pRight.dy - (h * 0.02));
    pickPath.quadraticBezierTo(pInner.dx, pInner.dy, pTop.dx + (w * 0.04), pTop.dy + (h * 0.08));
    pickPath.close();

    // Glow e desenho do cabeçote
    canvas.drawPath(pickPath, glowPaint);
    canvas.drawPath(pickPath, pickHeadPaint);

    // 3. Núcleo Hexagonal de Energia Neon na Junção
    final coreCenter = Offset(w * 0.68, h * 0.32);
    final coreRadius = math.max(2.0, w * 0.12);

    final coreGlow = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(2.0, w * 0.12));
    canvas.drawCircle(coreCenter, coreRadius * 0.7, coreGlow);

    final corePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(coreCenter, coreRadius * 0.5, corePaint);

    // 4. Detalhe no pomo da base (grip)
    final gripPaint = Paint()
      ..color = color
      ..strokeWidth = math.max(2.2, w * 0.13)
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    canvas.drawLine(startPoint, Offset(startPoint.dx + (w * 0.08), startPoint.dy - (h * 0.08)), gripPaint);
  }

  @override
  bool shouldRepaint(covariant _CyberMinerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.glowColor != glowColor;
  }
}
