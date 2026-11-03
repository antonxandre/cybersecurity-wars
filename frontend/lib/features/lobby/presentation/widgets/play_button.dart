import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Botão de Ação Primária Chanfrado (Estilo Esports AAA) com neon glow e gradiente.
class PlayButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isLoading;
  final double height;
  final double minWidth;

  const PlayButton({
    super.key,
    required this.label,
    this.icon = Icons.play_arrow_rounded,
    required this.onPressed,
    this.primaryColor = AppColors.blueTeam,
    this.secondaryColor = AppColors.blueTeamSecondary,
    this.isLoading = false,
    this.height = 54,
    this.minWidth = 220,
  });

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulseScale = 0.98 + (_pulseController.value * 0.04);
            final glowBlur = _isHovered ? 24.0 : (12.0 + (_pulseController.value * 8.0));

            return AnimatedScale(
              scale: _isHovered && isEnabled ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: Container(
                constraints: BoxConstraints(minWidth: widget.minWidth, minHeight: widget.height),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: widget.primaryColor.withValues(
                              alpha: _isHovered ? 0.6 : (0.35 * pulseScale),
                            ),
                            blurRadius: glowBlur,
                            spreadRadius: _isHovered ? 2 : 0,
                          ),
                        ]
                      : [],
                ),
                child: ClipPath(
                  clipper: const _ChamferClipper(chamferSize: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isEnabled
                          ? LinearGradient(
                              colors: _isHovered
                                  ? [widget.primaryColor, widget.secondaryColor]
                                  : [
                                      widget.primaryColor.withValues(alpha: 0.95),
                                      widget.secondaryColor.withValues(alpha: 0.90),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [AppColors.cardSurface, AppColors.surface],
                            ),
                      border: Border.all(
                        color: isEnabled
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.icon,
                                  size: 26,
                                  color: isEnabled ? Colors.black : AppColors.textMuted,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.label.toUpperCase(),
                                  style: AppTypography.titleLarge.copyWith(
                                    color: isEnabled ? Colors.black : AppColors.textMuted,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Corta os cantos chanfrados para estética militar cyber.
class _ChamferClipper extends CustomClipper<Path> {
  final double chamferSize;

  const _ChamferClipper({this.chamferSize = 10});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(chamferSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - chamferSize);
    path.lineTo(size.width - chamferSize, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, chamferSize);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ChamferClipper oldClipper) =>
      oldClipper.chamferSize != chamferSize;
}
