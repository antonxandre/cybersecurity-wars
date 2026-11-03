import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Modelo de notificação tática flutuante rápida (estilo HUD militar / cibersegurança).
class TacticalNotificationItem {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final DateTime timestamp;

  TacticalNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    this.accentColor = AppColors.blueTeam,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Widget controlador e renderizador de toasts táticos empilhados no canto inferior/lateral da Arena.
/// Evita sobreposição com o dock inferior.
class TacticalNotificationToast extends StatelessWidget {
  final TacticalNotificationItem? notification;
  final VoidCallback? onDismiss;

  const TacticalNotificationToast({
    super.key,
    required this.notification,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (notification == null) return const SizedBox.shrink();

    final item = notification!;

    return TweenAnimationBuilder<double>(
      key: ValueKey(item.id),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: Opacity(
            opacity: val.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: item.accentColor.withValues(alpha: 0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: item.accentColor.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: item.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: item.accentColor.withValues(alpha: 0.35)),
              ),
              child: Icon(item.icon, color: item.accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.codeSmall.copyWith(
                      color: item.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                onPressed: onDismiss,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
