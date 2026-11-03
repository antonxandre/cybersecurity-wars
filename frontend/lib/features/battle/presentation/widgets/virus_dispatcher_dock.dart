import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/match_economy_state.dart';
import '../../domain/models/tactical_virus_model.dart';

import 'cyber_miner_icon.dart';
import 'tactical_operations_panel.dart';

/// Dock Tático de Envio de Malwares e Gerenciamento Econômico (estilo Legion TD).
/// Malwares são contratados com Bits para invadir o time adversário e concedem Renda Permanente de Tokens.
class VirusDispatcherDock extends StatelessWidget {
  final MatchEconomyState economy;
  final int queuedAttacksCount;
  final TacticalPanelTab? activeTab;
  final void Function(TacticalVirusModel virus) onSendVirus;
  final VoidCallback onOpenMinerHub;
  final VoidCallback onOpenQueuedAttacks;
  final VoidCallback onOpenMainframeUpgrades;

  const VirusDispatcherDock({
    super.key,
    required this.economy,
    this.queuedAttacksCount = 0,
    this.activeTab,
    required this.onSendVirus,
    required this.onOpenMinerHub,
    required this.onOpenQueuedAttacks,
    required this.onOpenMainframeUpgrades,
  });

  @override
  Widget build(BuildContext context) {
    final viruses = TacticalVirusModel.catalog;

    final isMinerActive = activeTab == TacticalPanelTab.miner;
    final isQueueActive = activeTab == TacticalPanelTab.offensiveQueue;
    final isMainframeActive = activeTab == TacticalPanelTab.mainframe;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.90),
              borderRadius: BorderRadius.zero,
              border: const Border(
                top: BorderSide(color: AppColors.borderGlow, width: 1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barra Superior: Saldo de Moedas, Hub de Mineração e Fila de Ataques
                  Row(
                    children: [
                      // Saldo de Bits Minerados
                      _buildCurrencyChip(
                        icon: Icons.bolt_rounded,
                        label: '${economy.bits} BITS',
                        color: AppColors.blueTeam,
                        sublabel: '+${economy.minersCount * 5} bits/3s',
                      ),
                      const SizedBox(width: 8),

                      // Saldo de Tokens de Defesa e Renda
                      _buildCurrencyChip(
                        icon: Icons.toll_rounded,
                        label: '${economy.tokens} TOKENS',
                        color: AppColors.cpuClock,
                        sublabel: '+${economy.permanentIncomeTokens}T/round',
                      ),
                      const Spacer(),

                      // Botão Minerador (CyberMinerIcon + Nomenclatura Simplificada)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isMinerActive
                              ? AppColors.bandwidth.withValues(alpha: 0.2)
                              : AppColors.cardSurface,
                          side: BorderSide(
                            color: isMinerActive
                                ? AppColors.bandwidth
                                : (economy.canAffordMiner
                                    ? AppColors.bandwidth.withValues(alpha: 0.7)
                                    : AppColors.border),
                            width: isMinerActive ? 1.6 : 1.0,
                          ),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: onOpenMinerHub,
                        icon: CyberMinerIcon(
                          size: 17,
                          color: isMinerActive
                              ? AppColors.bandwidth
                              : (economy.canAffordMiner
                                  ? AppColors.bandwidth
                                  : AppColors.textMuted),
                        ),
                        label: Text(
                          'MINERADOR (${economy.minersCount}) [${economy.minerCost}T]',
                          style: AppTypography.codeSmall.copyWith(
                            color: isMinerActive || economy.canAffordMiner
                                ? AppColors.bandwidth
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botão Fila de Ataques Submetidos
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isQueueActive
                              ? AppColors.redTeam.withValues(alpha: 0.22)
                              : (queuedAttacksCount > 0
                                  ? AppColors.redTeam.withValues(alpha: 0.12)
                                  : AppColors.cardSurface),
                          side: BorderSide(
                            color: isQueueActive
                                ? AppColors.redTeam
                                : (queuedAttacksCount > 0
                                    ? AppColors.redTeam
                                    : AppColors.border),
                            width: isQueueActive ? 1.6 : 1.0,
                          ),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: onOpenQueuedAttacks,
                        icon: const Icon(
                          Icons.radar_rounded,
                          size: 17,
                          color: AppColors.redTeam,
                        ),
                        label: Text(
                          'FILA OFENSIVA ($queuedAttacksCount)',
                          style: AppTypography.codeSmall.copyWith(
                            color: isQueueActive || queuedAttacksCount > 0
                                ? AppColors.redTeam
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botão de Acesso aos Upgrades do Mainframe
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isMainframeActive
                              ? AppColors.coreAi.withValues(alpha: 0.25)
                              : AppColors.cardSurface,
                          side: BorderSide(
                            color: isMainframeActive
                                ? AppColors.coreAi
                                : AppColors.coreAi.withValues(alpha: 0.7),
                            width: isMainframeActive ? 1.6 : 1.0,
                          ),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: onOpenMainframeUpgrades,
                        icon: Icon(
                          Icons.memory_rounded,
                          size: 17,
                          color: isMainframeActive ? AppColors.coreAi : const Color(0xFFD080FF),
                        ),
                        label: Text(
                          'MAINFRAME',
                          style: AppTypography.codeSmall.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: isMainframeActive ? Colors.white : const Color(0xFFD080FF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Carrossel Horizontal de Malwares Disponíveis para Envio com Bits
                  SizedBox(
                    height: 82,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: viruses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final virus = viruses[index];
                        final canAfford = economy.bits >= virus.bitCost;
                        final hotkey = index < 9 ? '${index + 1}' : null;

                        return _buildVirusCard(virus, canAfford, hotkey);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.codeSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                sublabel,
                style: AppTypography.codeSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVirusCard(
      TacticalVirusModel virus, bool canAfford, String? hotkey) {
    final activeColor = canAfford ? virus.color : AppColors.textMuted;
    final progressFraction = canAfford
        ? 1.0
        : (economy.bits / virus.bitCost.toDouble()).clamp(0.0, 1.0);

    return InkWell(
      onTap: canAfford ? () => onSendVirus(virus) : null,
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: canAfford
              ? AppColors.cardSurface
              : AppColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: activeColor.withValues(alpha: canAfford ? 0.7 : 0.25),
            width: canAfford ? 1.2 : 1.0,
          ),
          boxShadow: canAfford
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                // Ícone do Malware com badge de Hotkey
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: activeColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(virus.icon, color: activeColor, size: 20),
                    ),
                    if (hotkey != null)
                      Positioned(
                        top: -3,
                        left: -3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: activeColor.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            hotkey,
                            style: AppTypography.codeSmall.copyWith(
                              fontSize: 9.5,
                              color: activeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),

                // Dados do Malware (Nome, Custo e Renda)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        virus.name,
                        style: AppTypography.codeSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: canAfford
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: canAfford
                                ? AppColors.blueTeam
                                : AppColors.textMuted,
                          ),
                          Text(
                            ' ${virus.bitCost}b',
                            style: AppTypography.codeSmall.copyWith(
                              color: canAfford
                                  ? AppColors.blueTeam
                                  : AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.cpuClock.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.zero,
                              border: Border.all(
                                color:
                                    AppColors.cpuClock.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '+${virus.incomeBonus}T',
                              style: AppTypography.codeSmall.copyWith(
                                color: AppColors.cpuClock,
                                fontSize: 10.5,
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

            // Barra de progresso de acumulação de Bits se o jogador ainda não pode pagar
            if (!canAfford) ...[
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 2.5,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.blueTeam.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
