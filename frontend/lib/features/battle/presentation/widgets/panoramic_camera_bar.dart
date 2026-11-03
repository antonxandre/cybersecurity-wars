import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/team_player_model.dart';

/// Barra de navegação rápida de câmera para o mapa do Tabuleiro Top-Down 4v4.
class PanoramicCameraBar extends StatelessWidget {
  final VoidCallback onFocusOverview;
  final VoidCallback onFocusMyGrid;
  final void Function(BoardQuadrant quadrant)? onFocusQuadrant;
  final VoidCallback onFocusOpponent;
  final VoidCallback onFocusMainframe;

  const PanoramicCameraBar({
    super.key,
    required this.onFocusOverview,
    required this.onFocusMyGrid,
    this.onFocusQuadrant,
    required this.onFocusOpponent,
    required this.onFocusMainframe,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.borderGlow, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAnchorButton(
                    label: 'GERAL',
                    icon: Icons.grid_view_rounded,
                    color: AppColors.blueTeam,
                    onTap: onFocusOverview,
                  ),
                  const SizedBox(width: 4),
                  _buildAnchorButton(
                    label: 'J1 (VOCÊ)',
                    icon: Icons.shield_rounded,
                    color: AppColors.blueTeam,
                    onTap: onFocusMyGrid,
                  ),
                  const SizedBox(width: 4),
                  _buildAnchorButton(
                    label: 'J2',
                    icon: Icons.security_rounded,
                    color: AppColors.coreAi,
                    onTap: () => onFocusQuadrant?.call(BoardQuadrant.bottomLeft),
                  ),
                  const SizedBox(width: 4),
                  _buildAnchorButton(
                    label: 'J3',
                    icon: Icons.radar_rounded,
                    color: AppColors.bandwidth,
                    onTap: () => onFocusQuadrant?.call(BoardQuadrant.topRight),
                  ),
                  const SizedBox(width: 4),
                  _buildAnchorButton(
                    label: 'J4',
                    icon: Icons.terminal_rounded,
                    color: AppColors.cpuClock,
                    onTap: () => onFocusQuadrant?.call(BoardQuadrant.bottomRight),
                  ),
                  const SizedBox(width: 4),
                  _buildAnchorButton(
                    label: 'MAINFRAME',
                    icon: Icons.memory_rounded,
                    color: AppColors.cpuClock,
                    onTap: onFocusMainframe,
                  ),
                  const SizedBox(width: 4),
                  _buildAnchorButton(
                    label: 'RIVAL',
                    icon: Icons.lock_outline_rounded,
                    color: AppColors.redTeam,
                    onTap: onFocusOpponent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnchorButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.codeSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
