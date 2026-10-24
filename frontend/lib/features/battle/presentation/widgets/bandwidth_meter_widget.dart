import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Barra de Banda de Rede / Energia em tempo real (estilo Clash Royale).
class BandwidthMeterWidget extends StatelessWidget {
  final double bandwidth;
  final double maxBandwidth;

  const BandwidthMeterWidget({
    super.key,
    required this.bandwidth,
    this.maxBandwidth = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (bandwidth / maxBandwidth).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone e Contador de Banda
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.bandwidth, size: 20),
              const SizedBox(width: 4),
              Text(
                bandwidth.toStringAsFixed(1),
                style: AppTypography.codeLarge.copyWith(color: AppColors.bandwidth),
              ),
              Text(
                ' / ${maxBandwidth.toInt()}',
                style: AppTypography.codeSmall,
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Barra de Progresso Fluida com Divisões de 10 segmentos
          Expanded(
            child: Stack(
              children: [
                // Fundo da barra
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                // Preenchimento gradiente com brilho neon
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: AppColors.bandwidthGradient,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: AppColors.neonGlow(AppColors.bandwidth, blur: 6),
                    ),
                  ),
                ),
                // Linhas divisórias para cada 1 ponto de energia
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    maxBandwidth.toInt() - 1,
                    (index) => Container(
                      width: 1,
                      height: 14,
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
