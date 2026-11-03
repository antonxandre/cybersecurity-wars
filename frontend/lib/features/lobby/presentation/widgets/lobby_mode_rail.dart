import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/lobby_models.dart';

/// Barra de navegação lateral (ou horizontal em mobile) para seleção de modo de jogo.
class LobbyModeRail extends StatelessWidget {
  final LobbyMode currentMode;
  final ValueChanged<LobbyMode> onModeSelected;
  final bool isHorizontal;

  const LobbyModeRail({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderGlow),
        ),
        child: Row(
          children: LobbyMode.values.map((mode) {
            final isSelected = currentMode == mode;
            return Expanded(
              child: _buildItem(
                mode: mode,
                isSelected: isSelected,
                isHorizontal: true,
              ),
            );
          }).toList(),
        ),
      );
    }

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: LobbyMode.values.map((mode) {
          final isSelected = currentMode == mode;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildItem(
              mode: mode,
              isSelected: isSelected,
              isHorizontal: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItem({
    required LobbyMode mode,
    required bool isSelected,
    required bool isHorizontal,
  }) {
    return _ModeRailItem(
      mode: mode,
      isSelected: isSelected,
      isHorizontal: isHorizontal,
      onTap: () => onModeSelected(mode),
    );
  }
}

class _ModeRailItem extends StatefulWidget {
  final LobbyMode mode;
  final bool isSelected;
  final bool isHorizontal;
  final VoidCallback onTap;

  const _ModeRailItem({
    required this.mode,
    required this.isSelected,
    required this.isHorizontal,
    required this.onTap,
  });

  @override
  State<_ModeRailItem> createState() => _ModeRailItemState();
}

class _ModeRailItemState extends State<_ModeRailItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.mode.accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: widget.isHorizontal ? 10 : 16,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? color.withValues(alpha: 0.16)
                : (_isHovered ? AppColors.cardSurface : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? color.withValues(alpha: 0.8)
                  : (_isHovered ? AppColors.borderGlow : Colors.transparent),
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: widget.isSelected || _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.mode.icon,
                  size: 26,
                  color: widget.isSelected
                      ? color
                      : (_isHovered ? Colors.white : AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.mode.shortLabel,
                textAlign: TextAlign.center,
                style: AppTypography.codeSmall.copyWith(
                  fontSize: 10,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  color: widget.isSelected
                      ? Colors.white
                      : (_isHovered ? AppColors.textPrimary : AppColors.textMuted),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
