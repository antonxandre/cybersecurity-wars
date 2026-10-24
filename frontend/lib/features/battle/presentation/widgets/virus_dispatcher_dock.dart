import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/match_economy_state.dart';
import '../../domain/models/tactical_virus_model.dart';

/// Dock Tático de Envio de Malwares e Gerenciamento de Mineradores (estilo Legion TD).
/// Substitui o dock de cartas por uma central de ataque com Tokens e bônus de renda permanente.
class VirusDispatcherDock extends StatelessWidget {
  final MatchEconomyState economy;
  final void Function(TacticalVirusModel virus) onSendVirus;
  final VoidCallback onRecruitMiner;
  final VoidCallback onOpenMainframeUpgrades;

  const VirusDispatcherDock({
    super.key,
    required this.economy,
    required this.onSendVirus,
    required this.onRecruitMiner,
    required this.onOpenMainframeUpgrades,
  });

  @override
  Widget build(BuildContext context) {
    final viruses = TacticalVirusModel.catalog;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.borderGlow, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra Superior da Economia: Saldo de Bits, Tokens, Mineradores e Renda
            Row(
              children: [
                // Saldo de Bits (Ouro)
                _buildCurrencyChip(
                  icon: Icons.toll_rounded,
                  label: '${economy.bits} BITS',
                  color: AppColors.blueTeam,
                  sublabel: '+${economy.totalIncomeBits}/rodada',
                ),
                const SizedBox(width: 8),

                // Saldo de Tokens (Cripto/Lumber)
                _buildCurrencyChip(
                  icon: Icons.token_rounded,
                  label: '${economy.tokens} TOKENS',
                  color: AppColors.coreAi,
                  sublabel: '+${economy.tokenRatePerSecond.toStringAsFixed(1)}/s',
                ),
                const Spacer(),

                // Botão Recrutar Minerador
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: economy.canRecruitMiner
                        ? AppColors.cardSurface
                        : AppColors.background.withValues(alpha: 0.5),
                    side: BorderSide(
                      color: economy.canRecruitMiner ? AppColors.cpuClock : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: economy.canRecruitMiner ? onRecruitMiner : null,
                  icon: const Icon(Icons.memory_rounded, size: 14, color: AppColors.cpuClock),
                  label: Text(
                    'MINERADOR (${economy.minersCount}/${economy.maxMiners}) [${economy.minerCostBits} BITS]',
                    style: AppTypography.codeSmall.copyWith(
                      color: economy.canRecruitMiner ? AppColors.cpuClock : AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Botão de Acesso aos Upgrades do Mainframe
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coreAi,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onOpenMainframeUpgrades,
                  icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                  label: Text(
                    'UPGRADE MAINFRAME',
                    style: AppTypography.codeSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Carrossel Horizontal de Malwares Disponíveis para Envio
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: viruses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final virus = viruses[index];
                  final canAfford = economy.tokens >= virus.tokenCost;

                  return _buildVirusCard(virus, canAfford);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyChip({
    required IconData icon,
    required String label,
    required Color color,
    required String sublabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.codeSmall.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              Text(
                sublabel,
                style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVirusCard(TacticalVirusModel virus, bool canAfford) {
    final activeColor = canAfford ? virus.color : AppColors.textMuted;

    return InkWell(
      onTap: canAfford ? () => onSendVirus(virus) : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: canAfford ? AppColors.cardSurface : AppColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activeColor.withValues(alpha: canAfford ? 0.6 : 0.2),
            width: 1.2,
          ),
          boxShadow: canAfford ? AppColors.neonGlow(activeColor, blur: 8, spread: 0.2) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: activeColor.withValues(alpha: 0.4)),
              ),
              child: Icon(virus.icon, color: activeColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    virus.name,
                    style: AppTypography.codeSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: canAfford ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${virus.tokenCost} TOKENS',
                        style: AppTypography.codeSmall.copyWith(
                          color: canAfford ? AppColors.coreAi : AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.bandwidth.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${virus.incomeBonus} Renda',
                          style: AppTypography.codeSmall.copyWith(
                            color: AppColors.bandwidth,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
