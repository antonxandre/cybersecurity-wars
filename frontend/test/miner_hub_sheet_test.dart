import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_theme.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/match_economy_state.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/miner_hub_sheet.dart';

void main() {
  testWidgets('MinerHubSheet displays metrics and triggers recruit callback', (tester) async {
    bool recruited = false;

    const economy = MatchEconomyState(
      tokens: 120,
      bits: 30,
      minersCount: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: MinerHubSheet(
            economy: economy,
            onRecruitMiner: () => recruited = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título e cabeçalho
    expect(find.text('CENTRAL DE MINERAÇÃO (HASHMINER)'), findsOneWidget);

    // 2. Métricas
    expect(find.text('2'), findsOneWidget); // minersCount
    expect(find.text('+10'), findsOneWidget); // bitRate (2 * 5)
    expect(find.text('30'), findsOneWidget); // bits

    // 3. Botão de recrutamento habilitado
    final button = find.text('RECRUTAR HASHMINER DAEMON');
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(recruited, isTrue);
  });

  testWidgets('MinerHubSheet disables recruit button when cannot afford', (tester) async {
    const poorEconomy = MatchEconomyState(
      tokens: 20, // menor que minerCost (50)
      bits: 0,
      minersCount: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: MinerHubSheet(
            economy: poorEconomy,
            onRecruitMiner: _noop,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final recruitButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(recruitButton.onPressed, isNull);
  });
}

void _noop() {}
