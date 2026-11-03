import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tactical_unit_info.dart';

/// HUD contextual padronizada para exibição de status e atributos atuais de qualquer unidade
/// (Mainframe Central, Bastiões Defensivos, Malwares e Tráfego de Rede) com painel integrado de melhorias.
class TacticalUnitInfoHud extends StatelessWidget {
  final TacticalUnitInfo info;
  final bool isAboveUnit;
  final double arrowOffset;
  final VoidCallback onClose;

  const TacticalUnitInfoHud({
    super.key,
    required this.info,
    this.isAboveUnit = true,
    this.arrowOffset = 170.0,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = info.themeColor;
    final integrityRatio = (info.currentIntegrity / (info.totalIntegrity > 0 ? info.totalIntegrity : 1.0)).clamp(0.0, 1.0);

    final hpBarColor = integrityRatio > 0.5
        ? AppColors.bandwidth
        : (integrityRatio > 0.25 ? AppColors.cpuClock : AppColors.redTeam);

    const hudWidth = 340.0;

    final content = Container(
      width: hudWidth,
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.of(context).size.height - 40).clamp(300.0, 700.0),
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabeçalho Holográfico
            _buildHeader(themeColor),

            const Divider(color: AppColors.border, height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 2. Descrição Tática
                  Text(
                    info.description,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 3. Barra de Integridade Dinâmica
                  _buildHealthBar(integrityRatio, hpBarColor),

                  const SizedBox(height: 12),

                  // 4. Grade de Atributos Chave
                  _buildAttributesGrid(themeColor),

                  // 5. Card de Efeito Atual e Habilidade Especial (Lv 3)
                  if (info.currentEffect != null || info.specialAbilityTitle != null)
                    _buildLevelAndAbilitiesCard(themeColor),

                  // 6. Painel Integrado de Upgrades de Habilidades / Hardware
                  if (info.upgrades.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildUpgradesPanel(themeColor),
                  ],

                  // 7. Botão de Ação Rápida (se configurado para a unidade)
                  if (info.onPrimaryAction != null && info.primaryActionLabel != null) ...[
                    const SizedBox(height: 12),
                    _buildPrimaryActionButton(themeColor),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

    // Seta holográfica apontando para a unidade no canvas
    final arrowWidget = SizedBox(
      width: hudWidth,
      height: 9,
      child: Stack(
        children: [
          Positioned(
            left: (arrowOffset - 8).clamp(16.0, hudWidth - 24.0),
            top: 0,
            child: CustomPaint(
              size: const Size(16, 9),
              painter: _HudArrowPainter(
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
      children: isAboveUnit ? [content, arrowWidget] : [arrowWidget, content],
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

  Widget _buildHeader(Color themeColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: themeColor.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Ícone Estilizado
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: themeColor, width: 1),
            ),
            child: Icon(
              info.icon,
              color: themeColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),

          // Título e Subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info.title,
                  style: AppTypography.displaySmall.copyWith(
                    fontSize: 13.5,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        info.subtitle,
                        style: AppTypography.codeSmall.copyWith(
                          fontSize: 11.5,
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: info.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: info.statusColor.withValues(alpha: 0.6), width: 0.8),
                      ),
                      child: Text(
                        info.statusText,
                        style: TextStyle(
                          color: info.statusColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botão Fechar
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.zero,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(double ratio, Color hpColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'INTEGRIDADE',
                style: AppTypography.codeSmall.copyWith(
                  fontSize: 11.0,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${info.currentIntegrity.toInt()} / ${info.totalIntegrity.toInt()} HP (${info.hpPercentage.toInt()}%)',
              style: AppTypography.codeSmall.copyWith(
                fontSize: 11.5,
                color: hpColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(hpColor),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesGrid(Color themeColor) {
    if (info.attributes.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: info.attributes.map((attr) {
        final attrColor = attr.color ?? themeColor;
        return Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(attr.icon, size: 16, color: attrColor),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attr.label,
                      style: AppTypography.codeSmall.copyWith(
                        fontSize: 10.0,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      attr.value,
                      style: AppTypography.codeMedium.copyWith(
                        fontSize: 12.0,
                        color: attrColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Card holográfico com a descrição do Efeito Ativo do Nível atual e a Habilidade Especial (Lv 3)
  Widget _buildLevelAndAbilitiesCard(Color themeColor) {
    final isLv3 = info.isSpecialUnlocked || (info.currentLevel != null && info.currentLevel! >= 3);
    final levelStars = info.currentLevel == 1
        ? '★☆☆'
        : (info.currentLevel == 2 ? '★★☆' : '★★★');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: isLv3 ? const Color(0xFFFFCC00) : themeColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: isLv3 ? AppColors.neonGlow(const Color(0xFFFFCC00), blur: 8, spread: 0.1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nível e Efeito Ativo
          if (info.currentEffect != null) ...[
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 15,
                  color: themeColor,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'EFEITO ATUAL (NÍVEL ${info.currentLevel ?? 1} $levelStars):',
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 11.0,
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              info.currentEffect!,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12.0,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
          ],

          // Habilidade Especial do Nível 3
          if (info.specialAbilityTitle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLv3
                    ? const Color(0xFFFFCC00).withValues(alpha: 0.12)
                    : AppColors.background.withValues(alpha: 0.7),
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: isLv3
                      ? const Color(0xFFFFCC00).withValues(alpha: 0.8)
                      : AppColors.border,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLv3 ? Icons.stars_rounded : Icons.lock_outline_rounded,
                        size: 15,
                        color: isLv3 ? const Color(0xFFFFCC00) : AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'HABILIDADE ESPECIAL (LV. 3): ${info.specialAbilityTitle!}',
                          style: AppTypography.codeSmall.copyWith(
                            fontSize: 11.0,
                            color: isLv3 ? const Color(0xFFFFCC00) : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isLv3
                              ? const Color(0xFFFFCC00).withValues(alpha: 0.2)
                              : Colors.black26,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: isLv3 ? const Color(0xFFFFCC00) : AppColors.textMuted,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isLv3 ? 'DESBLOQUEADO ★★★' : 'REQUER LV. 3',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: isLv3 ? const Color(0xFFFFCC00) : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.specialAbilityDescription ?? '',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: isLv3 ? AppColors.textPrimary : AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Painel de upgrades de habilidades/hardware embutido diretamente na HUD
  Widget _buildUpgradesPanel(Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tune_rounded, size: 15, color: Color(0xFFFFCC00)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'MELHORIAS DE HABILIDADES // HARDWARE',
                style: AppTypography.codeSmall.copyWith(
                  fontSize: 11.0,
                  color: const Color(0xFFFFCC00),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...info.upgrades.map((upgrade) => _buildUpgradeCard(upgrade, themeColor)),
      ],
    );
  }

  Widget _buildUpgradeCard(TacticalUnitUpgrade upgrade, Color themeColor) {
    final isMaxed = upgrade.currentLevel >= upgrade.maxLevel;
    final canUpgrade = upgrade.canUpgrade && !isMaxed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canUpgrade ? upgrade.onUpgrade : null,
          borderRadius: BorderRadius.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: canUpgrade
                  ? AppColors.cardSurface
                  : AppColors.cardSurface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: canUpgrade
                    ? themeColor.withValues(alpha: 0.6)
                    : AppColors.border,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                // Ícone do Upgrade com Badge de Nível
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: canUpgrade
                        ? themeColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: canUpgrade ? themeColor : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    upgrade.icon,
                    size: 18,
                    color: canUpgrade ? themeColor : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),

                // Título do Upgrade e Efeito
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              upgrade.title,
                              style: AppTypography.codeMedium.copyWith(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: canUpgrade ? Colors.white : AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Lv.${upgrade.currentLevel}',
                            style: AppTypography.codeSmall.copyWith(
                              fontSize: 11.0,
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        upgrade.effect,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.0,
                          color: canUpgrade ? AppColors.bandwidth : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Botão / Chip de Custo com Feedback de Ação
                if (isMaxed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bandwidth.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: AppColors.bandwidth, width: 1),
                    ),
                    child: Text(
                      'MAX',
                      style: AppTypography.codeSmall.copyWith(
                        fontSize: 11.0,
                        color: AppColors.bandwidth,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: canUpgrade
                          ? const Color(0xFFFFCC00).withValues(alpha: 0.18)
                          : AppColors.background,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: canUpgrade
                            ? const Color(0xFFFFCC00)
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          '${upgrade.cost}',
                          style: AppTypography.codeSmall.copyWith(
                            fontSize: 12.0,
                            color: canUpgrade
                                ? const Color(0xFFFFCC00)
                                : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
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

  Widget _buildPrimaryActionButton(Color themeColor) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor.withValues(alpha: 0.18),
          foregroundColor: themeColor,
          elevation: 0,
          side: BorderSide(color: themeColor, width: 1.2),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: info.onPrimaryAction,
        icon: Icon(info.primaryActionIcon ?? Icons.play_arrow_rounded, size: 18),
        label: Text(
          info.primaryActionLabel!,
          style: AppTypography.codeSmall.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12.0,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

/// Desenha o triângulo indicador da HUD apontando para a posição da unidade
class _HudArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isPointingDown;

  _HudArrowPainter({
    required this.color,
    required this.borderColor,
    required this.isPointingDown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final borderPath = Path();

    if (isPointingDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.close();

      borderPath.moveTo(0, 0);
      borderPath.lineTo(size.width / 2, size.height);
      borderPath.lineTo(size.width, 0);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.close();

      borderPath.moveTo(0, size.height);
      borderPath.lineTo(size.width / 2, 0);
      borderPath.lineTo(size.width, size.height);
    }

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(borderPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HudArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isPointingDown != isPointingDown;
  }
}
