import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tactical_virus_model.dart';

/// Módulo de Telemetria Ofensiva: Exibe as unidades e ataques que foram submetidos pelo time
/// e que serão despachados como ameaças adicionais contra a equipe adversária no round seguinte.
class QueuedAttacksDrawer extends StatelessWidget {
  final List<TacticalVirusModel> queuedAttacks;
  final VoidCallback? onClose;

  const QueuedAttacksDrawer({
    super.key,
    required this.queuedAttacks,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final totalIncomeBonus = queuedAttacks.fold<int>(0, (sum, v) => sum + v.incomeBonus);

    return Container(
      constraints: const BoxConstraints(maxHeight: 380, maxWidth: 380),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.redTeam.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.redTeam.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da Gaveta de Ataques
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.redTeam.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: AppColors.redTeam, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FILA OFENSIVA (PRÓXIMO ROUND)',
                        style: AppTypography.codeSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Malwares que invadirão o time rival na próxima wave',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Resumo de Bônus Econômico Acumulado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.redTeam.withValues(alpha: 0.06),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📈', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Bônus de Renda Garantido:',
                          style: AppTypography.codeSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+$totalIncomeBonus Tokens / round',
                  style: AppTypography.codeSmall.copyWith(
                    color: const Color(0xFFFFCC00),
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Lista de Ataques Submetidos
          Flexible(
            child: queuedAttacks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty_rounded, size: 30, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'Nenhum malware na fila de despacho.',
                            style: AppTypography.codeSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Use Bits no Dock para enviar ataques ao rival!',
                            style: AppTypography.codeSmall.copyWith(
                              color: const Color(0xFF00F0FF),
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(10),
                    itemCount: queuedAttacks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final virus = queuedAttacks[index];
                      return _buildVirusItem(virus, index + 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirusItem(TacticalVirusModel virus, int index) {
    final vColor = virus.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: vColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: vColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(virus.icon, size: 14, color: vColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$index ${virus.name}',
                  style: AppTypography.codeSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  'Dano: ${virus.attackDamageBits.toInt()} Bits • Vel: ${virus.packetSpeed.toInt()} px/s',
                  style: AppTypography.codeSmall.copyWith(
                    color: vColor,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              '+${virus.incomeBonus}T',
              style: AppTypography.codeSmall.copyWith(
                color: const Color(0xFFFFCC00),
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
