import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/fullscreen_helper.dart';
import '../../domain/models/match_state.dart';

/// Cabeçalho superior com Telemetria, Cronômetro, SLA e Integridade do Core.
class MatchHeaderWidget extends StatelessWidget {
  final MatchState state;
  final VoidCallback onUndoBuild;
  final VoidCallback onReadyPressed;

  const MatchHeaderWidget({
    super.key,
    required this.state,
    required this.onUndoBuild,
    required this.onReadyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: const Border(bottom: BorderSide(color: AppColors.borderGlow, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicador de Fase e Onda com Botão Voltar ao Hub
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Retornar ao Hub Tático',
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textSecondary),
                      onPressed: () => context.go('/hub'),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    _buildPhaseBadge(),
                    const SizedBox(width: 8),
                    Text(
                      'ONDA ${state.currentWave}/${state.totalWaves}',
                      style: AppTypography.codeMedium.copyWith(color: AppColors.blueTeam),
                    ),
                  ],
                ),
                // Cronômetro da Fase
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.cpuClock),
                      const SizedBox(width: 4),
                      Text(
                        '${state.remainingSeconds}s',
                        style: AppTypography.codeMedium.copyWith(
                          color: AppColors.cpuClock,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botão de Ação rápida da Fase (Desfazer ou Pronto) e Tela Cheia
                Row(
                  children: [
                    if (state.phase == MatchPhase.preparation) ...[
                      IconButton(
                        tooltip: 'Desfazer Última Construção',
                        icon: const Icon(Icons.undo_rounded, color: AppColors.textSecondary),
                        onPressed: onUndoBuild,
                        visualDensity: VisualDensity.compact,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          backgroundColor: AppColors.blueTeam,
                          foregroundColor: AppColors.background,
                        ),
                        onPressed: onReadyPressed,
                        child: const Text('PRONTO'),
                      ),
                    ] else ...[
                      const Icon(Icons.memory_rounded, size: 16, color: AppColors.cpuClock),
                      const SizedBox(width: 4),
                      Text(
                        '${state.cpuBudget} CPU',
                        style: AppTypography.codeSmall.copyWith(color: AppColors.cpuClock),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Alternar Tela Cheia (Fullscreen)',
                      icon: const Icon(Icons.fullscreen_rounded, size: 20, color: AppColors.textSecondary),
                      onPressed: FullscreenHelper.toggleFullscreen,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Medidores de SLA e Integridade do Core
            Row(
              children: [
                Expanded(
                  child: _buildMetricBar(
                    label: 'SLA DE NEGÓCIO',
                    value: state.slaPercentage,
                    color: state.slaPercentage > 70
                        ? AppColors.bandwidth
                        : (state.slaPercentage > 30 ? AppColors.cpuClock : AppColors.redTeam),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricBar(
                    label: 'LLM CORE INTEGRITY',
                    value: state.coreAiIntegrity,
                    color: AppColors.coreAi,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseBadge() {
    String text;
    Color color;

    switch (state.phase) {
      case MatchPhase.preparation:
        text = 'TURNO ZERO (BUILD)';
        color = AppColors.blueTeam;
        break;
      case MatchPhase.battle:
        text = 'COMBATE ATIVO';
        color = AppColors.redTeam;
        break;
      case MatchPhase.perkDraft:
        text = 'ESCOLHA DE PERK';
        color = AppColors.coreAi;
        break;
      case MatchPhase.victory:
        text = 'VITÓRIA';
        color = AppColors.bandwidth;
        break;
      case MatchPhase.defeat:
        text = 'DERROTA';
        color = AppColors.redTeam;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: AppTypography.codeSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildMetricBar({required String label, required double value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.codeSmall.copyWith(fontSize: 9)),
            Text('${value.toInt()}%',
                style: AppTypography.codeSmall.copyWith(fontSize: 10, color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (value / 100.0).clamp(0.0, 1.0),
            backgroundColor: AppColors.cardSurface,
            color: color,
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
