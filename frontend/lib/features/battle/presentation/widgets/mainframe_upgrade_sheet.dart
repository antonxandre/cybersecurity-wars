import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/mainframe_model.dart';

/// Modal Tático para Upgrades de Hardware no Mainframe Central (O 'Rei' no Legion TD Cyber).
class MainframeUpgradeSheet extends StatelessWidget {
  final MainframeModel mainframe;
  final int availableTokens;
  final VoidCallback onUpgradeCpu;
  final VoidCallback onUpgradeRam;
  final VoidCallback onUpgradeDisk;

  const MainframeUpgradeSheet({
    super.key,
    required this.mainframe,
    required this.availableTokens,
    required this.onUpgradeCpu,
    required this.onUpgradeRam,
    required this.onUpgradeDisk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.borderGlow, width: 2.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Modal com Saldo de Tokens
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: mainframe.teamColor),
                  ),
                  child: Icon(Icons.memory_rounded, color: mainframe.teamColor, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MAINFRAME CENTRAL // HARDWARE', style: AppTypography.titleLarge),
                    Text(
                      'FORTIFIQUE A ÚLTIMA LINHA DE DEFESA DO TIME',
                      style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.coreAi.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.coreAi),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.token_rounded, color: AppColors.coreAi, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$availableTokens TOKENS',
                        style: AppTypography.codeMedium.copyWith(
                          color: AppColors.coreAi,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra de Status Atual do Servidor
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatIndicator(
                    label: 'INTEGRIDADE',
                    value: '${mainframe.currentHp.toInt()} / ${mainframe.maxHp.toInt()} HP',
                    color: AppColors.bandwidth,
                  ),
                  Container(width: 1, height: 28, color: AppColors.border),
                  _buildStatIndicator(
                    label: 'DPS DO LASER',
                    value: '${mainframe.laserDps.toInt()} DPS',
                    color: AppColors.blueTeam,
                  ),
                  Container(width: 1, height: 28, color: AppColors.border),
                  _buildStatIndicator(
                    label: 'ALVOS SIMULTÂNEOS',
                    value: '${mainframe.targetCount} ALVO(S)',
                    color: AppColors.cpuClock,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3 Opções de Upgrades de Hardware
            Row(
              children: [
                Expanded(
                  child: _buildUpgradeCard(
                    title: 'CPU / OVERCLOCK',
                    icon: Icons.speed_rounded,
                    level: mainframe.cpuLevel,
                    benefit: '+30 DPS por disparo',
                    cost: mainframe.upgradeCostCpu,
                    canUpgrade: mainframe.canUpgradeCpu && availableTokens >= mainframe.upgradeCostCpu,
                    onTap: onUpgradeCpu,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUpgradeCard(
                    title: 'RAM / MULTI-TARGET',
                    icon: Icons.view_column_rounded,
                    level: mainframe.ramLevel,
                    benefit: '+1 Alvo Simultâneo',
                    cost: mainframe.upgradeCostRam,
                    canUpgrade: mainframe.canUpgradeRam && availableTokens >= mainframe.upgradeCostRam,
                    onTap: onUpgradeRam,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUpgradeCard(
                    title: 'DISCO / STORAGE',
                    icon: Icons.storage_rounded,
                    level: mainframe.diskLevel,
                    benefit: '+400 HP de Integridade',
                    cost: mainframe.upgradeCostDisk,
                    canUpgrade: mainframe.canUpgradeDisk && availableTokens >= mainframe.upgradeCostDisk,
                    onTap: onUpgradeDisk,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIndicator({required String label, required String value, required Color color}) {
    return Column(
      children: [
        Text(label, style: AppTypography.codeSmall.copyWith(fontSize: 9, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.codeSmall.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildUpgradeCard({
    required String title,
    required IconData icon,
    required int level,
    required String benefit,
    required int cost,
    required bool canUpgrade,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canUpgrade ? AppColors.coreAi.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: canUpgrade ? AppColors.coreAi : AppColors.textMuted, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.codeSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('NÍVEL $level', style: AppTypography.codeMedium.copyWith(color: AppColors.cpuClock)),
          const SizedBox(height: 2),
          Text(benefit, style: AppTypography.codeSmall.copyWith(fontSize: 9, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canUpgrade ? AppColors.coreAi : AppColors.cardSurface,
                foregroundColor: AppColors.background,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: canUpgrade ? onTap : null,
              child: Text(
                '$cost TOKENS',
                style: AppTypography.codeSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: canUpgrade ? AppColors.background : AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
