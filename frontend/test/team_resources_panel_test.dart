import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_theme.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/team_player_model.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/team_resources_panel.dart';

void main() {
  testWidgets('TeamResourcesPanel renders all 4 allies and handles sector focus', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    BoardQuadrant? focusedQuadrant;

    final players = TeamPlayerModel.initialBlueTeam();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: TeamResourcesPanel(
            players: players,
            onFocusSector: (q) => focusedQuadrant = q,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verifica título e badge 4v4
    expect(find.text('ALIADOS DA REDE'), findsOneWidget);
    expect(find.text('4v4'), findsOneWidget);

    // 2. Verifica presença dos 4 jogadores aliados
    expect(find.text('Jogador 1'), findsOneWidget);
    expect(find.text('Jogador 2'), findsOneWidget);
    expect(find.text('Jogador 3'), findsOneWidget);
    expect(find.text('Jogador 4'), findsOneWidget);

    // 3. Toca no segundo jogador (Jogador 2 - BottomLeft)
    await tester.tap(find.text('Jogador 2'));
    await tester.pumpAndSettle();

    expect(focusedQuadrant, equals(BoardQuadrant.bottomLeft));

    // 4. Teste de recolhimento (collapse)
    await tester.tap(find.text('ALIADOS DA REDE'));
    await tester.pumpAndSettle();

    // Não deve exibir a lista de jogadores enquanto recolhido
    expect(find.text('Jogador 2'), findsNothing);

    // Expande novamente
    await tester.tap(find.byIcon(Icons.people_alt_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Jogador 2'), findsOneWidget);
  });
}
