import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Barra de integridade de Mainframe tática com damage trail, segmentação futurista e glow neon.
class MainframeHealthBar extends StatelessWidget {
  final String label;
  final double currentHp;
  final double maxHp;
  final double hpPercent;
  final Color primaryColor;
  final bool isReversed; // Se true, inverte o preenchimento (lado direito do placar)

  const MainframeHealthBar({
    super.key,
    required this.label,
    required this.currentHp,
    required this.maxHp,
    required this.hpPercent,
    required this.primaryColor,
    this.isReversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final double fraction = (hpPercent / 100.0).clamp(0.0, 1.0);
    final isLowHp = hpPercent <= 25.0;

    return Column(
      crossAxisAlignment:
          isReversed ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rótulos Superiores: Nome e HP Numérico com %
        Row(
          mainAxisAlignment: isReversed
              ? MainAxisAlignment.end
              : MainAxisAlignment.spaceBetween,
          children: isReversed
              ? [
                  Text(
                    '${currentHp.toInt()}/${maxHp.toInt()} HP (${hpPercent.toInt()}%)',
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 12.5,
                      color: isLowHp ? AppColors.statusOpen : primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ]
              : [
                  Text(
                    label,
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '${currentHp.toInt()}/${maxHp.toInt()} HP (${hpPercent.toInt()}%)',
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 12.5,
                      color: isLowHp ? AppColors.statusOpen : primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 4),

        // Barra Segmentada com Animação de Damage Trail
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.4),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
              if (isLowHp)
                BoxShadow(
                  color: AppColors.redTeam.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Barra de Damage Trail (transição lenta vermelha/laranja atrás)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: fraction, end: fraction),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, trailVal, _) {
                    return FractionallySizedBox(
                      alignment: isReversed
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      widthFactor: trailVal,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    );
                  },
                ),

                // 2. Barra Principal (transição ágil com gradiente neon)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: fraction, end: fraction),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutQuad,
                  builder: (context, currentVal, _) {
                    return FractionallySizedBox(
                      alignment: isReversed
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      widthFactor: currentVal,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.75),
                            ],
                            begin: isReversed
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            end: isReversed
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // 3. Grid de Segmentação Sci-Fi (marcas divisórias de 10 em 10%)
                Row(
                  children: List.generate(
                    10,
                    (index) => Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.black.withValues(alpha: 0.45),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
