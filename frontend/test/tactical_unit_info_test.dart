import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_colors.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/bastion_node.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/mainframe_model.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/tactical_unit_info.dart';

void main() {
  group('TacticalUnitInfo Domain Model Tests', () {
    test('TacticalUnitInfo.fromMainframe configures Blue Mainframe and upgrades correctly', () {
      final mainframe = MainframeModel.initial(teamId: 'team_blue');
      bool cpuUpgraded = false;
      bool ramUpgraded = false;
      bool diskUpgraded = false;

      final info = TacticalUnitInfo.fromMainframe(
        mainframe: mainframe,
        isBlue: true,
        availableTokens: 100,
        onUpgradeCpu: () => cpuUpgraded = true,
        onUpgradeRam: () => ramUpgraded = true,
        onUpgradeDisk: () => diskUpgraded = true,
      );

      expect(info.id, 'mainframe_team_blue');
      expect(info.unitType, TacticalUnitType.mainframe);
      expect(info.title, 'MAINFRAME CENTRAL (BLUE)');
      expect(info.themeColor, AppColors.blueTeam);
      expect(info.isAlly, true);
      expect(info.currentIntegrity, 1000.0);
      expect(info.totalIntegrity, 1000.0);
      expect(info.hpPercentage, 100.0);
      expect(info.statusText, 'OPERACIONAL');

      // Verifica atributos
      final dpsAttr = info.attributes.firstWhere((a) => a.label == 'ATAQUE BÁSICO');
      expect(dpsAttr.value, '${mainframe.laserDps.toInt()} DPS');

      final targetsAttr = info.attributes.firstWhere((a) => a.label == 'ALVOS SIMULTÂNEOS');
      expect(targetsAttr.value, '${mainframe.targetCount} Canais');

      // Confirma que 'CAPACIDADE DE DISCO' foi removida dos atributos
      expect(info.attributes.any((a) => a.label == 'CAPACIDADE DE DISCO'), false);

      // Valida upgrades no próprio modelo
      expect(info.upgrades.length, 3);
      final cpuUpgrade = info.upgrades.firstWhere((u) => u.id == 'cpu');
      expect(cpuUpgrade.title, 'OVERCLOCK DE CPU');
      expect(cpuUpgrade.cost, mainframe.upgradeCostCpu);
      expect(cpuUpgrade.canUpgrade, true);
      cpuUpgrade.onUpgrade();
      expect(cpuUpgraded, true);

      final ramUpgrade = info.upgrades.firstWhere((u) => u.id == 'ram');
      expect(ramUpgrade.title, 'EXPANSÃO DE RAM');
      ramUpgrade.onUpgrade();
      expect(ramUpgraded, true);

      final diskUpgrade = info.upgrades.firstWhere((u) => u.id == 'disk');
      expect(diskUpgrade.title, 'BLINDAGEM DE DISCO');
      diskUpgrade.onUpgrade();
      expect(diskUpgraded, true);
    });

    test('TacticalUnitInfo.fromMainframe triggers onSendChatMessage callback with formatted announcement', () {
      final mainframe = MainframeModel.initial(teamId: 'team_blue');
      final chatMessages = <String>[];

      final info = TacticalUnitInfo.fromMainframe(
        mainframe: mainframe,
        isBlue: true,
        availableTokens: 100,
        onUpgradeCpu: () {},
        onUpgradeRam: () {},
        onUpgradeDisk: () {},
        onSendChatMessage: (msg) => chatMessages.add(msg),
      );

      final cpuUpgrade = info.upgrades.firstWhere((u) => u.id == 'cpu');
      cpuUpgrade.onUpgrade();
      expect(chatMessages.last, '[MAINFRAME] Upgrade realizado: OVERCLOCK DE CPU (Lv. 2)');

      final ramUpgrade = info.upgrades.firstWhere((u) => u.id == 'ram');
      ramUpgrade.onUpgrade();
      expect(chatMessages.last, '[MAINFRAME] Upgrade realizado: EXPANSÃO DE RAM (Lv. 2)');

      final diskUpgrade = info.upgrades.firstWhere((u) => u.id == 'disk');
      diskUpgrade.onUpgrade();
      expect(chatMessages.last, '[MAINFRAME] Upgrade realizado: BLINDAGEM DE DISCO (Lv. 2)');
    });

    test('TacticalUnitInfo.fromMainframe handles damaged and destroyed states', () {
      const damaged = MainframeModel(
        teamId: 'team_red',
        currentHp: 200.0,
      );
      final redInfo = TacticalUnitInfo.fromMainframe(
        mainframe: damaged,
        isBlue: false,
      );

      expect(redInfo.isAlly, false);
      expect(redInfo.title, 'MAINFRAME ALVO (RED)');
      expect(redInfo.themeColor, AppColors.redTeam);
      expect(redInfo.statusText, 'CRÍTICO');
      expect(redInfo.upgrades, isEmpty);

      const destroyed = MainframeModel(
        teamId: 'team_red',
        currentHp: 0.0,
      );
      final destroyedInfo = TacticalUnitInfo.fromMainframe(
        mainframe: destroyed,
        isBlue: false,
      );
      expect(destroyedInfo.statusText, 'COMPROMETIDO');
    });

    test('TacticalUnitInfo.fromBastionNode configures defensive node correctly', () {
      const node = BastionNode(
        id: 'node_test',
        name: 'Firewall',
        type: BastionNodeType.firewall,
        gridX: 1,
        gridY: 2,
        tokenCost: 40,
        maxIntegrity: 500.0,
        currentIntegrity: 500.0,
        attackDamageBits: 20.0,
        attackRange: 120.0,
      );

      bool dismantleCalled = false;
      bool upgradeCalled = false;
      final info = TacticalUnitInfo.fromBastionNode(
        node: node,
        gridX: 1,
        gridY: 2,
        isPrepPhase: true,
        availableTokens: 100,
        onUpgrade: () => upgradeCalled = true,
        onDismantle: () => dismantleCalled = true,
      );

      expect(info.unitType, TacticalUnitType.bastionNode);
      expect(info.title, 'FIREWALL');
      expect(info.subtitle, contains('CÉLULA TÁTICA (1, 2)'));
      expect(info.currentIntegrity, 500.0);
      expect(info.totalIntegrity, 500.0);
      expect(info.currentLevel, 1);
      expect(info.specialAbilityTitle, 'Reflexão de Pacotes');
      expect(info.currentEffect, contains('Barreira Básica'));
      expect(info.primaryActionLabel, 'DESMONTAR (+40 T)');
      expect(info.upgrades.length, 1);

      info.onPrimaryAction?.call();
      expect(dismantleCalled, true);

      info.upgrades.first.onUpgrade();
      expect(upgradeCalled, true);
    });

    test('TacticalUnitInfo.fromDataPacket formats malware details correctly', () {
      final packetInfo = TacticalUnitInfo.fromDataPacket(
        id: 'packet_123',
        subtypeName: 'SYN Flood Exploit',
        originName: 'redExploit',
        currentHealth: 45.0,
        maxHealth: 60.0,
        damage: 30.0,
        speed: 130.0,
        isLeaked: true,
        isAlly: false,
        movementStateDesc: 'Atacando Mainframe',
      );

      expect(packetInfo.unitType, TacticalUnitType.dataPacket);
      expect(packetInfo.title, 'SYN FLOOD EXPLOIT');
      expect(packetInfo.subtitle, 'MALWARE INIMIGO');
      expect(packetInfo.isAlly, false);
      expect(packetInfo.statusText, '⚠️ VAZAMENTO DETECTADO');
      expect(packetInfo.hpPercentage, closeTo(75.0, 0.1));
    });
  });
}
