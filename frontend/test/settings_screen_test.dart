import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_theme.dart';
import 'package:promptsec_arena_front/features/settings/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen renders title, categories and fullscreen option', (tester) async {
    // Definir resolução padrão de desktop widescreen
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verifica elementos do cabeçalho
    expect(find.text('CONFIGURAÇÕES DO SISTEMA'), findsOneWidget);
    expect(find.text('RETORNAR'), findsOneWidget);
    expect(find.text('RESTAURAR PADRÕES'), findsOneWidget);

    // Verifica abas e categorias
    expect(find.text('Vídeo & Gráficos'), findsWidgets);
    expect(find.text('Áudio & Efeitos'), findsWidgets);
    expect(find.text('Segurança & IA'), findsWidgets);

    // Verifica a opção de tela cheia por padrão
    expect(find.text('Tela Cheia por Padrão (Fullscreen)'), findsOneWidget);
    expect(find.text('PADRÃO ATIVADO'), findsOneWidget);
  });
}
