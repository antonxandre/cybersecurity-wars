import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'bastion_node.dart';
import 'mainframe_model.dart';

/// Tipos de unidades e entidades inspecionáveis no campo de batalha
enum TacticalUnitType {
  mainframe,
  bastionNode,
  dataPacket,
}

/// Atributo chave-valor estilizado para exibição na grade de métricas da HUD
class TacticalUnitAttribute {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const TacticalUnitAttribute({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
}

/// Card de melhoria de habilidade ou hardware acoplado diretamente à HUD da unidade
class TacticalUnitUpgrade {
  final String id;
  final String title;
  final String effect;
  final IconData icon;
  final int currentLevel;
  final int maxLevel;
  final int cost;
  final String costType; // 'Tokens' ou 'Bits'
  final bool canUpgrade;
  final VoidCallback onUpgrade;

  const TacticalUnitUpgrade({
    required this.id,
    required this.title,
    required this.effect,
    required this.icon,
    required this.currentLevel,
    required this.maxLevel,
    required this.cost,
    this.costType = 'Tokens',
    required this.canUpgrade,
    required this.onUpgrade,
  });
}

/// Modelo padronizado de apresentação para inspeção tática de unidades
class TacticalUnitInfo {
  final String id;
  final String title;
  final String subtitle;
  final TacticalUnitType unitType;
  final Color themeColor;
  final IconData icon;
  final double currentIntegrity;
  final double totalIntegrity;
  final String description;
  final String statusText;
  final Color statusColor;
  final List<TacticalUnitAttribute> attributes;
  final List<TacticalUnitUpgrade> upgrades;
  final bool isAlly;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;

  final int? currentLevel;
  final int? maxLevel;
  final String? currentEffect;
  final String? specialAbilityTitle;
  final String? specialAbilityDescription;
  final bool isSpecialUnlocked;
  final int? nextLevelCost;
  final VoidCallback? onUpgradeNode;

  double get currentHp => currentIntegrity;
  double get maxHp => totalIntegrity;

  double get hpPercentage =>
      (currentIntegrity / (totalIntegrity > 0 ? totalIntegrity : 1.0) * 100.0).clamp(0.0, 100.0);

  const TacticalUnitInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.unitType,
    required this.themeColor,
    required this.icon,
    required this.currentIntegrity,
    required this.totalIntegrity,
    required this.description,
    required this.statusText,
    required this.statusColor,
    required this.attributes,
    this.upgrades = const [],
    required this.isAlly,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.currentLevel,
    this.maxLevel,
    this.currentEffect,
    this.specialAbilityTitle,
    this.specialAbilityDescription,
    this.isSpecialUnlocked = false,
    this.nextLevelCost,
    this.onUpgradeNode,
  });

  /// Fábrica para o Mainframe Central (Time Azul Aliado ou Time Vermelho Adversário)
  factory TacticalUnitInfo.fromMainframe({
    required MainframeModel mainframe,
    required bool isBlue,
    int availableTokens = 0,
    VoidCallback? onUpgradeCpu,
    VoidCallback? onUpgradeRam,
    VoidCallback? onUpgradeDisk,
    VoidCallback? onOpenUpgrades,
    void Function(String message)? onSendChatMessage,
  }) {
    final isDestroyed = mainframe.isDestroyed;
    final color = isBlue ? AppColors.blueTeam : AppColors.redTeam;

    // Upgrades acoplados diretamente na HUD
    final upgradesList = <TacticalUnitUpgrade>[];
    if (isBlue) {
      if (onUpgradeCpu != null) {
        upgradesList.add(
          TacticalUnitUpgrade(
            id: 'cpu',
            title: 'OVERCLOCK DE CPU',
            effect: '+30 DPS no Ataque Básico',
            icon: Icons.speed_rounded,
            currentLevel: mainframe.cpuLevel,
            maxLevel: 10,
            cost: mainframe.upgradeCostCpu,
            canUpgrade: mainframe.canUpgradeCpu && availableTokens >= mainframe.upgradeCostCpu,
            onUpgrade: () {
              onUpgradeCpu();
              onSendChatMessage?.call(
                '[MAINFRAME] Upgrade realizado: OVERCLOCK DE CPU (Lv. ${mainframe.cpuLevel + 1})',
              );
            },
          ),
        );
      }

      if (onUpgradeRam != null) {
        upgradesList.add(
          TacticalUnitUpgrade(
            id: 'ram',
            title: 'EXPANSÃO DE RAM',
            effect: '+1 Alvo Simultâneo',
            icon: Icons.view_column_rounded,
            currentLevel: mainframe.ramLevel,
            maxLevel: 4,
            cost: mainframe.upgradeCostRam,
            canUpgrade: mainframe.canUpgradeRam && availableTokens >= mainframe.upgradeCostRam,
            onUpgrade: () {
              onUpgradeRam();
              onSendChatMessage?.call(
                '[MAINFRAME] Upgrade realizado: EXPANSÃO DE RAM (Lv. ${mainframe.ramLevel + 1})',
              );
            },
          ),
        );
      }

      if (onUpgradeDisk != null) {
        upgradesList.add(
          TacticalUnitUpgrade(
            id: 'disk',
            title: 'BLINDAGEM DE DISCO',
            effect: '+400 Integridade Total',
            icon: Icons.security_rounded,
            currentLevel: mainframe.diskLevel,
            maxLevel: 10,
            cost: mainframe.upgradeCostDisk,
            canUpgrade: mainframe.canUpgradeDisk && availableTokens >= mainframe.upgradeCostDisk,
            onUpgrade: () {
              onUpgradeDisk();
              onSendChatMessage?.call(
                '[MAINFRAME] Upgrade realizado: BLINDAGEM DE DISCO (Lv. ${mainframe.diskLevel + 1})',
              );
            },
          ),
        );
      }
    }

    return TacticalUnitInfo(
      id: 'mainframe_${mainframe.teamId}',
      title: isBlue ? 'MAINFRAME CENTRAL (BLUE)' : 'MAINFRAME ALVO (RED)',
      subtitle: isBlue ? 'NÚCLEO DE COMANDO ALIADO' : 'NÓ MESTRE ADVERSÁRIO',
      unitType: TacticalUnitType.mainframe,
      themeColor: color,
      icon: Icons.developer_board_rounded,
      currentIntegrity: mainframe.currentHp,
      totalIntegrity: mainframe.totalIntegrity,
      description: isBlue
          ? 'Servidor central protegido por refrigeração criogênica e lasers defensivos automatizados. Mantenha-o operacional a todo custo.'
          : 'Instância central do adversário. Transmita malwares pelas rotas para sobrecarregar seus buffers e destruí-lo.',
      statusText: isDestroyed
          ? 'COMPROMETIDO'
          : (mainframe.hpPercentage < 30 ? 'CRÍTICO' : 'OPERACIONAL'),
      statusColor: isDestroyed
          ? AppColors.redTeam
          : (mainframe.hpPercentage < 30 ? AppColors.cpuClock : AppColors.bandwidth),
      attributes: [
        TacticalUnitAttribute(
          label: 'ATAQUE BÁSICO',
          value: '${mainframe.laserDps.toInt()} DPS',
          icon: Icons.flash_on_rounded,
          color: AppColors.redTeam,
        ),
        TacticalUnitAttribute(
          label: 'ALVOS SIMULTÂNEOS',
          value: '${mainframe.targetCount} Canais',
          icon: Icons.alt_route_rounded,
          color: AppColors.bandwidth,
        ),
        TacticalUnitAttribute(
          label: 'HARDWARE CPU/RAM',
          value: 'Lv.${mainframe.cpuLevel} / Lv.${mainframe.ramLevel}',
          icon: Icons.memory_rounded,
          color: const Color(0xFFFFCC00),
        ),
      ],
      upgrades: upgradesList,
      isAlly: isBlue,
      primaryActionLabel: onOpenUpgrades != null ? 'MELHORIAS DE HARDWARE' : null,
      primaryActionIcon: onOpenUpgrades != null ? Icons.tune_rounded : null,
      onPrimaryAction: onOpenUpgrades,
    );
  }

  /// Fábrica para Bastiões de Defesa instalados na grade tática
  factory TacticalUnitInfo.fromBastionNode({
    required BastionNode node,
    required int gridX,
    required int gridY,
    bool isPrepPhase = false,
    int availableTokens = 0,
    VoidCallback? onUpgrade,
    List<TacticalUnitUpgrade> upgrades = const [],
    VoidCallback? onDismantle,
  }) {
    final upgradesList = List<TacticalUnitUpgrade>.from(upgrades);
    if (onUpgrade != null && node.upgradeCost != null) {
      upgradesList.add(
        TacticalUnitUpgrade(
          id: 'upgrade_${node.id}',
          title: 'UPGRADE P/ NÍVEL ${node.level + 1}',
          effect: node.level == 1
              ? 'Aumenta HP, DPS e aprimora atributos da unidade.'
              : 'Desbloqueia Habilidade Especial: ${node.specialAbilityTitle}',
          icon: Icons.upgrade_rounded,
          currentLevel: node.level,
          maxLevel: 3,
          cost: node.upgradeCost!,
          costType: 'Tokens',
          canUpgrade: node.canUpgrade(availableTokens),
          onUpgrade: onUpgrade,
        ),
      );
    }

    return TacticalUnitInfo(
      id: 'node_${gridX}_$gridY',
      title: node.name.toUpperCase(),
      subtitle: 'CÉLULA TÁTICA ($gridX, $gridY) // LV. ${node.level}',
      unitType: TacticalUnitType.bastionNode,
      themeColor: node.nodeColor,
      icon: node.icon,
      currentIntegrity: node.currentIntegrity,
      totalIntegrity: node.maxIntegrity,
      description: node.description,
      statusText: node.level >= 3 ? 'NÍVEL 3 (MÁXIMO)' : 'NÍVEL ${node.level} / 3',
      statusColor: node.nodeColor,
      currentLevel: node.level,
      maxLevel: 3,
      currentEffect: node.currentEffectDescription,
      specialAbilityTitle: node.specialAbilityTitle,
      specialAbilityDescription: node.specialAbilityDescription,
      isSpecialUnlocked: node.isSpecialUnlocked,
      nextLevelCost: node.upgradeCost,
      onUpgradeNode: onUpgrade,
      attributes: [
        TacticalUnitAttribute(
          label: 'PODER DE FOGO',
          value: '${node.attackDamage.toInt()} DPS',
          icon: Icons.flash_on_rounded,
          color: AppColors.redTeam,
        ),
        TacticalUnitAttribute(
          label: 'ALCANCE RADIAL',
          value: '${node.attackRange.toInt()} px',
          icon: Icons.radar_rounded,
          color: AppColors.blueTeam,
        ),
        TacticalUnitAttribute(
          label: 'NÍVEL ATUAL',
          value: 'Lv.${node.level} / 3',
          icon: Icons.military_tech_rounded,
          color: const Color(0xFFFFCC00),
        ),
      ],
      upgrades: upgradesList,
      isAlly: true,
      primaryActionLabel: isPrepPhase ? 'DESMONTAR (+${node.tokenCost} T)' : null,
      primaryActionIcon: isPrepPhase ? Icons.delete_sweep_rounded : null,
      onPrimaryAction: isPrepPhase ? onDismantle : null,
    );
  }

  /// Fábrica para Pacotes de Dados / Malwares
  factory TacticalUnitInfo.fromDataPacket({
    required String id,
    required String subtypeName,
    required String originName,
    required double currentHealth,
    required double maxHealth,
    required double damage,
    required double speed,
    required bool isLeaked,
    required bool isAlly,
    required String movementStateDesc,
    List<TacticalUnitUpgrade> upgrades = const [],
  }) {
    final color = isAlly ? AppColors.blueTeam : AppColors.redTeam;

    return TacticalUnitInfo(
      id: id,
      title: subtypeName.toUpperCase(),
      subtitle: isAlly ? 'PAYLOAD DEFENSIVO' : 'MALWARE INIMIGO',
      unitType: TacticalUnitType.dataPacket,
      themeColor: color,
      icon: isAlly ? Icons.security_rounded : Icons.bug_report_rounded,
      currentIntegrity: currentHealth,
      totalIntegrity: maxHealth,
      description:
          'Unidade de dados com carga ativa trafegando em alta velocidade pela infraestrutura da arena.',
      statusText: isLeaked ? '⚠️ VAZAMENTO DETECTADO' : movementStateDesc,
      statusColor: isLeaked ? AppColors.redTeam : AppColors.bandwidth,
      attributes: [
        TacticalUnitAttribute(
          label: 'PODER DE DANO',
          value: '${damage.toInt()} DMG',
          icon: Icons.bolt_rounded,
          color: AppColors.redTeam,
        ),
        TacticalUnitAttribute(
          label: 'VELOCIDADE',
          value: '${speed.toInt()} px/s',
          icon: Icons.speed_rounded,
          color: AppColors.blueTeam,
        ),
        TacticalUnitAttribute(
          label: 'ROTA ATUAL',
          value: movementStateDesc,
          icon: Icons.alt_route_rounded,
          color: const Color(0xFFFFCC00),
        ),
      ],
      upgrades: upgrades,
      isAlly: isAlly,
    );
  }
}
