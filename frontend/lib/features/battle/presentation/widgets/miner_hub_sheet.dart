import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/match_economy_state.dart';

/// Modal dedicado para contratação e gerenciamento de unidades mineradoras (HashMiner Daemons).
class MinerHubSheet extends StatelessWidget {
  final MatchEconomyState economy;
  final VoidCallback onRecruitMiner;

  const MinerHubSheet({
    super.key,
    required this.economy,
    required this.onRecruitMiner,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = economy.canAffordMiner;
    final minerCost = economy.minerCost;
    final bitRate = economy.minersCount * 5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFF00FF66).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF66).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de arrasto superior
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Título e Ícone
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF66).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: const Color(0xFF00FF66).withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.memory_rounded, color: Color(0xFF00FF66), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CENTRAL DE MINERAÇÃO (HASHMINER)',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gere Bits continuamente para financiar ofensivas ao time rival',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Métricas de Mineração
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.7),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  label: 'MINERADORES ATIVOS',
                  value: '${economy.minersCount}',
                  unit: 'Daemons',
                  color: const Color(0xFF00FF66),
                  icon: Icons.precision_manufacturing_rounded,
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildMetric(
                  label: 'TAXA DE PRODUÇÃO',
                  value: '+$bitRate',
                  unit: 'Bits / 3 seg',
                  color: const Color(0xFF00F0FF),
                  icon: Icons.electric_bolt_rounded,
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildMetric(
                  label: 'BITS ACUMULADOS',
                  value: '${economy.bits}',
                  unit: 'Bits',
                  color: const Color(0xFFFFCC00),
                  icon: Icons.savings_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card Didático do Ciclo Econômico
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.05),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF00F0FF), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tokens são investidos em HashMiners ➔ HashMiners acumulam Bits ➔ Bits contratam ataques ➔ Cada ataque despachado aumenta permanentemente sua Renda de Tokens por Round!',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botão de Contratação
          ElevatedButton(
            onPressed: canAfford ? onRecruitMiner : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF66),
              disabledBackgroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: canAfford ? Colors.black : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'RECRUTAR HASHMINER DAEMON',
                  style: AppTypography.titleMedium.copyWith(
                    color: canAfford ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: canAfford ? Colors.black.withValues(alpha: 0.2) : AppColors.border,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    '🪙 $minerCost Tokens',
                    style: AppTypography.codeSmall.copyWith(
                      color: canAfford ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tokens Disponíveis: 🪙 ${economy.tokens}',
              style: AppTypography.codeSmall.copyWith(
                color: canAfford ? const Color(0xFFFFCC00) : AppColors.redTeam,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.displayMedium.copyWith(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.codeSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 8.5,
          ),
        ),
        Text(
          unit,
          style: AppTypography.codeSmall.copyWith(
            color: color.withValues(alpha: 0.8),
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
