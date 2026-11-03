import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/mainframe_model.dart';
import '../../domain/models/match_economy_state.dart';
import '../../domain/models/tactical_virus_model.dart';
import 'cyber_miner_icon.dart';

/// Abas de navegação do painel de operações táticas
enum TacticalPanelTab {
  miner,
  offensiveQueue,
  mainframe,
}

/// Painel Unificado de Operações Táticas (Canto Inferior Direito da Arena).
/// Consolida e padroniza o visual de Minerador, Fila Ofensiva e Upgrades do Mainframe
/// compartilhando a mesma malha de colunas, linhas de métricas, barras de status e cards de ação.
class TacticalOperationsPanel extends StatelessWidget {
  final TacticalPanelTab activeTab;
  final ValueChanged<TacticalPanelTab> onTabChanged;
  final VoidCallback onClose;
  final MatchEconomyState economy;
  final List<TacticalVirusModel> queuedAttacks;
  final MainframeModel mainframe;
  final VoidCallback onRecruitMiner;
  final VoidCallback onUpgradeMainframeCpu;
  final VoidCallback onUpgradeMainframeRam;
  final VoidCallback onUpgradeMainframeDisk;

  const TacticalOperationsPanel({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.onClose,
    required this.economy,
    required this.queuedAttacks,
    required this.mainframe,
    required this.onRecruitMiner,
    required this.onUpgradeMainframeCpu,
    required this.onUpgradeMainframeRam,
    required this.onUpgradeMainframeDisk,
  });

  Color get _themeColor {
    switch (activeTab) {
      case TacticalPanelTab.miner:
        return AppColors.bandwidth;
      case TacticalPanelTab.offensiveQueue:
        return AppColors.redTeam;
      case TacticalPanelTab.mainframe:
        return AppColors.coreAi;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _themeColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = (screenWidth - 32.0).clamp(340.0, 450.0);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: panelWidth,
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: themeColor.withValues(alpha: 0.7), width: 1.5),
              boxShadow: [
                ...AppColors.neonGlow(themeColor, blur: 16, spread: 0.5),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Barra Superior de Abas (Segmented Tab Bar)
                _buildTabBar(),

                // 2. Cabeçalho Dinâmico da Aba Ativa
                _buildHeader(themeColor),

                const Divider(height: 1, color: AppColors.border),

                // 3. Conteúdo Rolável Padronizado (Colunas de Métricas + Status + Ações)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Linha 1: 3 Colunas de Métricas Padronizadas
                        _buildMetricsRow(themeColor),

                        const SizedBox(height: 10),

                        // Linha 2: Barra de Status / Progresso Dinâmico
                        _buildStatusRow(themeColor),

                        const SizedBox(height: 12),

                        // Linha 3: Conteúdo Específico da Aba Ativa
                        _buildActiveTabContent(themeColor),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: AppColors.border),

                // 4. Rodapé Tático de Recursos e Balanço de Moedas
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. SELETOR DE ABAS ---

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
      color: AppColors.cardSurface.withValues(alpha: 0.8),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              tab: TacticalPanelTab.miner,
              title: 'MINERADOR',
              iconWidget: CyberMinerIcon(
                size: 16,
                color: activeTab == TacticalPanelTab.miner
                    ? AppColors.bandwidth
                    : AppColors.textMuted,
              ),
              color: AppColors.bandwidth,
              badgeText: '${economy.minersCount}',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTabButton(
              tab: TacticalPanelTab.offensiveQueue,
              title: 'FILA',
              iconWidget: Icon(
                Icons.radar_rounded,
                size: 16,
                color: activeTab == TacticalPanelTab.offensiveQueue
                    ? AppColors.redTeam
                    : AppColors.textMuted,
              ),
              color: AppColors.redTeam,
              badgeText: '${queuedAttacks.length}',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTabButton(
              tab: TacticalPanelTab.mainframe,
              title: 'MAINFRAME',
              iconWidget: Icon(
                Icons.memory_rounded,
                size: 16,
                color: activeTab == TacticalPanelTab.mainframe
                    ? AppColors.coreAi
                    : AppColors.textMuted,
              ),
              color: AppColors.coreAi,
              badgeText: 'Lv.${mainframe.cpuLevel + mainframe.ramLevel + mainframe.diskLevel - 2}',
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
            onPressed: onClose,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Fechar painel',
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required TacticalPanelTab tab,
    required String title,
    required Widget iconWidget,
    required Color color,
    String? badgeText,
  }) {
    final isSelected = activeTab == tab;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTabChanged(tab),
        borderRadius: BorderRadius.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.codeSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.25)
                        : AppColors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: isSelected ? color : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. CABEÇALHO DINÂMICO ---

  Widget _buildHeader(Color themeColor) {
    String title;
    String subtitle;
    Widget icon;

    switch (activeTab) {
      case TacticalPanelTab.miner:
        title = 'MINERADOR // PRODUÇÃO DE BITS';
        subtitle = 'Extração contínua de Bits para financiar ataques ofensivos';
        icon = CyberMinerIcon(size: 20, color: themeColor);
        break;
      case TacticalPanelTab.offensiveQueue:
        title = 'FILA OFENSIVA // TELEMETRIA';
        subtitle = 'Malwares programados para invadir o time adversário';
        icon = Icon(Icons.bolt_rounded, color: themeColor, size: 20);
        break;
      case TacticalPanelTab.mainframe:
        title = 'MAINFRAME // HARDWARE CENTRAL';
        subtitle = 'Última linha de defesa: fortifique CPU, RAM e Disco';
        icon = Icon(Icons.memory_rounded, color: themeColor, size: 20);
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: themeColor.withValues(alpha: 0.5), width: 1),
            ),
            child: icon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.displaySmall.copyWith(
                    fontSize: 13.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. LINHA 1: COLUNAS DE MÉTRICAS PADRONIZADAS (3 COLUNAS) ---

  Widget _buildMetricsRow(Color themeColor) {
    switch (activeTab) {
      case TacticalPanelTab.miner:
        final bitRate = economy.minersCount * 5;
        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.precision_manufacturing_rounded,
                label: 'MINERADORES',
                value: '${economy.minersCount}',
                unit: 'Ativos',
                color: AppColors.bandwidth,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.electric_bolt_rounded,
                label: 'TAXA PRODUÇÃO',
                value: '+$bitRate',
                unit: 'Bits / 3s',
                color: AppColors.blueTeam,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.bolt_rounded,
                label: 'SALDO DE BITS',
                value: '${economy.bits}',
                unit: 'Bits',
                color: const Color(0xFFFFCC00),
              ),
            ),
          ],
        );

      case TacticalPanelTab.offensiveQueue:
        final totalIncome = queuedAttacks.fold<int>(0, (sum, v) => sum + v.incomeBonus);
        final totalDmg = queuedAttacks.fold<int>(0, (sum, v) => sum + v.attackDamageBits.toInt());
        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.radar_rounded,
                label: 'MALWARES',
                value: '${queuedAttacks.length}',
                unit: 'Na Fila',
                color: AppColors.redTeam,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.trending_up_rounded,
                label: 'BÔNUS RENDA',
                value: '+$totalIncome',
                unit: 'Tokens / rd',
                color: const Color(0xFFFFCC00),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.flash_on_rounded,
                label: 'DANO TOTAL',
                value: '$totalDmg',
                unit: 'Dano Bits',
                color: AppColors.redTeamSecondary,
              ),
            ),
          ],
        );

      case TacticalPanelTab.mainframe:
        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.shield_rounded,
                label: 'INTEGRIDADE',
                value: '${mainframe.currentHp.toInt()}',
                unit: '/ ${mainframe.maxHp.toInt()} HP',
                color: AppColors.bandwidth,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.flash_auto_rounded,
                label: 'DPS DO LASER',
                value: '${mainframe.laserDps.toInt()}',
                unit: 'DPS Neutro',
                color: AppColors.blueTeam,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.view_column_rounded,
                label: 'CANAIS RAM',
                value: '${mainframe.targetCount}',
                unit: 'Alvo(s)',
                color: AppColors.cpuClock,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.codeSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unit,
            style: AppTypography.codeSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 4. LINHA 2: BARRA DE STATUS / PROGRESSO DINÂMICO ---

  Widget _buildStatusRow(Color themeColor) {
    switch (activeTab) {
      case TacticalPanelTab.miner:
        final cost = economy.minerCost;
        final ratio = (economy.tokens / cost).clamp(0.0, 1.0);
        final canAfford = economy.canAffordMiner;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.6),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CUSTO PRÓXIMO MINERADOR:',
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '🪙 $cost Tokens ${canAfford ? "(Pronto)" : "(${economy.tokens}/$cost)"}',
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 11,
                      color: canAfford ? AppColors.bandwidth : AppColors.textSecondary,
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
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    canAfford ? AppColors.bandwidth : AppColors.blueTeam,
                  ),
                ),
              ),
            ],
          ),
        );

      case TacticalPanelTab.offensiveQueue:
        final totalIncome = queuedAttacks.fold<int>(0, (sum, v) => sum + v.incomeBonus);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.redTeam.withValues(alpha: 0.08),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.redTeam.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_graph_rounded, color: Color(0xFFFFCC00), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'BÔNUS DE RENDA GARANTIDO:',
                  style: AppTypography.codeSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '+$totalIncome Tokens / round',
                style: AppTypography.codeSmall.copyWith(
                  color: const Color(0xFFFFCC00),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case TacticalPanelTab.mainframe:
        final ratio = (mainframe.hpPercentage / 100.0).clamp(0.0, 1.0);
        final hpColor = ratio > 0.5
            ? AppColors.bandwidth
            : (ratio > 0.25 ? AppColors.cpuClock : AppColors.redTeam);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.6),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STATUS DE INTEGRIDADE DO SERVIDOR:',
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${mainframe.hpPercentage.toInt()}% OPERACIONAL',
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 11,
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
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                ),
              ),
            ],
          ),
        );
    }
  }

  // --- 5. LINHA 3: CONTEÚDO ESPECÍFICO DA ABA ATIVA ---

  Widget _buildActiveTabContent(Color themeColor) {
    switch (activeTab) {
      case TacticalPanelTab.miner:
        return _buildMinerView();
      case TacticalPanelTab.offensiveQueue:
        return _buildOffensiveQueueView();
      case TacticalPanelTab.mainframe:
        return _buildMainframeView();
    }
  }

  // --- ABA MINERADOR ---
  Widget _buildMinerView() {
    final canAfford = economy.canAffordMiner;
    final cost = economy.minerCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card Educativo do Ciclo
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bandwidth.withValues(alpha: 0.05),
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.bandwidth.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.bandwidth, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tokens compram Mineradores ➔ Mineradores geram Bits ➔ Bits contratam Malwares ➔ Cada Malware despachado aumenta permanentemente sua Renda de Tokens!',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Botão Principal de Recrutamento de Minerador
        ElevatedButton(
          onPressed: canAfford ? onRecruitMiner : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bandwidth,
            disabledBackgroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            elevation: 3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CyberMinerIcon(
                size: 20,
                color: canAfford ? Colors.black : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'RECRUTAR MINERADOR',
                style: AppTypography.titleMedium.copyWith(
                  color: canAfford ? Colors.black : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: canAfford ? Colors.black.withValues(alpha: 0.2) : AppColors.border,
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  '🪙 $cost Tokens',
                  style: AppTypography.codeSmall.copyWith(
                    color: canAfford ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ABA FILA OFENSIVA ---
  Widget _buildOffensiveQueueView() {
    if (queuedAttacks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radar_rounded,
              size: 32,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhum malware na fila de despacho.',
              style: AppTypography.codeSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gaste Bits no Dock para invadir o time adversário!',
              style: AppTypography.codeSmall.copyWith(
                color: AppColors.blueTeam,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: queuedAttacks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (context, index) {
        final virus = queuedAttacks[index];
        final vColor = virus.color;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: vColor.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: vColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(virus.icon, size: 15, color: vColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#${index + 1} ${virus.name}',
                      style: AppTypography.codeSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Dano: ${virus.attackDamageBits.toInt()} Bits • Vel: ${virus.packetSpeed.toInt()} px/s',
                      style: AppTypography.codeSmall.copyWith(
                        color: vColor,
                        fontSize: 10.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  '+${virus.incomeBonus}T',
                  style: AppTypography.codeSmall.copyWith(
                    color: const Color(0xFFFFCC00),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- ABA MAINFRAME (3 CARDS DE HARDWARE EM LINHA) ---
  Widget _buildMainframeView() {
    return Row(
      children: [
        Expanded(
          child: _buildHardwareCard(
            title: 'CPU',
            icon: Icons.speed_rounded,
            level: mainframe.cpuLevel,
            benefit: '+30 DPS Laser',
            cost: mainframe.upgradeCostCpu,
            canUpgrade: mainframe.canUpgradeCpu && economy.tokens >= mainframe.upgradeCostCpu,
            onTap: onUpgradeMainframeCpu,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildHardwareCard(
            title: 'RAM',
            icon: Icons.view_column_rounded,
            level: mainframe.ramLevel,
            benefit: '+1 Alvo Buffer',
            cost: mainframe.upgradeCostRam,
            canUpgrade: mainframe.canUpgradeRam && economy.tokens >= mainframe.upgradeCostRam,
            onTap: onUpgradeMainframeRam,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildHardwareCard(
            title: 'DISCO',
            icon: Icons.storage_rounded,
            level: mainframe.diskLevel,
            benefit: '+400 HP Máx',
            cost: mainframe.upgradeCostDisk,
            canUpgrade: mainframe.canUpgradeDisk && economy.tokens >= mainframe.upgradeCostDisk,
            onTap: onUpgradeMainframeDisk,
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareCard({
    required String title,
    required IconData icon,
    required int level,
    required String benefit,
    required int cost,
    required bool canUpgrade,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: canUpgrade ? AppColors.coreAi.withValues(alpha: 0.6) : AppColors.border,
          width: canUpgrade ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: canUpgrade ? AppColors.coreAi : AppColors.textMuted, size: 15),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.codeSmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lv. $level',
            style: AppTypography.codeMedium.copyWith(
              color: AppColors.cpuClock,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            benefit,
            style: AppTypography.codeSmall.copyWith(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canUpgrade ? AppColors.coreAi : AppColors.surface,
                foregroundColor: AppColors.background,
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                elevation: canUpgrade ? 2 : 0,
              ),
              onPressed: canUpgrade ? onTap : null,
              child: Text(
                '$cost T',
                style: AppTypography.codeSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: canUpgrade ? Colors.white : AppColors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. RODAPÉ DE RECURSOS ---

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.cardSurface.withValues(alpha: 0.7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.toll_rounded, size: 15, color: AppColors.cpuClock),
              const SizedBox(width: 4),
              Text(
                '🪙 ${economy.tokens} Tokens',
                style: AppTypography.codeSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.bolt_rounded, size: 15, color: AppColors.blueTeam),
              const SizedBox(width: 3),
              Text(
                '${economy.bits} Bits',
                style: AppTypography.codeSmall.copyWith(
                  color: AppColors.blueTeam,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            'Pressione [ESC] p/ fechar',
            style: AppTypography.codeSmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
