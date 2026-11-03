import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/match_state.dart';

/// Overlay de Fim de Jogo (Vitória ou Derrota) com Relatório Tático e Retorno ao Lobby.
class MatchResultOverlay extends StatelessWidget {
  final MatchState state;
  final VoidCallback? onBackToLobby;

  const MatchResultOverlay({
    super.key,
    required this.state,
    this.onBackToLobby,
  });

  bool get isVictory => state.phase == MatchPhase.victory;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isVictory ? AppColors.bandwidth : AppColors.redTeam;
    final title = isVictory ? 'FORTALEZA DEFENDIDA!' : 'SISTEMA COMPROMETIDO!';
    final subtitle = isVictory
        ? 'Todas as 3 ondas de ataque foram neutralizadas com sucesso.'
        : 'A integridade do Mainframe foi comprometida por ataques adversários.';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.zero,
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
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.zero,
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
                        label: 'TOTAL DE VAZAMENTOS (LEAKS)',
                        value: '${state.totalLeaks}',
                        color: state.totalLeaks > 0 ? AppColors.redTeam : AppColors.bandwidth,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // Botão de Retorno ao Lobby (Única ação disponível)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: AppColors.background,
                      elevation: 8,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {
                      if (onBackToLobby != null) {
                        onBackToLobby!();
                      } else {
                        context.go('/lobby');
                      }
                    },
                    icon: const Icon(Icons.meeting_room_rounded),
                    label: Text(
                      'VOLTAR PARA O LOBBY',
                      style: AppTypography.codeMedium.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
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
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.codeSmall.copyWith(fontSize: 11.5)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.codeLarge.copyWith(color: color, fontSize: 18.0),
          ),
        ],
      ),
    );
  }
}
