import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/roguelite_perk.dart';

/// Modal estilo Archero para Escolha Roguelite de 1 entre 3 Perks.
class PerkSelectionDialog extends StatelessWidget {
  final List<RoguelitePerk> perks;
  final void Function(RoguelitePerk perk) onPerkSelected;

  const PerkSelectionDialog({
    super.key,
    required this.perks,
    required this.onPerkSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.98),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.coreAi, width: 2),
          boxShadow: AppColors.neonGlow(AppColors.coreAi, blur: 24, spread: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.coreAi, size: 24),
                const SizedBox(width: 8),
                Text('APRIMORAMENTO ROGUELITE', style: AppTypography.displayMedium),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Escolha 1 modificador cibernético para a próxima onda:',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: perks.map((perk) => _buildPerkOption(context, perk)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkOption(BuildContext context, RoguelitePerk perk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: perk.categoryColor.withOpacity(0.6), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onPerkSelected(perk),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: perk.categoryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: perk.categoryColor),
                  ),
                  child: Icon(perk.icon, color: perk.categoryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            perk.name,
                            style: AppTypography.displaySmall.copyWith(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: perk.categoryColor, width: 0.8),
                            ),
                            child: Text(
                              'TIER ${perk.tier}',
                              style: AppTypography.codeSmall.copyWith(
                                fontSize: 9,
                                color: perk.categoryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        perk.description,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
