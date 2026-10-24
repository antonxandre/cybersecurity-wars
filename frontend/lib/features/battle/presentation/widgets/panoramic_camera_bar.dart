import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Barra de navegação rápida de câmera para o mapa panorâmico (2 campos + túneis).
class PanoramicCameraBar extends StatelessWidget {
  final VoidCallback onFocusMyGrid;
  final VoidCallback onFocusOverview;
  final VoidCallback onFocusOpponent;
  final VoidCallback onFocusMainframe;

  const PanoramicCameraBar({
    super.key,
    required this.onFocusMyGrid,
    required this.onFocusOverview,
    required this.onFocusOpponent,
    required this.onFocusMainframe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnchorButton(
            label: 'MEU GRID',
            icon: Icons.shield_rounded,
            color: AppColors.blueTeam,
            onTap: onFocusMyGrid,
          ),
          const SizedBox(width: 6),
          _buildAnchorButton(
            label: 'VISÃO GERAL',
            icon: Icons.pan_tool_alt_rounded,
            color: AppColors.coreAi,
            onTap: onFocusOverview,
          ),
          const SizedBox(width: 6),
          _buildAnchorButton(
            label: 'OPONENTE',
            icon: Icons.flash_on_rounded,
            color: AppColors.redTeam,
            onTap: onFocusOpponent,
          ),
          const SizedBox(width: 6),
          _buildAnchorButton(
            label: 'MAINFRAME',
            icon: Icons.memory_rounded,
            color: AppColors.cpuClock,
            onTap: onFocusMainframe,
          ),
        ],
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.codeSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
