import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Camada de atmosfera visual imersiva (vinheta radial, scanlines CRT e alerta crítico de Mainframe).
/// Não intercepta toques do usuário (IgnorePointer).
class ArenaAtmosphereOverlay extends StatefulWidget {
  final bool isCriticalAlert;

  const ArenaAtmosphereOverlay({
    super.key,
    required this.isCriticalAlert,
  });

  @override
  State<ArenaAtmosphereOverlay> createState() => _ArenaAtmosphereOverlayState();
}

class _ArenaAtmosphereOverlayState extends State<ArenaAtmosphereOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );

    if (widget.isCriticalAlert) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ArenaAtmosphereOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCriticalAlert != oldWidget.isCriticalAlert) {
      if (widget.isCriticalAlert) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Vinheta Radial Ambiente (foco no centro da tela)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.05,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.35),
                  AppColors.background.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.55, 0.85, 1.0],
              ),
            ),
          ),

          // 2. Scanlines CRT sutis para textura de terminal de alta tecnologia
          const RepaintBoundary(
            child: CustomPaint(
              painter: _CrtScanlinePainter(),
              size: Size.infinite,
            ),
          ),

          // 3. Vinheta de Alerta Crítico Pulsante (Vermelho Carmesim quando HP < 30%)
          if (widget.isCriticalAlert)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                final pulseValue = _pulseAnimation.value;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        AppColors.redTeam.withValues(alpha: 0.12 * pulseValue),
                        AppColors.redTeam.withValues(alpha: 0.40 * pulseValue),
                      ],
                      stops: const [0.0, 0.45, 0.75, 1.0],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// CustomPainter para desenhar linhas horizontais ultrafinas de CRT
class _CrtScanlinePainter extends CustomPainter {
  const _CrtScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const step = 3.5;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
