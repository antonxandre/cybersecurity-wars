import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/fullscreen_helper.dart';
import '../../domain/models/match_state.dart';
import 'mainframe_health_bar.dart';

/// Cabeçalho superior estilo Placar MOBA / Esports:
/// Mainframe Aliado (Esquerda), Timer Central com Ondas, Mainframe Rival (Direita) e Ações de Fase.
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
    final isLowTime = state.remainingSeconds <= 10 && state.phase == MatchPhase.preparation;
    final isBattlePhase = state.phase == MatchPhase.battle;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.zero,
              border: Border(
                bottom: BorderSide(color: AppColors.borderGlow, width: 1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Linha Superior de Controles de Navegação e Ações Rápidas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Canto Esquerdo: Voltar ao Lobby & Identificação da Sala
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Retornar ao Lobby',
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => context.go('/lobby'),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, size: 14, color: AppColors.blueTeam),
                                const SizedBox(width: 6),
                                Text(
                                  'PROMPTSEC ARENA (4v4)',
                                  style: AppTypography.codeSmall.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Canto Direito: Ações da Fase (Desfazer / Pronto) + Configurações
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.phase == MatchPhase.preparation) ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                backgroundColor: AppColors.cardSurface,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: onUndoBuild,
                              icon: const Icon(Icons.undo_rounded, size: 16, color: AppColors.textSecondary),
                              label: Text(
                                'DESFAZER',
                                style: AppTypography.codeSmall.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blueTeam,
                                foregroundColor: AppColors.background,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                visualDensity: VisualDensity.compact,
                                elevation: 4,
                                shadowColor: AppColors.blueTeamGlow,
                              ),
                              onPressed: onReadyPressed,
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: Text(
                                'PRONTO',
                                style: AppTypography.codeSmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: AppColors.background,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          const IconButton(
                            tooltip: 'Alternar Tela Cheia',
                            icon: Icon(
                              Icons.fullscreen_rounded,
                              size: 19,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: FullscreenHelper.toggleFullscreen,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.all(6),
                            constraints: BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Configurações de Áudio e Gráficos',
                            icon: const Icon(
                              Icons.settings_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => context.push('/settings'),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Linha Principal do Placar MOBA (Mainframe Azul | Timer & Onda | Mainframe Vermelho)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Barra de Integridade do Mainframe Aliado
                      Expanded(
                        child: MainframeHealthBar(
                          label: 'MAINFRAME ALIADO',
                          currentHp: state.mainframeBlue.currentHp,
                          maxHp: state.mainframeBlue.maxHp,
                          hpPercent: state.mainframeBlue.hpPercentage,
                          primaryColor: AppColors.blueTeam,
                          isReversed: false,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // 2. Núcleo Central: Timer Hexagonal / Retangular e Indicador de Onda
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: isLowTime
                                ? AppColors.redTeam
                                : (isBattlePhase ? AppColors.redTeamSecondary : AppColors.borderGlow),
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isLowTime)
                              BoxShadow(
                                color: AppColors.redTeam.withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: isLowTime ? AppColors.redTeam : AppColors.cpuClock,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${state.remainingSeconds}s',
                                  style: AppTypography.codeMedium.copyWith(
                                    color: isLowTime ? AppColors.redTeam : AppColors.cpuClock,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ONDA ${state.currentWave}/${state.totalWaves}',
                                  style: AppTypography.codeSmall.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _buildMiniPhaseDot(state.phase),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // 3. Barra de Integridade do Mainframe Adversário (Espelhada)
                      Expanded(
                        child: MainframeHealthBar(
                          label: 'MAINFRAME RIVAL',
                          currentHp: state.mainframeRed.currentHp,
                          maxHp: state.mainframeRed.maxHp,
                          hpPercent: state.mainframeRed.hpPercentage,
                          primaryColor: AppColors.redTeam,
                          isReversed: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPhaseDot(MatchPhase phase) {
    Color dotColor;
    String phaseLabel;
    switch (phase) {
      case MatchPhase.preparation:
        dotColor = AppColors.blueTeam;
        phaseLabel = 'BUILD';
        break;
      case MatchPhase.battle:
        dotColor = AppColors.redTeam;
        phaseLabel = 'COMBATE';
        break;
      case MatchPhase.victory:
        dotColor = AppColors.bandwidth;
        phaseLabel = 'VITÓRIA';
        break;
      case MatchPhase.defeat:
        dotColor = AppColors.redTeam;
        phaseLabel = 'DERROTA';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: dotColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: dotColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        phaseLabel,
        style: AppTypography.codeSmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: dotColor,
        ),
      ),
    );
  }
}
