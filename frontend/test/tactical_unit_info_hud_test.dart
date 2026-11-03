import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/bastion_node.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/mainframe_model.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/tactical_unit_info.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/tactical_unit_info_hud.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  testWidgets('TacticalUnitInfoHud renders Mainframe info, attributes and upgrades panel', (tester) async {
    final mainframe = MainframeModel.initial(teamId: 'team_blue');
    bool cpuUpgraded = false;
    bool closeFired = false;

    final info = TacticalUnitInfo.fromMainframe(
      mainframe: mainframe,
      isBlue: true,
      availableTokens: 100,
      onUpgradeCpu: () => cpuUpgraded = true,
      onUpgradeRam: () {},
      onUpgradeDisk: () {},
    );

    await tester.pumpWidget(createTestWidget(
      TacticalUnitInfoHud(
        info: info,
        onClose: () => closeFired = true,
      ),
    ));

    await tester.pumpAndSettle();

    // Valida textos principais
    expect(find.text('MAINFRAME CENTRAL (BLUE)'), findsOneWidget);
    expect(find.text('NÚCLEO DE COMANDO ALIADO'), findsOneWidget);
    expect(find.text('OPERACIONAL'), findsOneWidget);
    expect(find.text('1000 / 1000 HP (100%)'), findsOneWidget);

    // Valida atributo renomeado
    expect(find.text('ATAQUE BÁSICO'), findsOneWidget);
    expect(find.text('50 DPS'), findsOneWidget);
    expect(find.text('ALVOS SIMULTÂNEOS'), findsOneWidget);
    expect(find.text('1 Canais'), findsOneWidget);

    // Valida painel integrado de upgrades
    expect(find.text('MELHORIAS DE HABILIDADES // HARDWARE'), findsOneWidget);
    expect(find.text('OVERCLOCK DE CPU'), findsOneWidget);
    expect(find.text('EXPANSÃO DE RAM'), findsOneWidget);
    expect(find.text('BLINDAGEM DE DISCO'), findsOneWidget);

    // Clica no card de upgrade de CPU
    final cpuUpgradeCard = find.text('OVERCLOCK DE CPU');
    expect(cpuUpgradeCard, findsOneWidget);
    await tester.tap(cpuUpgradeCard);
    await tester.pump();
    expect(cpuUpgraded, true);

    // Valida e clica no botão fechar
    final closeBtn = find.byIcon(Icons.close_rounded);
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pump();
    expect(closeFired, true);
  });

  testWidgets('TacticalUnitInfoHud renders BastionNode level effect and special ability card', (tester) async {
    const node = BastionNode(
      id: 'node_firewall_1',
      name: 'Firewall',
      type: BastionNodeType.firewall,
      level: 1,
      gridX: 0,
      gridY: 0,
      tokenCost: 40,
      maxIntegrity: 500.0,
      currentIntegrity: 500.0,
    );

    bool upgraded = false;
    final info = TacticalUnitInfo.fromBastionNode(
      node: node,
      gridX: 0,
      gridY: 0,
      availableTokens: 100,
      onUpgrade: () => upgraded = true,
    );

    await tester.pumpWidget(createTestWidget(
      TacticalUnitInfoHud(
        info: info,
        onClose: () {},
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('FIREWALL'), findsOneWidget);
    expect(find.textContaining('EFEITO ATUAL (NÍVEL 1'), findsOneWidget);
    expect(find.textContaining('Barreira Básica'), findsOneWidget);
    expect(find.textContaining('HABILIDADE ESPECIAL (LV. 3): Reflexão de Pacotes'), findsOneWidget);
    expect(find.text('REQUER LV. 3'), findsOneWidget);
    expect(find.textContaining('Reflete 25% do dano de colisão'), findsOneWidget);
    final upgradeBtn = find.text('UPGRADE P/ NÍVEL 2');
    expect(upgradeBtn, findsOneWidget);
    await tester.ensureVisible(upgradeBtn);
    await tester.tap(upgradeBtn);
    await tester.pump();
    expect(upgraded, true);
  });
}
