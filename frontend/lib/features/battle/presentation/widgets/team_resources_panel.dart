import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/team_player_model.dart';

/// Painel de Telemetria e Recursos dos Aliados (Estilo RTS Warcraft 3).
/// Exibe informações em tempo real dos 4 jogadores aliados: Tokens, Bits, mineradores e status da wave.
class TeamResourcesPanel extends StatefulWidget {
  final List<TeamPlayerModel> players;
  final void Function(BoardQuadrant quadrant)? onFocusSector;

  const TeamResourcesPanel({
    super.key,
    required this.players,
    this.onFocusSector,
  });

  @override
  State<TeamResourcesPanel> createState() => _TeamResourcesPanelState();
}

class _TeamResourcesPanelState extends State<TeamResourcesPanel> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final players = widget.players.isNotEmpty
        ? widget.players
        : TeamPlayerModel.initialBlueTeam();

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isCollapsed ? 44 : 310,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.borderGlow, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: 310,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabeçalho do Painel com Botão de Recolher
                    InkWell(
                      onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                      borderRadius: BorderRadius.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded,
                                size: 18, color: AppColors.blueTeam),
                            if (!_isCollapsed) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ALIADOS DA REDE',
                                  style: AppTypography.codeSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.blueTeam
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Text(
                                  '4v4',
                                  style: AppTypography.codeSmall.copyWith(
                                    color: AppColors.blueTeam,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            Icon(
                              _isCollapsed
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_isCollapsed) ...[
                      const Divider(height: 1, color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: players
                              .map((player) => _buildPlayerCard(player))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(TeamPlayerModel player) {
    final statusColor = player.waveStatus.statusColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => widget.onFocusSector?.call(player.quadrant),
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: player.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.zero,
            border: Border.all(
                color: player.color.withValues(alpha: 0.35), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha Superior: Nome, Quadrante e Status
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: player.color,
                      shape: BoxShape.rectangle,
                      boxShadow: [
                        BoxShadow(
                          color: player.color.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      player.name,
                      style: AppTypography.codeSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                          width: 0.8),
                    ),
                    child: Text(
                      player.waveStatus.label,
                      style: AppTypography.codeSmall.copyWith(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Linha Inferior: Tokens, Bits e Mineradores
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildResourceMetric(
                    Icons.toll_rounded,
                    '${player.tokens}T',
                    AppColors.cpuClock,
                  ),
                  _buildResourceMetric(
                    Icons.bolt_rounded,
                    '${player.bits}b',
                    AppColors.blueTeam,
                  ),
                  _buildResourceMetric(
                    Icons.precision_manufacturing_rounded,
                    '${player.minersCount} Min',
                    AppColors.bandwidth,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceMetric(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTypography.codeSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}
