import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_theme.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/match_state.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/match_result_overlay.dart';

void main() {
  group('MatchResultOverlay Tests', () {
    testWidgets('renders defeat overlay without LLM Core or SLA texts and with Back to Lobby button', (tester) async {
      bool backToLobbyPressed = false;

      final defeatState = MatchState.initial().copyWith(
        phase: MatchPhase.defeat,
        statsDurationSeconds: 120,
        statsPacketsNeutralized: 45,
        totalLeaks: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: MatchResultOverlay(
              state: defeatState,
              onBackToLobby: () => backToLobbyPressed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verifica título e mensagem de derrota sem menção a LLM Core ou SLA de negócio
      expect(find.text('SISTEMA COMPROMETIDO!'), findsOneWidget);
      expect(find.textContaining('LLM Core'), findsNothing);
      expect(find.textContaining('LLM CORE'), findsNothing);
      expect(find.textContaining('SLA'), findsNothing);
      expect(find.textContaining('SLA DE NEGÓCIO'), findsNothing);

      // 2. Verifica ausência do botão Jogar Novamente
      expect(find.text('JOGAR NOVAMENTE'), findsNothing);

      // 3. Verifica presença das métricas de jogo mantidas
      expect(find.text('DURAÇÃO'), findsOneWidget);
      expect(find.text('120s'), findsOneWidget);
      expect(find.text('AMEAÇAS EXPURGADAS'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('TOTAL DE VAZAMENTOS (LEAKS)'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // 4. Verifica botão único de Voltar para o Lobby
      final backButton = find.text('VOLTAR PARA O LOBBY');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      expect(backToLobbyPressed, isTrue);
    });

    testWidgets('renders victory overlay without LLM Core or SLA texts and with Back to Lobby button', (tester) async {
      bool backToLobbyPressed = false;

      final victoryState = MatchState.initial().copyWith(
        phase: MatchPhase.victory,
        statsDurationSeconds: 240,
        statsPacketsNeutralized: 90,
        totalLeaks: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: MatchResultOverlay(
              state: victoryState,
              onBackToLobby: () => backToLobbyPressed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verifica título e mensagem de vitória
      expect(find.text('FORTALEZA DEFENDIDA!'), findsOneWidget);
      expect(find.textContaining('LLM Core'), findsNothing);
      expect(find.textContaining('SLA'), findsNothing);
      expect(find.text('JOGAR NOVAMENTE'), findsNothing);

      // 2. Verifica métricas
      expect(find.text('DURAÇÃO'), findsOneWidget);
      expect(find.text('240s'), findsOneWidget);
      expect(find.text('AMEAÇAS EXPURGADAS'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);
      expect(find.text('TOTAL DE VAZAMENTOS (LEAKS)'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // 3. Botão Voltar para o Lobby
      final backButton = find.text('VOLTAR PARA O LOBBY');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      expect(backToLobbyPressed, isTrue);
    });
  });
}
