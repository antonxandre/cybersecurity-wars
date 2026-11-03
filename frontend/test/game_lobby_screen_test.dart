import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_theme.dart';
import 'package:promptsec_arena_front/features/lobby/presentation/screens/game_lobby_screen.dart';

void main() {
  testWidgets('GameLobbyScreen renders AAA esports UI and switches modes', (tester) async {
    // Definir resolução padrão de desktop widescreen
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const GameLobbyScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verifica Top Bar Institucional (sem bits, tokens ou operador)
    expect(find.text('PROMPTSEC'), findsOneWidget);
    expect(find.text('ARENA'), findsOneWidget);
    expect(find.text('BITS'), findsNothing);
    expect(find.text('TOKENS'), findsNothing);

    // 2. Verifica Rail de Modos (apenas Criar Sala e Treino IA; sem busca de adversários)
    expect(find.text('Criar Sala'), findsOneWidget);
    expect(find.text('Treino IA'), findsOneWidget);
    expect(find.text('Buscar Sala'), findsNothing);

    // 3. Verifica Navegador Central de Salas (SALAS ATIVAS & LOBBIES e botão CRIAR SALA)
    expect(find.text('SALAS ATIVAS & LOBBIES'), findsOneWidget);
    expect(find.text('CRIAR SALA'), findsWidgets);
    expect(find.text('LANÇAR SALA'), findsNothing);

    // 4. Verifica Lista de Salas sem Mock (Exibe estado limpo sem salas mockadas)
    expect(find.text('NENHUMA SALA ENCONTRADA'), findsOneWidget);
    expect(find.text('CRIAR SALA AGORA'), findsOneWidget);

    // 5. Verifica Painéis Laterais (Estatísticas do perfil, Amigos e Notícias)
    expect(find.text('ESTATÍSTICAS DO PERFIL'), findsOneWidget);
    expect(find.text('WIN RATE'), findsOneWidget);
    expect(find.text('AMIGOS'), findsOneWidget);
    expect(find.text('COMUNICADOS TÁTICOS'), findsOneWidget);

    // 6. Interação: Clicar em "CRIAR SALA AGORA" cria a sala e abre a Sala de Espera (Waiting Room)
    await tester.tap(find.text('CRIAR SALA AGORA'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SALA DE ESPERA'), findsOneWidget);
    expect(find.text('SAIR DA SALA'), findsOneWidget);
    expect(find.text('CÓDIGO DE CONVITE'), findsOneWidget);
    expect(find.text('INICIAR PARTIDA'), findsOneWidget);

    // 7. Interação: Sair da Sala retorna para a listagem e agora exibe a sala criada
    await tester.tap(find.text('SAIR DA SALA'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SALAS ATIVAS & LOBBIES'), findsOneWidget);
    expect(find.text('SALA DE ESPERA'), findsNothing);
    expect(find.text('ENTRAR'), findsOneWidget);

    // 8. Interação: Trocar de modo para Treino IA
    await tester.tap(find.text('Treino IA'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('TREINO TÁTICO VS IA'), findsOneWidget);
    expect(find.text('INICIAR TREINO'), findsOneWidget);
  });
}
