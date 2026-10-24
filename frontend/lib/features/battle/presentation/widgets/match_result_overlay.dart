import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/match_state.dart';

/// Overlay de Fim de Jogo (Vitória ou Derrota) com Relatório Tático e Botão Reiniciar.
class MatchResultOverlay extends StatelessWidget {
  final MatchState state;
  final VoidCallback onPlayAgain;

  const MatchResultOverlay({
    super.key,
    required this.state,
    required this.onPlayAgain,
  });

  bool get isVictory => state.phase == MatchPhase.victory;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isVictory ? AppColors.bandwidth : AppColors.redTeam;
    final title = isVictory ? 'FORTALEZA DEFENDIDA!' : 'SISTEMA COMPROMETIDO!';
    final subtitle = isVictory
        ? 'Todas as 3 ondas de ataque foram neutralizadas com sucesso.'
        : (state.coreAiIntegrity <= 0
            ? 'O LLM Core foi corrompido por injeções de exploit.'
            : 'O SLA de negócio chegou a 0% devido a falhas de disponibilidade.');

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withOpacity(0.75),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor, width: 2),
              boxShadow: AppColors.neonGlow(primaryColor, blur: 24, spread: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone de Desfecho
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 2),
                  ),
                  child: Icon(
                    isVictory ? Icons.emoji_events_rounded : Icons.gpp_bad_rounded,
                    color: primaryColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                // Título
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.displayMedium.copyWith(color: primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                // Grid de Estatísticas Táticas da Partida
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        label: 'DURAÇÃO',
                        value: '${state.statsDurationSeconds}s',
                        color: AppColors.cpuClock,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        label: 'AMEAÇAS EXPURGADAS',
                        value: '${state.statsPacketsNeutralized}',
                        color: AppColors.bandwidth,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        label: 'LLM CORE FINAL',
                        value: '${state.coreAiIntegrity.toInt()}%',
                        color: AppColors.coreAi,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        label: 'SLA DE NEGÓCIO',
                        value: '${state.slaPercentage.toInt()}%',
                        color: state.slaPercentage > 50 ? AppColors.bandwidth : AppColors.redTeam,
                      ),
                    ),
                  ],
                ),

                // Lista de Perks Acumulados
                if (state.activePerks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('PERKS ATIVADOS:', style: AppTypography.codeSmall),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: state.activePerks.map((p) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: p.categoryColor, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(p.icon, size: 12, color: p.categoryColor),
                            const SizedBox(width: 4),
                            Text(
                              p.name,
                              style: AppTypography.codeSmall.copyWith(fontSize: 10, color: p.categoryColor),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 24),
                // Botões de Ação Final
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => context.go('/hub'),
                          icon: const Icon(Icons.hub_rounded, size: 16),
                          label: Text('HUB', style: AppTypography.codeSmall),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: AppColors.background,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onPlayAgain,
                          icon: const Icon(Icons.replay_rounded),
                          label: Text(
                            'JOGAR NOVAMENTE',
                            style: AppTypography.codeMedium.copyWith(
                              color: AppColors.background,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.codeSmall.copyWith(fontSize: 9)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.codeLarge.copyWith(color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
