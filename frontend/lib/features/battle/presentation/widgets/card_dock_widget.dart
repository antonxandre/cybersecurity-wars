import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/game_card.dart';

/// Dock inferior com a mão de 4 cartas estilo Clash Royale.
class CardDockWidget extends StatelessWidget {
  final List<GameCard> hand;
  final double currentBandwidth;
  final void Function(GameCard card, int lane) onCardPlay;

  const CardDockWidget({
    super.key,
    required this.hand,
    required this.currentBandwidth,
    required this.onCardPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.borderGlow, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: hand.map((card) {
            final canAfford = currentBandwidth >= card.bandwidthCost;
            return _buildCardItem(context, card, canAfford);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, GameCard card, bool canAfford) {
    return GestureDetector(
      onTap: canAfford
          ? () {
              _showLaneSelection(context, card);
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: canAfford ? 1.0 : 0.45,
        child: Container(
          width: 78,
          height: 108,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: canAfford ? card.rarityColor : AppColors.border,
              width: canAfford ? 1.8 : 1.0,
            ),
            boxShadow: canAfford
                ? AppColors.neonGlow(card.rarityColor, blur: 8, spread: 0.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Custo de Banda (Badge)
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.bandwidth),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 10, color: AppColors.bandwidth),
                      Text(
                        '${card.bandwidthCost}',
                        style: AppTypography.codeSmall.copyWith(
                          color: AppColors.bandwidth,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Ícone da Carta
              Icon(
                card.icon,
                size: 28,
                color: canAfford ? card.rarityColor : AppColors.textMuted,
              ),
              // Nome da Carta
              Text(
                card.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: canAfford ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLaneSelection(BuildContext context, GameCard card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Despachar ${card.name} (${card.bandwidthCost} Banda)',
                style: AppTypography.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha a rota de rede de destino:',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardSurface,
                        side: const BorderSide(color: AppColors.blueTeam),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onCardPlay(card, 0); // Lane 0
                      },
                      icon: const Icon(Icons.arrow_upward_rounded, color: AppColors.blueTeam),
                      label: const Text('Rota 1 (Uplink)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardSurface,
                        side: const BorderSide(color: AppColors.redTeam),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onCardPlay(card, 1); // Lane 1
                      },
                      icon: const Icon(Icons.arrow_downward_rounded, color: AppColors.redTeam),
                      label: const Text('Rota 2 (Downlink)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
