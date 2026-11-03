import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Painel tático estilizado para a interface de jogo (glassmorphism cyber).
class LobbyPanel extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;
  final bool showGlow;
  final double borderRadius;

  const LobbyPanel({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.trailing,
    this.accentColor,
    this.padding = const EdgeInsets.all(16),
    this.showGlow = false,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppColors.borderGlow;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: showGlow
              ? effectiveAccent.withValues(alpha: 0.6)
              : AppColors.borderGlow.withValues(alpha: 0.7),
          width: showGlow ? 1.5 : 1.0,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: effectiveAccent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface.withValues(alpha: 0.6),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: effectiveAccent),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: AppTypography.codeMedium.copyWith(
                          color: effectiveAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ],
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
