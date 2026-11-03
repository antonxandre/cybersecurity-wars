import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/bastion_node.dart';

/// Pop-up contextual tático posicionado diretamente sobre a unidade/célula na grade (estilo Legion TD / RTS).
/// Substitui o antigo bottom-dialog por uma sobreposição rica holográfica sobre o mapa.
class NodeContextPopup extends StatelessWidget {
  final int gridX;
  final int gridY;
  final int currentTokens;
  final BastionNode? existingNode;
  final bool isPrepPhase;
  final bool isAboveUnit;
  final double arrowOffset;
  final void Function(BastionNode node) onNodeSelected;
  final VoidCallback onNodeDismantled;
  final VoidCallback onClose;

  int get currentCpu => currentTokens;

  const NodeContextPopup({
    super.key,
    required this.gridX,
    required this.gridY,
    required this.currentTokens,
    required this.existingNode,
    required this.isPrepPhase,
    required this.isAboveUnit,
    required this.arrowOffset,
    required this.onNodeSelected,
    required this.onNodeDismantled,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = existingNode != null ? existingNode!.nodeColor : AppColors.blueTeam;

    final content = Container(
      width: 310,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: themeColor, width: 1.5),
        boxShadow: [
          ...AppColors.neonGlow(themeColor, blur: 16),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: existingNode != null
              ? _buildExistingNodeView(context, existingNode!)
              : _buildBlueprintListView(context),
        ),
      ),
    );

    // Indicador em seta apontando para a célula selecionada no mapa
    final arrowWidget = SizedBox(
      width: 310,
      height: 9,
      child: Stack(
        children: [
          Positioned(
            left: (arrowOffset - 8).clamp(16.0, 310.0 - 24.0),
            top: 0,
            child: CustomPaint(
              size: const Size(16, 9),
              painter: _PopupArrowPainter(
                color: AppColors.surface,
                borderColor: themeColor,
                isPointingDown: isAboveUnit,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: isAboveUnit
          ? [content, arrowWidget]
          : [arrowWidget, content],
    )
        .animate()
        .fadeIn(duration: 180.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          alignment: isAboveUnit ? Alignment.bottomCenter : Alignment.topCenter,
          duration: 180.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildExistingNodeView(BuildContext context, BastionNode node) {
    final integrityRatio = (node.currentIntegrity / node.maxIntegrity).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(node.icon, color: node.nodeColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  node.name.toUpperCase(),
                  style: AppTypography.displaySmall.copyWith(
                    fontSize: 13.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.zero,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          node.description,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        // Barra de Integridade Visual
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INTEGRIDADE DO NÓ',
                  style: AppTypography.codeSmall.copyWith(fontSize: 11.0),
                ),
                Text(
                  '${node.currentIntegrity.toInt()} / ${node.maxIntegrity.toInt()} HP',
                  style: AppTypography.codeSmall.copyWith(
                    fontSize: 11.5,
                    color: node.nodeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: LinearProgressIndicator(
                value: integrityRatio,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  integrityRatio > 0.5
                      ? AppColors.bandwidth
                      : (integrityRatio > 0.25 ? AppColors.cpuClock : AppColors.redTeam),
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Métricas de Dano, Alcance e Nível
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricTile(
              label: 'PODER DE FOGO',
              value: '${node.attackDamage.toInt()} DPS',
              color: AppColors.redTeam,
              icon: Icons.flash_on_rounded,
            ),
            Container(width: 1, height: 28, color: AppColors.border),
            _buildMetricTile(
              label: 'ALCANCE RADIAL',
              value: '${node.attackRange.toInt()} px',
              color: AppColors.blueTeam,
              icon: Icons.radar_rounded,
            ),
            Container(width: 1, height: 28, color: AppColors.border),
            _buildMetricTile(
              label: 'NÍVEL',
              value: 'Lv.${node.level} / 3',
              color: const Color(0xFFFFCC00),
              icon: Icons.military_tech_rounded,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Efeito Ativo do Nível
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: node.nodeColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EFEITO ATUAL (NÍVEL ${node.level}):',
                style: AppTypography.codeSmall.copyWith(
                  fontSize: 10.5,
                  color: node.nodeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                node.currentEffectDescription,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Ação: Desmontar Nó (somente na fase de preparação)
        if (isPrepPhase)
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.redTeam,
                side: const BorderSide(color: AppColors.redTeam, width: 1.2),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: onNodeDismantled,
              icon: const Icon(Icons.delete_sweep_rounded, size: 16),
              label: Text(
                'DESMONTAR (+${node.tokenCost} TOKENS REEMBOLSO)',
                style: AppTypography.codeSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'MODIFICAÇÕES BLOQUEADAS DURANTE COMBATE',
                style: AppTypography.codeSmall.copyWith(
                  fontSize: 11.0,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBlueprintListView(BuildContext context) {
    if (!isPrepPhase) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.zero,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.lock_clock_rounded, color: AppColors.cpuClock, size: 26),
            const SizedBox(height: 6),
            Text(
              'COMBATE ATIVO EM ANDAMENTO',
              style: AppTypography.codeMedium.copyWith(
                color: AppColors.cpuClock,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aguarde a próxima onda para alocar novas defesas.',
              style: AppTypography.bodySmall.copyWith(fontSize: 11.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final blueprints = BastionNode.blueprints(gridX, gridY);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppColors.blueTeam),
                const SizedBox(width: 6),
                Text(
                  'ALOCAR DEFESA BASTIÃO:',
                  style: AppTypography.codeSmall.copyWith(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.zero,
              child: Container(
                padding: const EdgeInsets.all(2),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Column(
              children: blueprints.map((bp) {
                final canAfford = currentTokens >= bp.tokenCost;
                return _buildCompactBlueprintTile(context, bp, canAfford);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBlueprintTile(BuildContext context, BastionNode bp, bool canAfford) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: canAfford ? AppColors.cardSurface : AppColors.cardSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: canAfford ? bp.nodeColor.withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.zero,
          onTap: canAfford
              ? () {
                  final instance = bp.copyWith(
                    id: 'node_${bp.type.name}_${DateTime.now().millisecondsSinceEpoch}',
                  );
                  onNodeSelected(instance);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                // Ícone do Nó
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: bp.nodeColor.withValues(alpha: canAfford ? 0.15 : 0.05),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: canAfford ? bp.nodeColor : AppColors.textMuted,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    bp.icon,
                    color: canAfford ? bp.nodeColor : AppColors.textMuted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                // Nome & Atributos Compactos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bp.name,
                            style: AppTypography.displaySmall.copyWith(
                              fontSize: 12.5,
                              color: canAfford ? AppColors.textPrimary : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Custo de Tokens
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(
                                color: canAfford ? const Color(0xFFFFCC00) : AppColors.textMuted,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🪙', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 3),
                                Text(
                                  '${bp.tokenCost}',
                                  style: AppTypography.codeSmall.copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: canAfford ? const Color(0xFFFFCC00) : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'HP ${bp.maxIntegrity.toInt()} • DPS ${bp.attackDamage.toInt()} • ${bp.attackRange.toInt()}px',
                        style: AppTypography.codeSmall.copyWith(
                          fontSize: 10.5,
                          color: canAfford ? AppColors.textSecondary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.codeSmall.copyWith(
                fontSize: 12.0,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.codeSmall.copyWith(
            fontSize: 10.0,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Desenha o triângulo da seta indicadora conectando o pop-up à célula no mapa.
class _PopupArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isPointingDown;

  _PopupArrowPainter({
    required this.color,
    required this.borderColor,
    required this.isPointingDown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (isPointingDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PopupArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isPointingDown != isPointingDown;
  }
}
