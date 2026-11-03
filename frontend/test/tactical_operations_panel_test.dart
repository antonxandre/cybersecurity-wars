import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_theme.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/mainframe_model.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/match_economy_state.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/tactical_virus_model.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/tactical_operations_panel.dart';

void main() {
  const testViruses = [
    TacticalVirusModel(
      id: 'worm_1',
      name: 'Worm Propagator',
      description: 'Multiplica-se rapidamente',
      bitCost: 35,
      incomeBonusTokens: 8,
      attackDamageBits: 45,
      packetHp: 50.0,
      packetSpeed: 70.0,
      icon: Icons.bug_report_rounded,
      color: Color(0xFFFF5500),
    ),
  ];

  testWidgets('TacticalOperationsPanel renders miner tab and triggers recruit callback', (tester) async {
    bool recruited = false;
    bool closed = false;

    const economy = MatchEconomyState(
      tokens: 120,
      bits: 30,
      minersCount: 2,
    );

    final mainframe = MainframeModel.initial(teamId: 'team_blue');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: TacticalOperationsPanel(
            activeTab: TacticalPanelTab.miner,
            onTabChanged: (_) {},
            onClose: () => closed = true,
            economy: economy,
            queuedAttacks: const [],
            mainframe: mainframe,
            onRecruitMiner: () => recruited = true,
            onUpgradeMainframeCpu: () {},
            onUpgradeMainframeRam: () {},
            onUpgradeMainframeDisk: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título e cabeçalho da aba Minerador
    expect(find.text('MINERADOR // PRODUÇÃO DE BITS'), findsOneWidget);

    // 2. Métricas de colunas
    expect(find.text('MINERADORES'), findsOneWidget);
    expect(find.text('TAXA PRODUÇÃO'), findsOneWidget);
    expect(find.text('SALDO DE BITS'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);

    // 3. Botão de recrutamento e clique
    final recruitButton = find.text('RECRUTAR MINERADOR');
    expect(recruitButton, findsOneWidget);

    await tester.tap(recruitButton);
    await tester.pumpAndSettle();
    expect(recruited, isTrue);

    // 4. Botão de fechar
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });

  testWidgets('TacticalOperationsPanel switches tabs and renders offensive queue', (tester) async {
    TacticalPanelTab currentTab = TacticalPanelTab.miner;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: TacticalOperationsPanel(
                activeTab: currentTab,
                onTabChanged: (tab) => setState(() => currentTab = tab),
                onClose: () {},
                economy: const MatchEconomyState(tokens: 100, bits: 50, minersCount: 1),
                queuedAttacks: testViruses,
                mainframe: MainframeModel.initial(teamId: 'team_blue'),
                onRecruitMiner: () {},
                onUpgradeMainframeCpu: () {},
                onUpgradeMainframeRam: () {},
                onUpgradeMainframeDisk: () {},
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Clicar na aba FILA
    await tester.tap(find.text('FILA'));
    await tester.pumpAndSettle();

    // 2. Verificar cabeçalho e itens da Fila Ofensiva
    expect(find.text('FILA OFENSIVA // TELEMETRIA'), findsOneWidget);
    expect(find.text('MALWARES'), findsOneWidget);
    expect(find.text('BÔNUS RENDA'), findsOneWidget);
    expect(find.text('DANO TOTAL'), findsOneWidget);
    expect(find.text('#1 Worm Propagator'), findsOneWidget);
    expect(find.text('+8T'), findsOneWidget);
  });

  testWidgets('TacticalOperationsPanel renders mainframe hardware upgrades', (tester) async {
    bool cpuUpgraded = false;
    bool ramUpgraded = false;
    bool diskUpgraded = false;

    final mainframe = MainframeModel.initial(teamId: 'team_blue');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: TacticalOperationsPanel(
            activeTab: TacticalPanelTab.mainframe,
            onTabChanged: (_) {},
            onClose: () {},
            economy: const MatchEconomyState(tokens: 300, bits: 0, minersCount: 1),
            queuedAttacks: const [],
            mainframe: mainframe,
            onRecruitMiner: () {},
            onUpgradeMainframeCpu: () => cpuUpgraded = true,
            onUpgradeMainframeRam: () => ramUpgraded = true,
            onUpgradeMainframeDisk: () => diskUpgraded = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Cabeçalho Mainframe
    expect(find.text('MAINFRAME // HARDWARE CENTRAL'), findsOneWidget);
    expect(find.text('INTEGRIDADE'), findsOneWidget);
    expect(find.text('DPS DO LASER'), findsOneWidget);
    expect(find.text('CANAIS RAM'), findsOneWidget);

    // 2. 3 Cards de Hardware (CPU, RAM, DISCO)
    expect(find.text('CPU'), findsOneWidget);
    expect(find.text('RAM'), findsOneWidget);
    expect(find.text('DISCO'), findsOneWidget);

    // 3. Clicar em cada botão de upgrade
    await tester.tap(find.text('${mainframe.upgradeCostCpu} T'));
    await tester.pumpAndSettle();
    expect(cpuUpgraded, isTrue);

    await tester.tap(find.text('${mainframe.upgradeCostRam} T'));
    await tester.pumpAndSettle();
    expect(ramUpgraded, isTrue);

    await tester.tap(find.text('${mainframe.upgradeCostDisk} T'));
    await tester.pumpAndSettle();
    expect(diskUpgraded, isTrue);
  });
}
