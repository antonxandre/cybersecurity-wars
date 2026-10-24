import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/bastion_node.dart';

/// Folha modal para compra e alocação de nós na grade (estilo Legion TD).
class NodeSelectionSheet extends StatelessWidget {
  final int gridX;
  final int gridY;
  final int currentCpu;
  final BastionNode? existingNode;
  final void Function(BastionNode node) onNodeSelected;
  final VoidCallback onNodeDismantled;

  const NodeSelectionSheet({
    super.key,
    required this.gridX,
    required this.gridY,
    required this.currentCpu,
    this.existingNode,
    required this.onNodeSelected,
    required this.onNodeDismantled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderGlow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da Célula
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.blueTeam),
                      ),
                      child: const Icon(Icons.grid_on_rounded, color: AppColors.blueTeam, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CÉLULA DE REDE ($gridX, $gridY)',
                          style: AppTypography.displaySmall.copyWith(fontSize: 15),
                        ),
                        Text(
                          existingNode == null ? 'Célula Disponível' : 'Nó Ativo Alocado',
                          style: AppTypography.bodySmall.copyWith(
                            color: existingNode == null ? AppColors.bandwidth : AppColors.cpuClock,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Saldo de CPU Disponível
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cpuClock),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.memory_rounded, size: 14, color: AppColors.cpuClock),
                      const SizedBox(width: 4),
                      Text(
                        '$currentCpu CPU',
                        style: AppTypography.codeMedium.copyWith(color: AppColors.cpuClock),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),

            // Caso já exista um nó alocado na célula
            if (existingNode != null) ...[
              _buildExistingNodeView(context, existingNode!),
            ] else ...[
              // Lista de Blueprints para compra
              Text('SELECIONE O NÓ DE DEFESA:', style: AppTypography.codeSmall),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: BastionNode.blueprints(gridX, gridY).map((bp) {
                      final canAfford = currentCpu >= bp.cpuCost;
                      return _buildBlueprintCard(context, bp, canAfford);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExistingNodeView(BuildContext context, BastionNode node) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: node.nodeColor, width: 1.5),
        boxShadow: AppColors.neonGlow(node.nodeColor, blur: 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(node.icon, color: node.nodeColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.name, style: AppTypography.displaySmall.copyWith(fontSize: 16)),
                    Text(node.description, style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Métricas do nó
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricChip(
                'INTEGRIDADE',
                '${node.currentIntegrity.toInt()}/${node.maxIntegrity.toInt()}',
                AppColors.bandwidth,
              ),
              _buildMetricChip(
                'PODER',
                '${node.attackDamage.toInt()} DPS',
                AppColors.redTeam,
              ),
              _buildMetricChip(
                'ALCANCE',
                '${node.attackRange.toInt()}px',
                AppColors.blueTeam,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Botão Desmontar Nó com Reembolso de CPU
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.redTeam,
                side: const BorderSide(color: AppColors.redTeam),
              ),
              onPressed: () {
                Navigator.pop(context);
                onNodeDismantled();
              },
              icon: const Icon(Icons.delete_sweep_rounded),
              label: Text('DESMONTAR NÓ (+${node.cpuCost} CPU REEMBOLSADOS)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintCard(BuildContext context, BastionNode bp, bool canAfford) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford ? bp.nodeColor.withOpacity(0.7) : AppColors.border,
          width: canAfford ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canAfford
              ? () {
                  Navigator.pop(context);
                  // Gera ID único para o nó
                  final instance = bp.copyWith(
                    id: 'node_${bp.type.name}_${DateTime.now().millisecondsSinceEpoch}',
                  );
                  onNodeSelected(instance);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Ícone do Nó
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bp.nodeColor.withOpacity(canAfford ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: canAfford ? bp.nodeColor : AppColors.textMuted,
                    ),
                  ),
                  child: Icon(
                    bp.icon,
                    color: canAfford ? bp.nodeColor : AppColors.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Informações e Descrição
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bp.name,
                            style: AppTypography.displaySmall.copyWith(
                              fontSize: 14,
                              color: canAfford ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                          ),
                          // Custo em CPU
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: canAfford ? AppColors.cpuClock : AppColors.textMuted,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.memory_rounded,
                                  size: 11,
                                  color: canAfford ? AppColors.cpuClock : AppColors.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${bp.cpuCost}',
                                  style: AppTypography.codeSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: canAfford ? AppColors.cpuClock : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bp.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: canAfford ? AppColors.textSecondary : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'HP: ${bp.maxIntegrity.toInt()}  •  DPS: ${bp.attackDamage.toInt()}  •  Alcance: ${bp.attackRange.toInt()}px',
                        style: AppTypography.codeSmall.copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.codeSmall.copyWith(fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.codeMedium.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
